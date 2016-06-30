class AdvertisersController < ApplicationController
  include Publishers::Themes
  include Categories
  include Search
  include PaginationHelper
  include Api

  if ssl_rails_environment?
    ssl_required :new, :edit
  else
    ssl_allowed  :new, :edit
  end
  ssl_allowed :create, :update, :delete, :clear_logo

  before_filter :default_to_demo_login,                               :except => [:public_index, :subcategories, :seo_friendly_public_index, :show]
  before_filter :user_required,                                       :except => [:public_index, :subcategories, :seo_friendly_public_index, :show]
  before_filter :set_publisher,                                       :only   => [ :index, :new, :create, :delete ]
  before_filter :set_advertiser,                                      :only   => [ :edit, :update, :clear_logo, :subscribe ]
  before_filter :can_manage?,                                         :except => [ :index, :public_index, :subcategories, :seo_friendly_public_index, :show ]
  before_filter :check_and_set_api_version_header_for_json_requests,  :only   => [:show]

  layout with_theme_unless_admin_user("application")

  def index
    page = params[:page] || 1
    @advertisers = Advertiser.search(:publisher => @publisher, :name => params[:name], :zip => params[:zip])\
      .paginate(:page => page, :per_page => 75)
    set_crumb_prefix @publisher
  end

  def show
    respond_to do |format|
      format.json do
        if (@advertiser = Advertiser.find_by_id(params[:id]))
          render :layout => false
        else
          render :nothing => true, :status => :not_found
        end
      end
    end
  end

  def seo_friendly_public_index
    @publisher = Publisher.find_by_label( params[:publisher_label] )
    if @publisher
      if params[:path] && !params[:path].empty?
        @category = @publisher.find_category_by_path(params[:path])
      end
      public_index
    else
      raise ActiveRecord::RecordNotFound.new(params[:publisher_label])
    end
  end

  def public_index
    validate_sort_value
    assign_search_params
    assign_categories
    search_request = create_search_request

    @publisher    ||= Publisher.find_by_id( params[:publisher_id] )
    if params[:advertiser_id]
      advertiser = @publisher.advertisers.find_by_id(params[:advertiser_id])
      @advertisers = [advertiser] if advertiser
    end
    @advertisers  ||= @publisher.advertisers_with_web_offers(search_request)

    @publisher_categories = Category.all_with_offers_count_for_publisher(search_request)
    @publisher_id         = @publisher.id
    @offers_count         = @publisher.active_placed_offers_count(@city, @state)
    @advertisers_count    = @advertisers.size

    if @category && @category.parent
      assign_subcategories_based_on_search_request( search_request )
    else
      @offers = @advertisers.collect(&:offers).flatten.uniq
      assign_subcategories @offers, @publisher, @category
    end

    @page_size = page_size_from_param(params[:page_size], 10)
    @pages = (@advertisers_count + @page_size - 1) / @page_size

    if params[:page].present?
      @page = params[:page].to_i
      @page = @pages if @page > @pages
    else
      @page = 1
    end


    if params[:with_map]
      @mappable_advertisers = @advertisers.select { |a| a.store.try(:latitude_and_longitude_present?) }
      @advertisers_count    = @mappable_advertisers.size
      @pages                = (@advertisers_count + @page_size - 1) / @page_size
      @advertisers          = @mappable_advertisers.slice((@page - 1) * @page_size, @page_size) || []
      @map                  = true
    else
      @advertisers = @advertisers.slice((@page - 1) * @page_size, @page_size) || []
      @advertisers.collect(&:offers).flatten.each { |offer| offer.record_impression(@publisher.id) }
    end


    respond_to do |format|
      format.html do
        layout = "advertisers/public_index" if params[:layout] == "iframe" || @publisher.theme == 'withtheme'
        layout ||= layout_for_publisher(@publisher, "offers")
        unless params[:with_map]
          unless @publisher.theme == 'withtheme'
            render :layout => layout, :template => template_for_publisher(@publisher, "public_index")
          else
            render with_theme(:layout => layout, :template => "advertisers/public_index")
          end
        else
          unless @publisher.theme == 'withtheme'
            render :layout => layout, :template => template_for_publisher(@publisher, "map_index")
          else
            render with_theme(:layout => layout, :template => "advertisers/map_index")
          end
        end
      end
      format.json do
        # this is taken from active_support/json/encoders/enumerable.rb
        # since the map json is different from the basic json for advertiser
        unless params[:page].present?
          # if we don't have an initial page, then we assume this is the first request and we want to return all the
          # mappable advertisers as well -- we don't want to do this for all map json requests.  we assume the map
          # javascript will hold onto the initial list of all mappable advertisers.
          render :json => "{\"request\": \"#{request.url}\",\"page\": #{@page},\"page_size\": #{@page_size},\"page_count\": #{@pages},\"total_count\": #{@mappable_advertisers.size},\"advertisers\": [#{@advertisers.map { |value| value.to_map_json } * ','}],\"mappable_advertisers\": [#{@mappable_advertisers.map { |value| value.to_map_json } * ','}]}"
        else
          render :json => "{\"request\": \"#{request.url}\",\"page\": #{@page},\"page_size\": #{@page_size},\"page_count\": #{@pages},\"total_count\": #{@mappable_advertisers.size},\"advertisers\": [#{@advertisers.map { |value| value.to_map_json } * ','}]}"
        end
      end
      format.js   do
        # need to record impressions for advertisers
        @advertisers.collect(&:offers).flatten.each { |offer| offer.record_impression(@publisher.id) }
        render :layout => false, :partial => "advertisers/#{@publisher.theme}/business", :collection => @advertisers
      end
    end

  end

  def new
    @advertiser = @publisher.advertisers.build
    add_store_if_paychex_publisher(@advertiser)
    set_crumb_prefix @publisher
    add_crumb "New", new_publisher_advertiser_path(@publisher)
    render :edit
  end

  def create
    @advertiser = @publisher.advertisers.build(params[:advertiser])
    if @advertiser.save
      flash[:notice] = "Created #{@advertiser.name}"
      redirect_after_save_depending_on_user!
    else
      set_crumb_prefix @publisher
      add_crumb "New", new_publisher_advertiser_path(@publisher)
      @advertiser.logo = nil
      add_store_if_paychex_publisher(@advertiser)
      render :edit
    end
  end

  def edit
    # Shoddy
    if params[:auth].present? && params[:auth].size > 20
      @advertiser.update_attributes! :returned_from_paypal_at => Time.now
    end

    @advertiser.stores.build
    set_crumb_prefix @advertiser.publisher
    add_crumb @advertiser.name, edit_advertiser_path(@advertiser)
    @publisher ||= @advertiser.publisher
  end

  def update
    if @advertiser.update_attributes(params[:advertiser].reverse_merge(:coupon_clipping_modes => []))
      flash[:notice] = "Updated #{@advertiser.name}"
      redirect_after_save_depending_on_user!
    else
      set_crumb_prefix @advertiser.publisher
      add_crumb @advertiser.name
      add_crumb "Edit", edit_advertiser_path(@advertiser)
      @advertiser.logo = nil
      render :edit
    end
  end

  def delete
    advertisers = @publisher.advertisers.find(params[:id])
    advertisers.each(&:delete!)
    flash[:notice] = "Deleted #{advertisers.size} #{advertisers.size > 1 ? 'advertisers' : 'advertiser'}"
    redirect_to publisher_advertisers_path(@publisher)
  end

  def clear_logo
    # Paperclip docs claim that destroy removes file, but it does not
    @advertiser.logo.destroy
    @advertiser.logo.clear
    @advertiser.save!
  end

  def subscribe
    publisher = @advertiser.publisher
    @paypal_configuration = PaypalConfiguration.for_currency_code(publisher.currency_code) if publisher && publisher.enable_paypal_buy_now?
    @paypal_configuration.setup_paypal_notification! if @paypal_configuration
  end

  private

  def set_publisher
    @publisher ||= Publisher.manageable_by(current_user).find(params[:publisher_id])
  end

  def set_advertiser
    @advertiser = Advertiser.manageable_by(current_user).find(params[:id])
  end

  def set_crumb_prefix(publisher)
    if admin?
      add_crumb "Publishers", publishers_path
    end
    if publishing_group?
      add_crumb "Publishers", publishing_group_publishers_path(current_user.company)
    end
    if admin? || publishing_group? || publisher?
      add_crumb publisher.name
      add_crumb "Advertisers", publisher_advertisers_path(publisher)
    end
  end

  def can_manage?
    unless current_user.can_manage? @advertiser || @publisher
      return access_denied
    end
  end

  # makes sure the sort value is legit, if not
  # defaults to "Name"
  def validate_sort_value
    unless ["Name", "Most Recent", "Distance"].include?( params[:sort] )
      params[:sort] = "Name"
    end
  end

  def map_window_content(advertiser)
    ui = "<h3 class='map'>"
    ui += "<a class='advertiser_name_link'>#{advertiser.name}</a>"
    ui += "</h3>"
    ui += "<div class='address'>"
    ui += advertiser.address.join("<br />")
    ui += "<br />"
    ui += advertiser.formatted_phone_number
    ui += "</div>"
    ui
  end

  def add_store_if_paychex_publisher(advertiser)
    if advertiser.publisher.uses_paychex? && advertiser.stores.empty?
      advertiser.stores.build
    end
  end

  def redirect_after_save_depending_on_user!
    if advertiser?
      if @advertiser.offers.empty?
        redirect_to new_advertiser_offer_path(@advertiser)
      else
        redirect_to edit_advertiser_path(@advertiser)
      end
    else
      redirect_to edit_publisher_advertiser_path(@advertiser.publisher, @advertiser)
    end
  end

  def advertiser?
    current_user.present? && current_user.company.is_a?(Advertiser)
  end

end
