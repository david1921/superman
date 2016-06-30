class Syndication::SearchRequest
  
  module Sort
    START_DATE_ASCENDING = "start_date_asc"
    START_DATE_DESCENDING = "start_date_desc"
    PRICE_ASCENDING = "price_asc"
    PRICE_DESCENDING = "price_desc"
  end
  
  # Filter
  # 
  # Represents the available option in the search filter for syndication.
  class Filter

    attr_accessor :radius, :text, :start_date, :end_date
    attr_reader :national_deals,  :categories
    attr_writer :require_locations, :location
    
    def initialize(*args)
      params = (args.pop || {}).with_indifferent_access
      @national_deals     = params[:national_deals]
      @location           = params[:location]
      @radius             = params[:radius] || 50
      @categories         = params[:categories] || []
      @start_date         = params[:start_date]
      @end_date           = params[:end_date]
      @require_locations  = params[:require_locations]
      @text               = params[:text]
    end
    
    def national_deals?
      ActiveRecord::ConnectionAdapters::Column.value_to_boolean(@national_deals)
    end
    
    def date_range?
      parsed_start_date && parsed_end_date
    end

    def parsed_start_date
      @parsed_start_date ||= parse_date(@start_date)
    end
    
    def parsed_end_date
      @parsed_end_date ||= parse_date(@end_date)
    end

    def location
      @location
    end
    
    # only require locations if required_locations was set
    # to true and we don't already have a location
    def require_locations?
      @require_locations && !@location
    end
    
    private

    def parse_date(date_string)
      return nil unless date_string.present?
      begin
        Time.zone.parse(date_string)
      rescue
        nil
      end
    end

  end
  
  # Paging
  #
  # Represent a paging for the search request.  Paging
  # involves knowing the page size and the current page.
  class Paging
    
    attr_reader :page_size, :current_page
    
    def initialize(*args)
      params = (args.pop || {}).with_indifferent_access
      @page_size    = (params[:page_size] || 10).to_i
      @current_page = (params[:current_page] || 1).to_i
    end
    
    def position_in_current_page?(position)
      @range ||= create_range
      @range.include?(position)
    end
    
    def page_size=(value)
      @page_size = value.to_i
    end
    
    def current_page=(value)
      @current_page = value.to_i
    end
    
    private
    
    
    def create_range
      end_index = @page_size * @current_page
      start_index = end_index - @page_size + 1
      (start_index..end_index)
    end
    
  end
  
  # Available RADIUS filter values in miles.
  RADIUS = [1, 5, 10, 25, 50, 100]
  
  attr_accessor :publisher, :paging, :current_user, :sort, :status
  
  def initialize(*args)
    params = (args.pop || {}).with_indifferent_access    
    @filter = Filter.new( params[:filter] )    
    @paging = Paging.new( params[:paging] )
  end
  
  alias_method :orig_status, :status
  
  def map?
    false
  end
  
  def on_current_page?(deal, position)
    @paging.position_in_current_page?(position)
  end
  
  def status
     orig_status.respond_to?(:to_sym) ? orig_status.to_sym : orig_status
  end
  
  def perform
    #For performance reasons this was changed to be executed as one query rather
    #than chaining the named scopes in daily deal. It's not pretty but it's fast.
    Syndication::SearchResponse.new(:deals => find_deals)
  end
  
  def latitude
    zip_code = zip_code_based_on_filter_location
    if zip_code
      zip_code.latitude
    else
      publisher.google_map_latitude if publisher
    end
  end
  
  def longitude
    zip_code = zip_code_based_on_filter_location
    if zip_code
      zip_code.longitude
    else
      publisher.google_map_longitude if publisher
    end
  end
  
  def zoom_level
    if publisher && publisher.google_map_zoom_level.present?
      publisher.google_map_zoom_level
    else
      6
    end
  end
  
  def find_deals
    publishers_excluded_by_publisher_ids = @publisher.publishers_unavailable_for_distribution_ids
    publishers_not_in_syndication_network_ids = Publisher.not_in_syndication_network.map(&:id)
    
    includes = [:publisher, :advertiser]
    substitutions = {:publisher_id => @publisher.id, :now => Time.zone.now}
    conditions = "daily_deals.deleted_at IS NULL AND daily_deals.hide_at > :now"
    
    if publishers_excluded_by_publisher_ids.present? && !publishers_excluded_by_publisher_ids.empty?
      substitutions.merge!({:publishers_excluded_by_publisher_ids => publishers_excluded_by_publisher_ids})
      conditions << " AND daily_deals.publisher_id NOT IN (:publishers_excluded_by_publisher_ids)"
    end
    
    if publishers_not_in_syndication_network_ids.present? && !publishers_not_in_syndication_network_ids.empty?
      substitutions.merge!({:publishers_not_in_syndication_network_ids => publishers_not_in_syndication_network_ids})
      conditions << " AND daily_deals.publisher_id NOT IN (:publishers_not_in_syndication_network_ids)"
    end
    
    build_status_search(includes, substitutions, conditions)
    build_locations_only(includes, substitutions, conditions)
    build_text_search(includes, substitutions, conditions)
    build_location_search(includes, substitutions, conditions)
    build_categories_search(includes, substitutions, conditions)
    build_national_deals_search(includes, substitutions, conditions)
    build_date_range_search(includes, substitutions, conditions)
    
    perform_search(includes, substitutions, conditions)    
  end
  
  def perform_search(includes, substitutions, conditions)
    DailyDeal.paginate(
      :page => paging.current_page, 
      :per_page => paging.page_size,
      :include => includes,
      :conditions => [conditions, substitutions],
      :order => order_clause
    )    
  end
  
  def build_locations_only(includes, substitutions, conditions)
    if filter.require_locations?
      includes << { :advertiser => :stores }
      conditions << " AND (stores.advertiser_id = advertisers.id AND stores.longitude IS NOT NULL and stores.latitude IS NOT NULL)"
    end
  end
  
  def build_text_search(includes, substitutions, conditions) 
    if filter.text.present?
      includes << [:analytics_category, :publishers_category, :advertiser, {:advertiser => :translations}, :translations]
      substitutions[:text] = filter.text
      conditions << " AND (daily_deal_translations.value_proposition REGEXP '[[:<:]]#{filter.text}[[:>:]]' OR advertiser_translations.name REGEXP '[[:<:]]#{filter.text}[[:>:]]' OR daily_deal_categories.name REGEXP '[[:<:]]#{filter.text}[[:>:]]')"
    end
  end
  
  def build_location_search(includes, substitutions, conditions)
    if filter.location.present?
      zips = filter.radius.present? ? ZipCode.zips_near_zip_and_radius(filter.location, filter.radius.try(:to_i)) : filter.location
      includes << { :advertiser => :stores }
      substitutions[:zips] = zips
      conditions << " AND SUBSTR(stores.zip, 1, 5) in (:zips)"
    end
  end
  
  def build_categories_search(includes, substitutions, conditions)
    if filter.categories.present?
      substitutions[:category_ids] = filter.categories
      conditions << " AND daily_deals.analytics_category_id in (:category_ids)"
    end
  end
  
  def build_national_deals_search(includes, substitutions, conditions)
    if filter.national_deals?
      conditions << " AND daily_deals.national_deal = 1"
    end
  end
  
  def build_date_range_search(includes, substitutions, conditions)
    if filter.date_range?
      dates = [filter.parsed_start_date, filter.parsed_end_date]
      substitutions[:bod] = dates.first.beginning_of_day
      substitutions[:eod] = dates.last.end_of_day
      conditions << " AND start_at BETWEEN :bod and :eod"
      #switch back to sql below if it needs to be by active between
      #" AND daily_deals.deleted_at IS NULL AND ((start_at BETWEEN :bod AND :eod) OR (hide_at BETWEEN :bod AND :eod) OR (start_at <= :bod AND hide_at >= :eod))"
    else
      if filter.parsed_start_date.present?
        date = filter.parsed_start_date
        substitutions[:bod] = date.beginning_of_day
        substitutions[:eod] = date.end_of_day
        conditions << " AND start_at BETWEEN :bod and :eod"
      elsif filter.parsed_end_date.present?
        date = filter.parsed_end_date
        substitutions[:bod] = date.beginning_of_day
        substitutions[:eod] = date.end_of_day
        conditions << " AND hide_at BETWEEN :bod and :eod"
      end
    end
  end
  
  def build_status_search(includes, substitutions, conditions)
    if status == :sourced_by_publisher
      conditions << " AND (daily_deals.publisher_id = :publisher_id AND available_for_syndication = true)"
    elsif status == :sourced_by_network
      conditions << " AND (daily_deals.publisher_id <> :publisher_id AND available_for_syndication = true)"
    elsif status == :distributed_by_publisher
      conditions << " AND (daily_deals.publisher_id = :publisher_id AND available_for_syndication = false AND source_id IS NOT NULL)"
    elsif status == :distributed_by_network
      #conditions << " AND (daily_deals.publisher_id <> :publisher_id AND available_for_syndication = false AND source_id IS NOT NULL)"
      conditions << " AND daily_deals.id IN (select distinct(source_id) from daily_deals where daily_deals.source_id IS NOT NULL)"
    elsif status == :sourceable_by_publisher
      conditions << " AND (daily_deals.publisher_id = :publisher_id AND source_id IS NULL)"
    else
      conditions << %Q{ AND ((daily_deals.publisher_id = :publisher_id)
                              OR (daily_deals.publisher_id <> :publisher_id AND (daily_deals.available_for_syndication = true OR daily_deals.source_id IS NOT NULL)))}
    end
  end
  
  def order_clause
    case sort
      when Syndication::SearchRequest::Sort::START_DATE_ASCENDING
        "start_at"
      when Syndication::SearchRequest::Sort::START_DATE_DESCENDING
        "start_at desc"
      when Syndication::SearchRequest::Sort::PRICE_ASCENDING
        "price"
      when Syndication::SearchRequest::Sort::PRICE_DESCENDING
        "price desc"
      else
        "start_at desc"
    end
  end
  
  def filter
    @filter ||= Filter.new
  end

  def filter=(params)
    @filter = Filter.new(params)
  end
  
  private
  
  def zip_code_based_on_filter_location
    unless filter.blank? || filter.location.blank?
      @zip_code_based_on_filter_location ||= ZipCode.find_by_zip(filter.location)
    end
  end

end
