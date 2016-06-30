class OffersController < ApplicationController
  include Categories
  include Search
  include PaginationHelper
  include Advertisers::Breadcrumbs
  include Publishers::Themes

  before_filter :default_to_demo_login, :only => :index
  before_filter :user_required, :only => [ :index, :new, :create, :copy, :edit, :update, :destroy, :clear_photo, :preview, :subcategory_options ]
  before_filter :set_advertiser, :only => [ :index, :new, :create, :copy, :edit, :update, :destroy, :clear_photo, :subcategory_options ]
  before_filter :can_manage?, :only => [ :new, :create, :copy, :update, :destroy, :clear_photo ]
  before_filter :set_p3p, :only => [ :public_index, :print, :call, :email, :txt ]
  before_filter :ensure_single_offer_request_not_deleted, :only => [:public_index, :seo_friendly_public_index]
  before_filter :reject_if_spam, :only => [:public_index, :seo_friendly_public_index]
  
  protect_from_forgery :except => [ :call, :email, :txt, :public_index, :seo_friendly_public_index, :nofollow ]  
  ssl_allowed :index, :new, :create, :copy, :edit, :update, :destroy, :clear_photo, :preview, :clear_offer_image, :subcategory_options
  
  layout "application", :except => [ :public_index, :print, :nofollow ]
  
  def index
    @offers = (@advertiser.offers + @advertiser.txt_offers + @advertiser.gift_certificates).compact
    set_crumb_prefix(@advertiser)
  end

  def new
    @offer = @advertiser.offers.build
    set_crumb_prefix(@advertiser)
    add_crumb "New Coupon", new_offer_path(@advertiser)
    render :edit
  end

  def create
    @offer = @advertiser.offers.build(params[:offer])
    if @offer.save
      flash[:notice] = "Created offer for #{@advertiser.name}"
      redirect_to edit_advertiser_path(@advertiser)
    else
      set_crumb_prefix(@advertiser)
      add_crumb "New Coupon", new_offer_path(@advertiser)
      @offer.offer_image = nil
      @offer.photo = nil
      render :edit
    end
  end

  def copy
    @source_offer = Offer.find(params[:id])
    # rails 2.3
    @offer = @source_offer.clone
    @offer.advertiser = @advertiser

    @offer.label = @offer.label << "_copy"
    @offer.listing = @offer.label if @source_offer.listing?
    @offer.categories = @source_offer.categories if @source_offer.categories.present?

    @offer.bit_ly_url = nil
    @offer.photo = nil
    @offer.offer_image = nil
    

    add_crumb "New Coupon (Copy)", copy_offer_path(@advertiser, :source_id => @source_offer)
    render :edit 
  end

  def edit
    @offer = Offer.find(params[:id])
    @advertiser = Advertiser.manageable_by(current_user).find(@offer.advertiser) # authorization check
    return access_denied unless @advertiser
    set_crumb_prefix(@advertiser)
    add_crumb "Edit Coupon", edit_offer_path(@offer)
  end

  def update
    @offer = Offer.find(params[:id])
    @advertiser = Advertiser.manageable_by(current_user).find(@offer.advertiser) # authorization check
    
    if @offer.update_attributes(params[:offer])
      flash[:notice] = "Updated #{@offer.advertiser.name} offer"
      redirect_to edit_advertiser_path(@advertiser)
    else
      set_crumb_prefix(@advertiser)
      add_crumb "Edit Coupon", edit_offer_path(@offer)
      @offer.offer_image = nil
      @offer.photo = nil
      render :edit
    end
  rescue ActiveRecord::StaleObjectError
    flash[:error] = "There was a change to the offer before your save. Please edit again."
    render :edit
  end

  def destroy
    @offer = Offer.find(params[:id])
    if @offer.delete!
      flash[:notice] = "Coupon marked for deletion, and will be removed from the site within the next 24 hours."
      redirect_to edit_advertiser_url(@advertiser)
    else
      render :edit
    end
  end
  
  def clear_photo
    @offer = Offer.find(params[:id])
    @advertiser = Advertiser.manageable_by(current_user).find(@offer.advertiser) # authorization check
    return access_denied unless @advertiser

    # Paperclip docs claim that destroy removes file, but it does not
    @offer.photo.destroy
    @offer.photo.clear
    unless @offer.save
      render "error"
    end 
  end
  
  def clear_offer_image
    @offer = Offer.find(params[:id])
    @advertiser = Advertiser.manageable_by(current_user).find(@offer.advertiser) # authorization check
    return access_denied unless @advertiser

    # Paperclip docs claim that destroy removes file, but it does not
    @offer.offer_image.destroy
    @offer.offer_image.clear
    unless @offer.save
      render "error"
    end
  end   
  
  def seo_friendly_public_index
    @publisher = Publisher.find_by_label(params[:publisher_label])
    if @publisher
      if params[:advertiser_label]
        @advertiser = @publisher.advertisers.find_by_label( params[:advertiser_label] )
      elsif params[:path] && !params[:path].empty?        
        @category = @publisher.find_category_by_path(params[:path])
      end
      @publisher_id = @publisher.id
      public_index
    else
      raise ActiveRecord::RecordNotFound.new(params[:publisher_label])
    end
  end

  # Many simple SQL calls are faster than one big join here (with small amount of demo data)
  
  def public_index
    respond_to do |format|
      format.html do
        public_index_as_html
      end
      format.wgs84 do
        public_index_as_wgs84
      end
    end
  end
  
  def public_index_as_html   
    assign_search_params
    assign_categories
    search_request = create_search_request
    
    if params[:offer_id].present?
      offer       = Offer.find(params[:offer_id])
      @offers     = [ offer ]  
      @advertiser = offer.advertiser
    elsif params[:advertiser_id].present? || @advertiser
      @advertiser ||= Advertiser.find_by_id( params[:advertiser_id] )
      @offers     = @advertiser ? @advertiser.offers.active : []
    else
      @offers = Offer.find_all_for_publisher(search_request)
      randomize_coupons search_request
      update_search_params search_request
      
      if @category && @category.parent
        assign_subcategories_based_on_search_request( search_request ) 
      else
        assign_subcategories @offers, @publisher, @category
      end
    end

    @page_size = page_size_from_param(params[:page_size], @publisher.page_preference)
    @pages = (@offers.size + @page_size - 1) / @page_size

    if params[:page].present?
      @page = params[:page].to_i
      @page = @pages if @page > @pages
    else
      @page = 1
    end
    
    @offers = @offers.slice((@page - 1) * @page_size, @page_size) || []

    OffersController.benchmark "OffersController#record_impressions" do
      @offers.each { |offer| offer.record_impression(@publisher.id) }
    end

    @categories_publisher_has_offers_in = Offer.active.in_publishers([@publisher]).map(&:categories).flatten.uniq
    @publisher_categories = Category.all_with_offers_count_for_publisher(search_request) 
    @offers_count         = @publisher.active_placed_offers_count(@city, @state)
    @showing_featured     = search_request.featured?
    
    unless @publisher.theme == 'withtheme'
      if %w{ standard sdcitybeat businessdirectory }.include?(@publisher.theme)
        if params[:layout] == "iframe"
          layout = "offers/public_index"
        else
          @subscribed = (cookies[:subscribed] == "subscribed")
          layout = layout_for_publisher(@publisher)
        end
        render :layout => layout, :template => template_for_publisher(@publisher, "public_index")
      else
        render :layout => "offers/public_index"
      end
    else 
      render with_theme(:layout => "public_index", :template => "offers/public_index")
    end
  end
  
  def public_index_as_wgs84
    assign_search_params
    @offers = Offer.find_all_for_publisher(create_search_request)

    # Due to how the search request works, we can't just pass in a limit param, so we have to truncate after the fact.
    @limit = (params[:limit].to_i - 1) if params[:limit]
    @offers = @offers[0..@limit] if @limit

    render :file => "offers/wgs84.xml.builder", :layout => false
  end

  def show
    @offer      = Offer.find(params[:id])
    @publisher  = @offer.publisher  
    @layout     = params[:layout]
    if %w{ standard sdcitybeat }.include?( @publisher.theme )   
      render :layout => "offers/#{@publisher.theme}/show", :template => template_for_publisher(@publisher, "show")
    else
      render :layout => "offers/show"
    end
  end
  
  def preview
    @offer = Offer.find(params[:id])
    @advertiser = Advertiser.manageable_by(current_user).find(@offer.advertiser) # authorization check
    return access_denied unless @advertiser
    @publisher = @offer.publisher
    @offers = [@offer]
    render :layout => "offers/public_index", :template => template_for_publisher(@publisher, 'preview')
  end
  
  def embed_coupon
    respond_to do |format|
      format.js {
        unless @offer = Offer.find_by_label(params[:id])
          render :status => :not_found, :text => "Coupon not found"
        end
      }
    end
  end
  
  # responsible for building a popular coupon thumbnail
  # widget, that publishers can place on their site.
  def thumbnail
    @publisher ||= Publisher.find_by_label( params[:label] )  
    # this is primarily for VVM coupon widget, but if we want to make it more general
    # we probably want to added a thumbnail_limit as a publisher setting.
    @offers     = @publisher.offers.active.by_popularity.limit(2) 
    @categories = Category.all_with_offers_count_for_publisher({:publisher => @publisher}) 
    expires_in AppConfig.expires_in_timeout.minutes, :public => true
    render :template => template_for_publisher(@publisher, "thumbnail"), :layout => false
  end

  def print
    @offer = Offer.find(params[:id])
    @publisher = Publisher.find(params[:publisher_id])
    @offer.record_click @publisher.id
    @lead = @offer.leads.create(:publisher => @publisher, :print_me => true, :remote_ip => request.remote_ip)
    unless @publisher.theme == 'withtheme'
      render template_for_publisher(@publisher, 'print')
    else
      render with_theme(:layout => false, :template => "offers/print")
    end
  end

  def email
    @offer        = Offer.find(params[:id])    
    @advertiser   = Advertiser.find_by_id(params[:advertiser_id])
    publisher     = @advertiser.present? ? @advertiser.publisher : Publisher.find(params[:publisher_id])
    @offer.record_click publisher.id
    @lead = @offer.leads.build(:publisher => publisher, :email_me => true)
    
    render :template => 'advertisers/offers/email' if @advertiser # otherwise render basic offers/email
  end

  def txt
    @offer      = Offer.find(params[:id])
    @advertiser = Advertiser.find_by_id(params[:advertiser_id])
    publisher   = @advertiser.present? ? @advertiser.publisher : Publisher.find(params[:publisher_id])
    @offer.record_click publisher.id
    @lead = @offer.leads.build(:publisher => publisher, :txt_me => true)
    
    render :template => 'advertisers/offers/txt' if @advertiser # otherwise render basic offer/txt
  end

  def call
    @offer = Offer.find(params[:id])
    publisher = Publisher.find(params[:publisher_id])
    @offer.record_click publisher.id
    @lead = @offer.leads.build(:publisher => publisher, :call_me => true)
  end

  def facebook
    offer = Offer.find(params[:id])
    publisher = Publisher.find(params[:publisher_id])
    offer.record_click publisher.id, "facebook"
    
    action = params[:popup].present? ? "sharer.php" : "share.php"  
    host = (publisher.use_production_host_for_facebook_shares? && publisher.production_host.present?) ? publisher.production_host : request.host
    offer_url = "http://#{host}/#{offer.bit_ly_path(publisher)}&v=#{offer.updated_at.to_i}"
    redirect_to "http://www.facebook.com/#{action}?u=#{CGI.escape(offer_url)}&t=#{CGI.escape(offer.facebook_title(publisher))}"
  end

  def twitter
    offer = Offer.find(params[:id])
    publisher = Publisher.find(params[:publisher_id])
    offer.record_click publisher.id, "twitter"
    
    redirect_to "http://twitter.com/?status=#{CGI.escape(offer.twitter_status(publisher)).gsub('+', '%20')}"
  end

  def xd_email
    @offer       = Offer.find(params[:id])   
    @advertiser  = Advertiser.find_by_id(params[:advertiser_id])
    @publisher   = @advertiser.present? ? @advertiser.publisher : Publisher.find(params[:publisher_id]) 
    @offer.record_click @publisher.id
    @lead = @offer.leads.build(:publisher => @publisher, :email_me => true)
    if @advertiser
      render :partial => "advertisers/offers/xd_email", :layout => "advertisers/xd_lead_panel"
    else
      render :partial => "offers/panels/email", :layout => "offers/xd_lead_panel"
    end
  end

  def xd_txt
    @offer = Offer.find(params[:id])    
    @advertiser  = Advertiser.find_by_id(params[:advertiser_id])
    @publisher   = @advertiser.present? ? @advertiser.publisher : Publisher.find(params[:publisher_id])
    @offer.record_click @publisher.id
    @lead = @offer.leads.build(:publisher => @publisher, :txt_me => true)
    unless @advertiser
      render :partial => "offers/panels/txt", :layout => "offers/xd_lead_panel"
    else
      render :partial => "advertisers/offers/xd_txt", :layout => "advertisers/xd_lead_panel"
    end
  end

  def xd_call
    @offer = Offer.find(params[:id])    
    @publisher = Publisher.find(params[:publisher_id])
    @offer.record_click @publisher.id
    @lead = @offer.leads.build(:publisher => @publisher, :call_me => true)
    render :partial => "offers/panels/call", :layout => "offers/xd_lead_panel"
  end
  
  def email_preview
    @offer = Offer.find(params[:id])
    @lead = @offer.leads.build(:publisher => @offer.publisher, :email => "test@example", :call_me => true)
    offer_html_email = CouponMailer.create_coupon(@lead)
    render :text => offer_html_email.parts.detect { |p| p.content_type == "text/#{params[:format]}" }.body
  end

  def subcategory_options
    publishing_group = @advertiser.publisher.publishing_group
    category = publishing_group.categories.find_by_id(params[:category_id])
    subcategories = category.subcategories.allowed_by_publishing_group(publishing_group).all(:order => "name ASC")
    render :partial => "subcategory_option", :collection => subcategories
  end

  private
  
  def set_advertiser
    OffersController.benchmark "OffersController#set_advertiser" do
      if params[:advertiser_id].blank?
        @advertiser = Advertiser.manageable_by(current_user).first
      else
        @advertiser = Advertiser.manageable_by(current_user).find(params[:advertiser_id])
      end

      unless @advertiser
        flash[:notice] = "There are no advertisers assigned to your account"
        redirect_to new_session_path
      end
    end
  end
  
  def can_manage?
    unless current_user.can_manage?(@advertiser)
      return access_denied
    end
  end
  
  def ensure_single_offer_request_not_deleted
    if params[:offer_id].present?
      offer = Offer.find(params[:offer_id])
      return render_404 unless offer && !offer.deleted?
    end
  end

  def reject_if_spam
    # check to make sure postal code is valid if it's present.  receiving a lot of spam from VVM coupon widget
    if params[:postal_code].present?
      return render_404 if params[:postal_code].length > 9 # quick look, there are not postal codes longer than 9 characters
    end
  end
end
