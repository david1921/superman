module DailyDeals
  class SearchRequest
  
    class Sort
    
      attr_reader :on, :direction
    
      # Creates a new Sort object used in the DailyDealSearchRequest,
      # with a given on value like "Price", "Location", etc and a
      # direction which can be "ascending" or "descending".
      def initialize(on, direction = "ascending")
        @on         = on
        @direction  = direction
      end
    
    end
    
    # Helper class method to perform a serach.
    # Just initializes a new SearchRequest and
    # issues a perform.  Equivalent to running:
    #
    # request = DailyDeals::SearchRequest.new(...)
    # request.perform
    #
    # see #perform
    def self.perform(parameters={})
      new(parameters).perform
    end
    
    
    attr_reader :publisher, :categories, :location, :distance, :distance_unit, :sort_by, :sort_direction, :page, :page_size
  
    # Creates a new daily deal search request
    # with the given options.  
    #
    # Options:
    #
    # :publisher      - this is the Publisher to limit the daily deal search to
    # :consumer       - this is the consumer who is doing the search, and if given will limit results for consumer
    # :categories     - the categories to limit to, if nil or empty then this option isn't used -- must be an array of names or ids
    # :location       - the place or postal code, if nil then this option isn't used
    # :distance       - used in conjunction with :location, if nil then defaults to XX
    # :distance_unit  - what unit the distance is in km or miles, defaults to miles. 
    # :sort           - an array of DailyDealSearchRequest::Sort objects
    #
    # NOTE: we need to keep in mind that we will be adding paging as well, with the following parameters:
    # :page       - the current page, defaults to 1
    # :page_size  - the number of results on a page, default is 20
    def initialize(parameters={})
      @publisher      = parameters[:publisher]
      @categories     = load_categories_by_name_or_id(@publisher, parameters[:categories])
      @location       = lookup_location(parameters[:location])
      @distance       = parameters[:distance]
      @distance_unit  = parameters[:distance_unit]
      
      @sort_by        = parameters[:sort_by]
      @sort_direction = parameters[:sort_direction]
      
      @page           = (parameters[:page] || 1).to_i
      @page_size      = (parameters[:page_size] || 20).to_i
    end
  
    # Does the search and returns DailyDeals::SearchResponse
    def perform
      # This will allow us to switch backend data structure for
      # searching pretty easily.
      perform_by_mysql
    end
  
    private
  
    def perform_by_mysql
      daily_deals = nil
      if publisher
        daily_deals = find_for_publisher_via_mysql
      else
        raise NotImplementedError, "What should we do if no publisher is given, is this even allowed."
      end
      SearchResponse.new(daily_deals)
    end
  
    def load_categories_by_name_or_id(publisher, categories_by_name_or_id)
      return [] unless categories_by_name_or_id && categories_by_name_or_id.any?
      categories_by_name_or_id.collect do |category_name_or_id|
        if publisher
          publisher.daily_deal_categories.find_by_id(category_name_or_id) || publisher.daily_deal_categories.find_by_name(category_name_or_id)
        else
          raise NotImplementedError, "Not test or implemented yet, not sure if we need this capability without a publisher"
          #DailyDealCategory.analytics.find_by_name_or_id(category_name_or_id)
        end
      end
    end
    
    def find_for_publisher_via_mysql
      includes      = [:publisher, :advertiser]
      joins         = ["inner join daily_deal_translations on daily_deal_translations.daily_deal_id = daily_deals.id"]
      substitutions = {:publisher_id => publisher.id, :now => Time.zone.now}
      conditions    = "daily_deals.deleted_at IS NULL AND daily_deals.hide_at > :now"
      conditions    << " AND daily_deals.publisher_id = :publisher_id"
      
      build_categories_search(includes, substitutions, conditions)
      build_location_search(includes, substitutions, conditions)
      
      DailyDeal.paginate(
        :page => page, 
        :per_page => page_size,
        :include => includes,
        :joins => joins,
        :conditions => [conditions, substitutions],
        :order => mysql_order_clause
      )  
    end
    
    def build_categories_search(includes, substitutions, conditions)
      if categories.any?
        substitutions[:category_ids] = categories.collect(&:id)
        conditions << " AND daily_deals.publishers_category_id in (:category_ids)"
      end
    end
    
    def build_location_search(includes, substitutions, conditions)
      if location        
        includes << { :advertiser => :stores }        
        store_ids = Store.find(:all, :origin => [location.lat,location.lng], :within => distance_in_miles).collect(&:id)
        substitutions[:store_ids] = store_ids
        conditions << " AND stores.id in (:store_ids)" 
      end
    end
    
    def distance_in_miles
      "miles" == distance_unit ? distance.to_i : distance.to_i / 0.621371
    end
    
    def lookup_location(location)
      return nil unless location
      lat_and_lng = Geokit::Geocoders::MultiGeocoder.geocode(location)
      Geokit::LatLng.normalize(lat_and_lng.lat,lat_and_lng.lng)
    end
    
    def mysql_order_clause
      case sort_by
      when "price"
        "daily_deals.price #{mysql_order_direction}"
      when "start_at"
        "daily_deals.start_at #{mysql_order_direction}"
      when "title"
        "daily_deal_translations.value_proposition #{mysql_order_direction}"
      else
        "daily_deals.id asc"
      end
    end
    
    def mysql_order_direction
      "descending" == sort_direction ? "desc" : "asc"
    end
  
  end
end