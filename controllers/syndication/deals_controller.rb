class Syndication::DealsController < Syndication::ApplicationController
  
  before_filter :assign_publisher, :only => [:list, :grid, :show, :source, :unsource, :distribute, :calendar, :show_on_calendar, :map]
  before_filter :assign_deal, :only => [:show, :show_on_calendar, :source, :unsource, :distribute]
  before_filter :assign_deal_categories, :only => [:list, :grid, :calendar, :map]
  before_filter :set_default_location_cookie, :only => [:list, :grid, :calendar, :map]
  
  ssl_allowed :list, :grid, :show, :source, :unsource, :distribute, :calendar, :show_on_calendar, :map
  
  def calendar
    respond_to do |format|
      format.html do
        #Setup the search request but don't execute it here so that 
        #params are passed to other views properly. The calendar json
        #action performs the search.
        setup_search_request
      end
      format.json do
        perform_search_request({:default_page_size => 600})
        response.content_type = "text/plain"
      end
      format.js do
        render :layout => false
      end
    end
    
  end
  
  def list
    perform_search_request({ :default_page_size => 4 })
    flash.now[:notice] = "No results found." if !@search_response.results?
  end
  
  def grid
    perform_search_request({ :default_page_size => 9 })
    flash.now[:notice] = "No results found." if !@search_response.results?
  end

  def map
    map_options = {:require_locations => true, :default_page_size => 5}
    respond_to do |format|
      format.html do
        setup_search_request(map_options)
      end
      format.json do
        response.content_type = "text/plain"
        perform_search_request(map_options)
      end
    end
  end
  
  def show_on_calendar
    render :template => 'syndication/deals/show_on_calendar', :layout => false
  end
  
  def source
    access_denied if @deal.nil?
    if @deal.sourceable?(@publisher)
      @deal.available_for_syndication = true
      if @deal.valid?
        @deal.save
        redirect_to syndication_deal_path(@deal, Syndication::RequestParameters.collect(request))
        flash[:notice] = "Syndicated deal."
      else
        redirect_with_error(@deal, @deal.errors.full_messages.join(","))
      end
    else
      redirect_with_error(@deal, "Can not source a deal that does not belong to you or is a distributed deal.") 
    end
  end
  
  def unsource
    access_denied if @deal.nil?
    if @deal.unsourceable?(@publisher)
      @deal.available_for_syndication = false
      if @deal.valid?
        @deal.save
        redirect_to syndication_deal_path(@deal, Syndication::RequestParameters.collect(request))
        flash[:notice] = "Unsyndicated deal."
      else
        redirect_with_error(@deal, @deal.errors.full_messages.join(","))
      end
    else
      redirect_with_error(@deal, "Can not unsource a deal that already has distributed deals or is not sourced by you.") 
    end
  end
  
  def distribute
    access_denied if @deal.nil?
    if @deal.sourced_by_network?(@publisher)
      begin
        distributed_deal = @deal.syndicated_deals.build(:publisher_id => @publisher.id)
        distributed_deal.start_at = params[:daily_deal][:start_at]
        distributed_deal.hide_at = params[:daily_deal][:hide_at]
        distributed_deal.featured = params[:daily_deal][:featured]
        distributed_deal.save!
        @deal.save!
        redirect_to syndication_deal_path(distributed_deal, Syndication::RequestParameters.collect(request))
        flash[:notice] = "Distributed this deal."
      rescue Exception => e
        redirect_with_error(@deal, e.message)
      end
    else
      redirect_with_error(@deal, "Can not distribute a deal that is owned by you or not sourced by the network.") 
    end
  end
  
  private
  
  def assign_deal
    @deal = DailyDeal.find_by_id(params[:id])
  end
  
  def assign_deal_categories
    @categories = DailyDealCategory.analytics
  end
  
  def setup_search_request(options = {})
    create_search_request
    set_search_request_parameters
    set_search_request_options(options)
    clear_search_request_filter_attributes_with_descriptions
  end
  
  def perform_search_request(options = {})
    setup_search_request(options)
    @search_response = @search_request.perform
  end
  
  def deals_as_json
    @search_response.deals.collect { |deal|
      deal_json = deal.as_json_with_options({ :only => [:value_proposition], :methods => [:start_at_date_only] })
      deal_json[:daily_deal].merge!({
      #The following data is specific to the ui and the user context so adding them here instead of the model
          :sourceable_by_publisher  => deal.sourceable_by_publisher?(@publisher),
          :sourced_by_publisher     => deal.sourced_by_publisher?(@publisher),
          :sourced_by_network       => deal.sourced_by_network?(@publisher),
          :distributed_by_publisher => deal.distributed_by_publisher?(@publisher),
          :distributed_by_network   => deal.distributed_by_network?(@publisher),
          :syndication_deal_url     => syndication_deal_path(deal, Syndication::RequestParameters.collect(request)),
          :show_on_calendar_url     => show_on_calendar_syndication_deal_path(deal),
          :id => deal.id
      })
      deal_json
    }
  end
  
  private
  
  def redirect_with_error(deal, message)
    redirect_to syndication_deal_path(deal, Syndication::RequestParameters.collect(request))
    flash[:error] = message
  end
  
  def current_publisher
    @publisher
  end
  
  def create_search_request
    if params[:reset].present?
      reset_search_request
    end
    @search_request = create_search_request_based_on_action
    @search_request.publisher = @publisher
  end
  
  def reset_search_request
    params[:search_request] = nil
    cookies[:syndication_default_location] = nil
  end
  
  def set_search_request_parameters
    @search_request.paging.current_page = params[:page] if params[:page].present?
    @search_request.status = params[:status] if params[:status].present?
    if params[:sort].present?
      @search_request.sort = params[:sort]
    else
      @search_request.sort = Syndication::SearchRequest::Sort::START_DATE_ASCENDING
    end
    if cookies[:syndication_default_location].present? && 
       (@search_request.filter.location.blank? && @search_request.filter.location != 'Zip Code')
      @search_request.filter.location = cookies[:syndication_default_location]
    end
  end
  
  def set_search_request_options(options)
    @search_request.filter.require_locations = options[:require_locations] if options[:require_locations].present?
    @search_request.paging.page_size = options[:default_page_size] || 10 # defaulting to 10, in absence of any guidance ;)
  end
  
  def clear_search_request_filter_attributes_with_descriptions
    @search_request.filter.location = nil if @search_request.filter.location == 'Zip Code'
    @search_request.filter.text = nil if @search_request.filter.text == 'Search Deals'
  end
  
  def create_search_request_based_on_action
    action_name == "map" ? Syndication::MapSearchRequest.new(params[:search_request]) : Syndication::SearchRequest.new(params[:search_request])
  end
  
  def set_default_location_cookie
    if request.env['HTTP_REFERER'].try(:include?, 'syndication/login')
      cookies[:syndication_default_location] = { :value => current_publisher.zip, :expires => 24.hours.from_now }
    end
  end
  
end
