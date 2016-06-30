require "publishers/themes"

class PublishersController < ApplicationController
  include Categories
  include CouponsHelper
  include PaginationHelper
  include UsersHelper
  include DailyDealHelper
  include Publishers::Themes
  include Api
  include Analog::Referer::Controller
  include ::Consumers::Cookies::LastSeenDeal
  include ::Consumers::RedirectToLocalDeal
  include ::Consumers::ValidConsumers

  if ssl_rails_environment?
    ssl_required :google_offers_feed
  else
    ssl_allowed :google_offers_feed
  end

  before_filter :require_google_offers_import_user_basic_auth, :only => :google_offers_feed
  before_filter :set_referer_information, :only => [:deal_of_the_day]
  before_filter :set_p3p, :only => [ :embed_coupons, :coupon_page, :coupon_ad, :embed_coupon_ad ]
  before_filter :admin_privilege_required, :except => [ 
    :index, :index_coupons, :embed_coupons, :coupons_page, :coupon_ad_page, :coupon_ad, :embed_coupon_ad, :coupon_ad_image, 
    :show, :deal_of_the_day, :tomorrow_deal_of_the_day, :next_deal_of_the_day, :seo_friendly_deal_of_the_day,
    :google_offers_feed, :coupons, :daily_deals, :https_hosts, :help, :seller, :search, :categories, :location, :for_you
  ]
  before_filter :full_admin_privilege_required, :only => [:https_hosts]
  before_filter :user_required, :only => [ :index ]
  before_filter :assign_publishing_group, :only => [ :index ]
  before_filter :assign_publisher, :only => [ :edit, :update, :generate_qa_data]
  before_filter :assign_publisher_by_label, :only => [
    :index_coupons, :coupon_ad, :coupons_page, :coupon_ad_page, :deal_of_the_day,
    :tomorrow_deal_of_the_day, :next_deal_of_the_day, :help, :seller, :search, :categories, :location, :for_you
  ]

  before_filter :redirect_to_market_deal_of_the_day, :only => [:deal_of_the_day]
  before_filter :assign_market_by_label, :only => [ :deal_of_the_day ]
  before_filter :assign_publishing_groups, :only => [ :new, :create, :edit, :update ]
  before_filter :check_and_set_api_version_header_for_json_requests, :only => [:show]
  before_filter :redirect_to_local_publisher_if_enable_redirect_to_users_publisher, :only => [:deal_of_the_day], :unless => :api_request_or_admin_or_consumer_has_master_membership_code?
  before_filter :ensure_valid_consumer, :except => [ :new, :create, :edit, :update ], :if => :enforcing_valid_consumers?
  skip_before_filter :verify_authenticity_token, :only => [:deal_of_the_day]
  
  helper :coupons
  
  layout with_theme_unless_admin_user("application")  

  PUBLISHER_XML_FIELDS = [:address_line_1,
                :advertiser_has_listing,
                :allow_gift_certificates,
                :city,
                :country_id,
                :coupon_border_type,
                :excluded_clipping_modes,
                :exclude_from_market_selection,
                :id,
                :label,
                :launched,
                :name,
                :parent_theme,
                :publishing_group_id,
                :search_box,
                :show_bottom_pagination,
                :show_call_button,
                :show_facebook_button,
                :show_phone_number,
                :show_small_icons,
                :show_twitter_button,
                :state,
                :subcategories,
                :theme,
                :theme,
                :zip]

  def index
    @text = Publishers::SearchText.new(params[:text])
    
    if @publishing_group
      publishing_group_index
    elsif admin?
      admin_index @text
    else
      publishers_index
    end
  end

  def new
    @publisher = Publisher.new
    render :edit
  end

  def create
    @publisher = Publisher.new(params[:publisher])
    Publisher.transaction do
      if @publisher.save
        current_user.add_company(@publisher) if current_user.has_restricted_admin_privileges?
        flash[:notice] = "Created #{@publisher.name}"
        redirect_to edit_publisher_path(@publisher)
      else
        render :edit
      end
    end
  end
  
  def update 
    if @publisher.update_attributes(params[:publisher])
      flash[:notice] = "Updated #{@publisher.name}"
      redirect_to edit_publisher_path(@publisher)
    else
      render :edit
    end
  end

  def delete
    publishers  = Publisher.find(params[:id])
    publishers.delete_if { |publisher| publisher.destroy}

    number_deleted = params[:id].size - publishers.size
    flash[:notice] = "Deleted #{number_deleted} #{number_deleted > 1 ? 'publishers' : 'publisher'}."

    redirect_to publishers_url
  end

  def index_coupons
    raise ActiveRecord::RecordNotFound unless @publisher
    page_size = page_size_from_param(params[:page_size])
    redirect_to public_offers_path(
      @publisher, 
      :page_size => page_size, 
      :iframe_width => iframe_width(params[:iframe_width]),
      :iframe_height => iframe_height(page_size, params[:iframe_height])
    )
  end
  
  def embed_coupons
    assign_publisher_by_label
    @page_size = page_size_from_param(params[:page_size])
    render :layout => false
  rescue ActiveRecord::RecordNotFound
    render :status => :not_found, :text => "Coupon not found"
  end

  def embed_coupon_ad
    assign_publisher_by_label
    render :layout => false
  rescue ActiveRecord::RecordNotFound
    render :status => :not_found, :text => "Coupon not found" 
  end
  
  def coupon_ad
    @offer = Offer.find_by_publisher(@publisher)
    render :layout => false
  end
  
  def show
    respond_to do |format|
      format.html do
        assign_publisher_by_label
        @categories_publisher_has_offers_in = Offer.active.in_publishers([@publisher]).map(&:categories).flatten.uniq
        @publisher_categories = Category.all_with_offers_count_for_publisher(:publisher => @publisher)
        assign_categories
        assign_subcategories([], @publisher, @category)
        @text = params[:text]
        @postal_code = params[:postal_code]
        @radius = params[:radius]
        @subscribed = (cookies[:subscribed] == "subscribed")
        @page_size  = page_size_from_param(params[:page_size], @publisher.page_preference)
        @layout = params[:layout]
        layout = ("iframe" == @layout ? "offers/public_index" : layout_for_publisher(@publisher, "offers"))
        render :layout => layout, :template => template_for_publisher(@publisher, "show")
      end
      format.json do 
        if (@publisher = Publisher.find_by_label(params[:id]))
          render with_api_version
        else
          render :nothing => true, :status => :not_found
        end   
      end
    end
  end
  
  def https_hosts
    host_param = params[:https_only_host].present? ? params[:https_only_host][:host] : nil

    if request.delete?
      host = HttpsOnlyHost.find_by_host(host_param)
      if host.present?
        host.destroy
        flash[:notice] = "Removed HTTPS requirement for host #{host.host}"
      end
    elsif request.post?
      host = HttpsOnlyHost.create! :host => host_param
      flash[:notice] = "Successfully added HTTPS required for all pages served by #{host.host}"
    end
    
    @https_hosts = HttpsOnlyHost.all(:order => "host ASC").map { |https_host| https_host.host }
  end
  
  def coupons_page
    @page_size = page_size_from_param(params[:page_size])
    render :layout => false
  end
  
  def coupon_ad_page
    render :layout => false
  end  

  def coupons
    @publishers = publishers_with_active_offers
    respond_with_publisher_xml_fields
  end

  def daily_deals
    @publishers = publishers_with_active_daily_deals
    respond_with_publisher_xml_fields
  end

  def launched_with_current_or_future_daily_deals
    @publishers = Publisher.launched.with_current_or_future_daily_deals
    respond_with_publisher_xml_fields
  end

  def respond_with_publisher_xml_fields
    respond_to do |format|
      format.xml { render :xml => @publishers.to_xml(:only => PUBLISHER_XML_FIELDS) }
    end
  end

  def seo_friendly_deal_of_the_day
    @publisher = Publisher.find_by_label(params[:publisher_label])
    set_persistent_cookie(:publisher_label, @publisher.label)
    deal_of_the_day
  end
  
  def deal_of_the_day
    if @market.present?
      filtered_deals = @publisher.deals_in_market(@market)
    else
      filtered_deals = @publisher.deals_without_market
    end
    if @publisher.main_publisher?  && !current_consumer.try(:has_master_membership_code?) && !admin?
      filtered_deals = filtered_deals.ordered_by_start_at_descending.show_on_landing_page
    end
    if request.format.xml? || request.format.rss? || @publisher.launched?
      @daily_deal ||= (filtered_deals.current_or_previous || filtered_deals.active.in_order.last || filtered_deals.in_order.last)
      @show_special_deal = @publisher.show_special_deal?
      render_deal
    else
      if @publisher.uses_daily_deal_subscribers_presignup
        presignup_url_method = :presignup_publisher_daily_deal_subscribers_url
      else
        presignup_url_method = :presignup_publisher_consumers_url
      end
      redirect_to __send__(presignup_url_method, @publisher, :protocol => https_unless_development, :referral_code => params[:referral_code])
    end
  end 
  
  def tomorrow_deal_of_the_day
    @daily_deal = @publisher.daily_deals.tomorrow
    if @daily_deal
      deal_of_the_day
    else
      raise ActiveRecord::RecordNotFound.new("Tomorrow's daily deal")
    end
  end

  def next_deal_of_the_day
    @daily_deal = @publisher.daily_deals.starting_in_future.first
    raise ActiveRecord::RecordNotFound unless @daily_deal
    @time = @daily_deal.start_at
    render_deal
  end

  def generate_qa_data
    advertiser = Analog::QaData.generate_advertiser(@publisher)

    3.times do |i|
      Analog::QaData.generate_store(advertiser)
    end

    last_deal = @publisher.daily_deals.featured.last
    start_at = (last_deal.hide_at + 10.minutes if last_deal) || 1.day.ago
    3.times do |i|
      Analog::QaData.generate_daily_deal(advertiser, :featured => i == 0, :start_at => start_at)
    end

    redirect_to publisher_daily_deals_url(@publisher.id)
  end
  
  def google_offers_feed
    publisher = Publisher.find(params[:id])
    unless publisher.enable_google_offers_feed?
      render :nothing => true, :status => :not_found
      return
    end
    
    respond_to do |format|
      format.xml do
        publisher.export_google_offers_feed_xml!(buffer = "")
        render :text => buffer
      end
    end
  end

  def help
    render with_theme(:layout => "daily_deals", :template => "publishers/help")
  end

  def seller
    render with_theme(:layout => "daily_deals", :template => "publishers/seller")
  end  

  def search
    render with_theme(:layout => "daily_deals", :template => "publishers/search")
  end

  def categories
    @daily_deals = @publisher.daily_deals.active
    render with_theme(:layout => "daily_deals", :template => "publishers/categories")
  end
  
  def location
    @daily_deals = @publisher.daily_deals.active
    render with_theme(:layout => "daily_deals", :template => "publishers/location")
  end

  def for_you
    @daily_deals = @publisher.daily_deals.active
    render with_theme(:layout => "daily_deals", :template => "publishers/for_you")
  end

  # Used for determining translation scope in Liquid template rendering
  def current_publisher
    @publisher
  end
  
  protected
  
  def assign_publishing_group
    if params[:publishing_group_id].present?
      @publishing_group = PublishingGroup.find(params[:publishing_group_id])
      raise ActiveRecord::RecordNotFound unless admin? || (@publishing_group == current_user.company && @publishing_group.self_serve?)
    else
      admin_privilege_required
    end
  end
  
  def assign_publisher
    @publisher = Publisher.manageable_by(current_user).find(params[:id])
    @publisher_id = @publisher.to_param
  end
  
  def assign_publisher_by_label
    label = params[:label]||params[:id]
    @publisher = Publisher.find_by_label!(label)
    @publisher_id = @publisher.to_param
  end

  def redirect_to_market_deal_of_the_day
    return unless @publisher
    return if @publisher.markets.empty?
    return if params[:market_label].present?
    redirect_to public_deal_of_day_for_market_path :label => @publisher.label, :market_label => current_market(@publisher).label
  end
  
  def assign_market_by_label
    if params[:market_label].present?
      @market = Market.find_all_by_publisher_id(@publisher_id).detect {|m| m.label == params[:market_label].downcase}
    end
  end
  
  def assign_publishing_groups
    @publishing_groups = PublishingGroup.manageable_by(current_user)
  end
  
  def publishing_group_index
    @publishers = @publishing_group.publishers.manageable_by(current_user).with_users.with_advertisers.with_publishing_group
    add_crumb(@publishing_group.name) if admin?
    add_crumb "Publishers", publishing_group_publishers_path(@publishing_group)
    render :template => "publishers/index_for_publishing_group"
  end
  
  # Full Analog employee or 'restricted' admin
  def admin_index(text)
    add_crumb "Publishers", publishers_path
    if text.wildcard?
      @publishing_groups = PublishingGroup.manageable_by(current_user).with_publishers
      @publishers = Publisher.manageable_by(current_user).with_publishing_group.not_in_publishing_groups(@publishing_groups)
    elsif @text.valid_length?
      @publishing_groups = PublishingGroup.manageable_by(current_user).with_publishers.name_or_label_like(text)
      @publishers = Publisher.manageable_by(current_user).with_publishing_group.not_in_publishing_groups(@publishing_groups).name_or_label_like(text)
    else
      @publishing_groups = []
      @publishers = []
    end
  end
  
  def publishers_index
    add_crumb "Publishers", publishers_path
    @publishing_groups = PublishingGroup.manageable_by(current_user)
    @publishers = Publisher.manageable_by(current_user).not_in_publishing_groups(@publishing_groups)
  end
  
  def render_deal
    if @daily_deal.present?
      @advertiser   = @daily_deal.advertiser
      @page_context = "daily_deals"
      respond_to do |format|
        format.html do
          if flash[:analytics_tag]
            self.analytics_tag = flash[:analytics_tag]
          else
            analytics_tag.landing!
          end
          if (referral_code = params[:referral_code].to_s.strip).present?
            @referral = true
            expiry_time = (@daily_deal.publisher.enable_unlimited_referral_time ? 10.years : 72.hours).from_now
            cookies[:referral_code] = { :value => referral_code, :expires => expiry_time }
          end
          cookies[:daily_deal_market_id] = @market.to_param if @market.present?
          set_last_seen_deal_cookie(@daily_deal)
          render with_theme(:template => "daily_deals/show", :layout => "daily_deals")
        end
        format.json do
          expires_in AppConfig.expires_in_timeout.minutes, :public => true
          render :json => @daily_deal.to_json(:link => daily_deal_url(@daily_deal, :host => @daily_deal.publisher.daily_deal_host)),
                 :callback => params[:callback]
        end
        format.xml do
          expires_in AppConfig.expires_in_timeout.minutes, :public => true
          render with_theme(:template => "daily_deals/show.xml.builder", :layout => false)
        end
        format.rss do
          @time ||= Time.zone.now
          expires_in AppConfig.expires_in_timeout.minutes, :public => true
          render with_theme(:template => "daily_deals/show.rss.builder", :layout => false)
        end
        format.fbtab do
          render with_theme(:template => "daily_deals/show", :layout => "daily_deals")
        end
      end
    elsif params[:market_label].present?
      redirect_to_default_market
    else
      raise ActiveRecord::RecordNotFound
    end    
  end

  def redirect_to_default_market
    begin
      raise if params[:market_label] == "national"
      national_market = @publisher.markets.find_by_name("National")
      raise if national_market.nil?
      redirect_to public_deal_of_day_for_market_path :label => @publisher.label, :market_label => national_market.label
    rescue
      raise ActiveRecord::RecordNotFound
    end
  end
  
  def publishers_with_active_offers
    Publisher.launched.with_active_offers
  end
  
  def publishers_with_active_daily_deals
    Publisher.launched.with_active_daily_deals
  end
end
