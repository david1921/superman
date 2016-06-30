class DailyDealsController < ApplicationController
  include UsersHelper
  include MarketSelectionHelper
  include DailyDealHelper
  include Advertisers::Breadcrumbs
  include DailyDeals::Filtering
  include Publishers::Themes
  include Api
  include Analog::Referer::Controller
  include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  include ::Consumers::RedirectToLocalDeal
  include ::Consumers::Cookies::LastSeenDeal
  include ::Consumers::ValidConsumers

  newrelic_ignore :only => [:email]
  
  protect_from_forgery :except => :subscribe

  caches_action :status, :layout => false, :expires_in => AppConfig.expires_in_timeout.minutes
  caches_action :details, :expires_in => AppConfig.expires_in_timeout.minutes
  
  require_api_version :minimum => "3.0.0", :only => [:deal_discount]
  
  before_filter :set_referer_information, :only => [:show]
  before_filter :user_required, :only => [ :index, :syndicated_daily_deals, :new, :create, :edit, :update, :destroy, :clear_photo, :clear_secondary_photo, :preview, :preview_pdf, :preview_non_voucher_redemption, :affiliated_publisher_list ]
  before_filter :admin_privilege_required, :only => [:deliver_email, :affiliated_publisher_list, :random]
  before_filter :set_manageable_advertiser, :only => [ :new, :create ]
  before_filter :set_manageable_daily_deal, :only => [ :edit, :update, :destroy, :affiliated_publisher_list, :preview_pdf, :preview_non_voucher_redemption ]
  before_filter :set_manageable_publisher,  :only => [ :index, :syndicated_daily_deals]
  before_filter :affiliate_required, :only => :affiliate
  before_filter :assign_publisher_by_label, :only => [ :past, :public_index ]
  before_filter :set_daily_deal, :only => [:show, :deal_discount]
  before_filter :set_publisher_from_daily_deal, :only => :show
  before_filter :set_advertiser_from_daily_deal, :only => :show
  before_filter :set_time_zone, :only => [:index, :new, :create, :edit, :update, :email]
  before_filter :perform_http_basic_authentication, :only => [:affiliated, :syndicated_daily_deals]
  before_filter :check_and_set_api_version_header_for_json_requests, :only => [:active, :status, :details, :qr_encoded, :deal_discount]
  before_filter :set_publisher_for_static_page, :only => [:about_us, :faqs, :how_it_works, :contact, :privacy_policy, :california_privacy_policy, :legal, :terms, :feature_your_business]
  before_filter :set_daily_deal_variation, :only => [:new]
  before_filter :redirect_to_users_publisher_deal, :only => :show, :unless => :api_request_or_admin_or_consumer_has_master_membership_code?
  before_filter :ensure_valid_consumer


  before_filter :except => [:show, :public_index] do |c|
    User.current = c.send(:current_user)
  end
  
  ssl_allowed :subscribe, :affiliated
  ssl_allowed :show, :public_index, :with_format => [ Mime::JSON, Mime::JS ]

  layout with_theme("daily_deals", :except => :email)
  
  def index
    set_crumb_prefix
    @daily_deals =  @publisher.daily_deals.not_deleted.most_to_least_current.paginate(:page => params[:page], :per_page => 25)

    respond_to do |format|
      format.html { render with_theme_unless_admin_user(:layout => "application") }
    end
  end
  
  def official_rules
    @daily_deal = DailyDeal.find(params[:id])
    @publisher = @daily_deal.publisher
    render with_theme
  end
  
  def qr_code
    daily_deal = DailyDeal.find(params[:id])
    respond_to do |format|
      format.eps do
        raw_qr_code_file =
          daily_deal.with_qr_code_image daily_deal.qr_code_data,
            :level => 2, :module_size => 8, :output_format => :eps, :keep_file => true
        send_file raw_qr_code_file, :disposition => "inline", :type => "application/postscript"
      end
    end
  end

  def public_index
    @categories = daily_deal_categories_from_names(@publisher, params[:category])
    @daily_deals = find_available_daily_deals(:categories => @categories).in_order.include_publisher.include_advertiser
    @available_and_recently_finished_deals = find_available_and_recently_finished_daily_deals(:categories => @categories)
    @mall = params[:mall]
    case @mall
    when "0"
      @daily_deals = @daily_deals.not_shopping_mall
      @available_and_recently_finished_deals = @available_and_recently_finished_deals.not_shopping_mall
    when "1"
      @daily_deals = @daily_deals.shopping_mall_or_featured
      @available_and_recently_finished_deals = @available_and_recently_finished_deals.shopping_mall
    end      
    @featured_deal = @daily_deals.detect(&:featured?)
    respond_to do |format|
      format.html do
        @side_deals = @daily_deals.side.paginate(:page => params[:page], :per_page => params[:per_page])
        @daily_deals = @daily_deals.paginate(:page => params[:page], :per_page => params[:per_page])
        # Calculate number left in single query
        if "widget" == params[:template]
          render with_theme(:layout => false, :template => "daily_deals/widget")
        else
          render with_theme
        end
      end
      format.js do
        render with_theme(:layout => false)
      end
      format.json do
        expires_in AppConfig.expires_in_timeout.minutes, :public => true
        # NOTE: the following is a fix for stupid IE see http://www.rezashojaei.com/2011/06/ie-tries-to-download-json-response.html
        response.content_type = "text/plain"
        render :json => @daily_deals
      end
    end

  end

  def affiliate
    @daily_deal = current_user.daily_deals.today
    render :layout => "application"
  end
  
  def loyalty_program
    @daily_deal = DailyDeal.find(params[:id])
    @publisher = @daily_deal.publisher
    render with_theme
  end
  
  def show
    @daily_deal = DailyDeal.find(params[:id])
    @publisher = @daily_deal.publisher
    @advertiser = @daily_deal.advertiser
    @show_special_deal = @publisher.show_special_deal?
    analytics_tag.landing!
    respond_to do |format|
      format.html do
        set_last_seen_deal_cookie(@daily_deal)
        cookies.delete :daily_deal_market_id
        set_loyalty_program_cookie_if_appropriate(
          :daily_deal => @daily_deal, :referral_code => params[:referral_code])
        set_referral_code_cookie_if_appropriate(
          :daily_deal => @daily_deal, :referral_code => params[:referral_code])
        if (code = params[:placement_code].to_s.strip).present?
          cookies[:placement_code] = { :value => code, :expires => 72.hours.from_now }
        end
        render with_theme
      end
      format.json do
        # the javascript widget uses this
        expires_in AppConfig.expires_in_timeout.minutes, :public => true
        # NOTE: the following is a fix for stupid IE see http://www.rezashojaei.com/2011/06/ie-tries-to-download-json-response.html
        response.content_type = "text/plain" 
        # this way of rendering the deal only has a few fields in it
        render :json => @daily_deal
      end
      format.js do
        render with_theme(:layout => false)
      end
      format.xml do
        expires_in AppConfig.expires_in_timeout.minutes, :public => true
        render :layout => false
      end
      format.fbtab do 
        render with_theme(:layout => "daily_deals")
      end
    end
  end
  
  def past
    @daily_deals = DailyDeal.past(@publisher, @publisher.past_daily_deals_number_sold)
    render with_theme
  end

  def new
    @daily_deal = DailyDeal.build_with_defaults(@advertiser)
    set_crumb_prefix
    add_crumb @advertiser.name, edit_advertiser_path(@advertiser)
    add_crumb "New Daily Deal", new_advertiser_daily_deal_path(@advertiser)
    render with_theme_unless_admin_user(:template => 'daily_deals/edit', :layout => "application")
  end
  
  def create
    @daily_deal = @advertiser.daily_deals.build(params[:daily_deal])
    if @daily_deal.save
      flash[:notice] = "Created daily deal for #{@advertiser.name}"
      redirect_to edit_advertiser_path(@advertiser)
    else
      set_crumb_prefix
      add_crumb "New Daily Deal", new_advertiser_daily_deal_path(@advertiser)
      render with_theme_unless_admin_user(:layout => "application", :template => 'daily_deals/edit')
    end
  end  
  
  def edit
    @daily_deal.build_off_platform_purchase_summary if @daily_deal.off_platform? and @daily_deal.off_platform_purchase_summary.blank?    
    @referred_through_advertiser = request.env['HTTP_REFERER'].include?("advertiser") if request.env['HTTP_REFERER'].present?
    @daily_deal_variations = @daily_deal.daily_deal_variations
    set_crumb_prefix
    add_crumb "Edit Daily Deal", edit_daily_deal_path(@daily_deal)
    render with_theme_unless_admin_user(:layout => "application")
  end
  
  def update
    ensure_syndicated_deal_publisher_ids_are_set

    if @daily_deal.update_attributes(params[:daily_deal])
      flash[:notice] = "Daily Deal was updated."
      redirect_to edit_daily_deal_path(@daily_deal)
    else
      set_crumb_prefix
      add_crumb "Edit Daily Deal", edit_daily_deal_path(@daily_deal)
      render with_theme_unless_admin_user(:template => "daily_deals/edit", :layout => "application")
    end
  end                                       
  
  def destroy
    @daily_deal = DailyDeal.find_by_id(params[:id])
    if @daily_deal.mark_as_deleted!
      flash[:notice] = "Daily Deal was deleted."
    else
      flash[:error] = "We were unable to delete the daily deal."
    end
    referred_through_advertiser = request.env['HTTP_REFERER'].include?("advertiser") if request.env['HTTP_REFERER'].present?
    if referred_through_advertiser
      redirect_to edit_advertiser_path(@daily_deal.advertiser)
    else
      redirect_to publisher_daily_deals_path(@daily_deal.publisher)
    end
  end  
  
  def clear_photo
    @daily_deal = DailyDeal.find(params[:id])
    
    unless Rails.env.staging?
      # Paperclip docs claim that destroy removes file, but it does not
      @daily_deal.photo.destroy
      @daily_deal.photo.clear
      @daily_deal.save!
    end
  end
  
  def clear_secondary_photo
    @daily_deal = DailyDeal.find(params[:id])
    
    # Paperclip docs claim that destroy removes file, but it does not
    @daily_deal.secondary_photo.destroy
    @daily_deal.secondary_photo.clear
    @daily_deal.save!
  end
  
  def email
    @publisher = Publisher.find_by_label!(params[:label])
    if params[:tomorrow].present?
      @daily_deal = @publisher.daily_deals.featured_at(24.hours.from_now).first
      @time = Time.zone.now.tomorrow
    elsif params[:next].present?
      @daily_deal = @publisher.daily_deals.featured_after(@publisher.now).first
      @time = @daily_deal.try(:start_at)
    else
      @daily_deal = @publisher.daily_deals.current_or_previous
      @time = Time.zone.now
    end
    raise ActiveRecord::RecordNotFound unless @daily_deal
    
    # Avoid a bunch of daily_deal.advertiser calls in template
    @advertiser = @daily_deal.advertiser
    respond_to do |format|
      format.html { render with_theme }
      format.text  { render with_theme(:template => "daily_deals/email.text.plain") }
      format.rss  { 
        expires_in AppConfig.expires_in_timeout.minutes, :public => true
        render :layout => false
      }
    end
  end
  
  def deliver_email
    @publisher = Publisher.find_by_label!(params[:label])
    @daily_deal = @publisher.daily_deals.current_or_previous
    raise ActiveRecord::RecordNotFound unless @daily_deal
    
    DailyDealMailer.deliver_daily_deal @daily_deal, params[:to], render_to_string(with_theme(:layout => false, :template => "daily_deals/email"))
    
    render :text => "Sent email to #{params[:to]}"
  end
  
  def twitter
    daily_deal = DailyDeal.find(params[:id])
    daily_deal.record_click "twitter"
    bit_ly_url = daily_deal.bit_ly_url
    if params[:referral_code].present?
      # if there's a referral_code, we can't use the cached bit_ly url that the
      # deal has because it was not created with the referral_code
      url_to_shorten = "#{daily_deal.url_for_bit_ly}?referral_code=#{params[:referral_code]}"
      bit_ly_url = daily_deal.shorten_url_with_bit_ly(url_to_shorten)
    end
    redirect_to "http://twitter.com/?status=#{CGI.escape(daily_deal.twitter_status(false)).gsub('+', '%20')}%20#{bit_ly_url}"
  end
  
  def facebook
    daily_deal = DailyDeal.find(params[:id])
    daily_deal.record_click "facebook"
    action = params[:popup].present? ? "sharer.php" : "share.php"
    url = daily_deal_url(daily_deal, :v => daily_deal.updated_at.to_i)
    if params[:referral_code].present?
      url += "&referral_code=#{params[:referral_code]}"
    end
    redirect_to "http://www.facebook.com/#{action}?u=#{CGI.escape(url)}&t=#{CGI.escape(daily_deal.facebook_title)}"    
  end 
  
  def subscribe
    publisher = Publisher.find(params[:publisher_id])
    subscriber = publisher.subscribers.build( params[:subscriber].merge(:must_accept_terms => true, :user_agent => user_agent) )
    if subscriber.save
      cookies[:subscribed] = "subscribed"
      redirect_to subscribed_publisher_daily_deals_path(publisher)
    else
      flash[:warn] = publisher.display_text_for(:daily_deal_subscribe_error_message)
      redirect_to public_deal_of_day_path(publisher.label)
    end
  end
  
  def subscribed
    @publisher = Publisher.find(params[:publisher_id])
    analytics_tag.signup!
    render with_theme( :layout => "daily_deals", :template => "daily_deals/subscribed")
  end

  def seo_friendly_faqs
    @publisher = Publisher.find_by_label(params[:publisher_label])
    set_persistent_cookie(:publisher_label, @publisher.label)
    # TODO: will need to generalize @h1 if other publications use the seo route
    @h1        = "VOICE Deal of the Day for #{params[:location]}"
    render with_theme( :layout => "daily_deals", :template => "daily_deals/faqs" )
  end


  def about_us
    render with_theme(:layout => "daily_deals", :template => "daily_deals/about_us") 
  end
  
  def faqs
    render with_theme(:layout => "daily_deals", :template => "daily_deals/faqs")
  end
  
  def how_it_works
    render with_theme(:layout => "daily_deals", :template => "daily_deals/how_it_works")
  end

  def contact
    render with_theme(:layout => "daily_deals", :template => "daily_deals/contact")
  end
  
  def privacy_policy
    layout = popup? ? false : "daily_deals"
    render with_theme(:layout => layout, :template => "daily_deals/privacy_policy")
  end
  
  def california_privacy_policy
    render with_theme(:layout => "daily_deals", :template => "daily_deals/california_privacy_policy")
  end
  
  def legal
    render with_theme(:layout => "daily_deals", :template => "daily_deals/legal")
  end
  
  def terms
    layout = popup? ? false : "daily_deals"
    render with_theme(:layout => layout, :template => "daily_deals/terms")
  end
  
  def feature_your_business
    render with_theme(:layout => "daily_deals", :template => "daily_deals/feature_your_business")
  end
  
  def active
    respond_to do |format|
      format.json do
        @publisher = Publisher.find_by_label(params[:publisher_id])
        if (@publisher)
          unless "3.5.0" == api_version
            @daily_deals = @publisher.daily_deals.active
            @summary = params[:summary] == "true"
            render with_api_version
          else
            filter = params[:filter]||{}
            sort   = params[:sort]||{}
            search_parameters = {
              :publisher => @publisher,
              :categories     => extract_categories_from_filter_parameters( filter ),
              :location       => filter[:location],
              :distance       => filter[:distance],
              :distance_unit  => filter[:distance_unit],
              :sort_by        => sort[:by],
              :sort_direction => sort[:direction],
              :page           => params[:page],
              :page_size      => params[:page_size]
            }        
            @daily_deals = DailyDeals::SearchRequest.perform( search_parameters ).daily_deals
            @summary = params[:summary] == "true"
            render with_api_version
          end
        else
          render :nothing => true, :status => :not_found
        end
      end
    end
  end
  
  def status
    respond_to do |format|
      format.json do
        if (@daily_deal = DailyDeal.find_by_id(params[:id]))
          render :layout => false
        else
          render :nothing => true, :status => :not_found
        end
      end
    end
  end
  
  def affiliated
    respond_to do |format|
      format.json do
        @placements = @user.available_daily_deal_placements
        render :layout => false
      end
    end
  end

  # This action is kind of a second #show for the iphone app
  # #show is used by the javascript widget and has json that does not match the fields of the deal, e.g. "title"
  def details
    @daily_deal = DailyDeal.find(params[:id])
    respond_to do |format|
      format.json do
        render with_api_version
      end
    end
  end
  
  def affiliated_publisher_list
    render :partial => "daily_deals/affiliate_placements", :locals => { :affiliate_placements => @daily_deal.affiliate_placements.not_deleted }
  end
  
  def current_publisher
    @publisher
  end
  
  def qr_encoded
    @daily_deal = DailyDeal.active_or_qr_code_active.find(params[:base36].try(:to_i, 36))
    respond_to do |format|
      format.html do
        if browser.mobile?
          redirect_to new_daily_deal_one_click_purchase_url(@daily_deal, :host => @daily_deal.publisher.daily_deal_host)
        else
          redirect_to daily_deal_url(@daily_deal, :host => @daily_deal.publisher.daily_deal_host)
        end
      end
      format.json do
        redirect_to details_daily_deal_url(@daily_deal, :host => AppConfig.api_host, :format => "json")
      end
    end
  end

  def preview_pdf
    send_data @daily_deal.to_preview_pdf, :filename => "daily-deal-#{@daily_deal.id}-certificate-preview.pdf", :type => "application/pdf"
  end

  def preview_non_voucher_redemption
    @daily_deal_purchase = DailyDealPurchase.new
    @publisher = @daily_deal.publisher
    render with_theme(:template => 'daily_deal_purchases/non_voucher_redemption')
  end

  def random
    scope = DailyDeal
    if params[:publisher_id].present?
      scope = Publisher.find_by_label!(params[:publisher_id]).daily_deals
    end
    active_count = scope.active.count
    if active_count == 0
      raise ActiveRecord::RecordNotFound
    end
    deal = scope.active.offset(rand(active_count)).limit(1).first
    redirect_to :action => :show, :id => deal.to_param
  end
  
  def deal_discount
    @publisher = @daily_deal.publisher
    @discount  = @publisher.discounts.usable.find_by_code( (params[:consumer]||{})[:discount] )
    unless @discount
      respond_to do |format|
        format.json { render :nothing => true, :status => :not_acceptable }
      end            
    else
      respond_to do |format|
        format.json { render with_api_version }
      end
    end
  end
  
  private
  
  def set_loyalty_program_cookie_if_appropriate(options = {})
    raise ArgumentError "missing required argument :daily_deal" unless options.include?(:daily_deal)
    raise ArgumentError "missing required argument :referral_code" unless options.include?(:referral_code)

    daily_deal = options[:daily_deal]
    referral_code = options[:referral_code].to_s.strip

    return unless daily_deal.present? && daily_deal.enable_loyalty_program? && referral_code.present?
    
    cookies[:"loyalty_referral_code_#{daily_deal.id}"] = { :value => referral_code, :expires => 72.hours.from_now }
  end
  
  def set_referral_code_cookie_if_appropriate(options = {})
    raise ArgumentError "missing required argument :daily_deal" unless options.include?(:daily_deal)
    raise ArgumentError "missing required argument :referral_code" unless options.include?(:referral_code)
    
    daily_deal = options[:daily_deal]
    referral_code = options[:referral_code]
    
    return unless daily_deal.present? && daily_deal.publisher.enable_daily_deal_referral? && referral_code.present?

    expiry_time = @daily_deal.publisher.enable_unlimited_referral_time? ? 10.years : 72.hours
    cookies[:referral_code] = { :value => referral_code, :expires => expiry_time.from_now }
  end
  
  def affiliate_required
    unless affiliate? and current_user.publisher.id.to_s == params[:publisher_id]
      render :text => "access denied", :status => :unauthorized
    end
  end
  
  def set_time_zone
    if @publisher.present?
      Time.zone = @publisher.time_zone
    elsif @advertiser.present?
      Time.zone = @advertiser.publisher.try(:time_zone)
    elsif @daily_deal.present?
      Time.zone = @daily_deal.publisher.try(:time_zone) 
    end
    
    # Redundant?
    Time.zone ||= "Pacific Time (US & Canada)"
  end
  
  def set_manageable_advertiser
    @advertiser = Advertiser.manageable_by(current_user).find(params[:advertiser_id])
  end
  
  def set_daily_deal
    @daily_deal = DailyDeal.find(params[:id])
  end
  
  def set_publisher_from_daily_deal
    @publisher = @daily_deal.publisher
  end
  
  def set_advertiser_from_daily_deal
    @advertiser = @daily_deal.advertiser
  end
  
  def set_manageable_daily_deal
    @daily_deal = DailyDeal.find(params[:id])
    if @daily_deal.syndicated?
      Publisher.manageable_by(current_user).find(@daily_deal.publisher_id)
    elsif
      Advertiser.manageable_by(current_user).find(@daily_deal.advertiser_id)
    end
  end
  
  def set_manageable_publisher
    @publisher = Publisher.manageable_by(current_user).find(params[:publisher_id])
  end

  def assign_publisher_by_label
    @publisher = Publisher.find_by_label!(params[:label])
    @publisher_id = @publisher.to_param  
  end
  
  def set_crumb_prefix
    if current_user.has_admin_privilege?
      add_crumb "Publishers", publishers_path
    end
    if @publisher.present?
      add_crumb @publisher.name
      add_crumb "Daily Deals", publisher_daily_deals_path(@publisher)
    elsif
      add_crumb @daily_deal.publisher.name
      add_crumb "Daily Deals", publisher_daily_deals_path(@daily_deal.publisher)
    end
  end

  def daily_deal_categories_from_names(publisher, names)
    publisher.allowable_daily_deal_categories.with_names(names)
  end

  # Hack to allow syndicated_deal_publisher_ids to be set to [].  Check boxes do
  # not send a value if they are not checked, thus if no check boxes are
  # checked, syndicated_deal_publisher_ids will not be set and the deal's
  # attribute will not be updated
  def ensure_syndicated_deal_publisher_ids_are_set
    if @daily_deal.publisher.publishing_group.try(:restrict_syndication_to_publishing_group)
      params[:daily_deal][:syndicated_deal_publisher_ids] ||= [] if params[:daily_deal]
    end
  end

  def set_daily_deal_variation
    publisher = @daily_deal.publisher if @daily_deal
    if publisher && publisher.enable_daily_deal_variations?
      @daily_deal_variation = @daily_deal.daily_deal_variations.find_by_id(params[:daily_deal_variation_id])
    end
  end

  def set_publisher_for_static_page
    @publisher = Publisher.find(params[:publisher_id])
    unless api_request_or_admin_or_consumer_has_master_membership_code?
      if current_consumer && current_consumer.publisher.id !=  @publisher.id && current_consumer.publisher.try(:publishing_group).try(:enable_redirect_to_local_static_pages)
        @publisher = current_consumer.publisher
      end
    end
  end
  
  def extract_categories_from_filter_parameters(filter = {})
    categories = (filter||{})[:categories]
    categories.present? ? categories.split(",").collect(&:strip) : nil
  end
end
