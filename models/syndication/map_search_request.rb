class Syndication::MapSearchRequest < Syndication::SearchRequest
  
  class Bounds
    
    # Default represents the US view of the map.
    DEFAULT_ZOOM      = "4"
    DEFAULT_CENTER    = "35.23826597039702,-99.21997699999997"
    
    attr_accessor :ne, :sw, :center, :zoom, :location_blank
    
    def initialize(*args)
      params  = (args.pop||{}).with_indifferent_access
      @location_blank = params[:location_blank]
      if @location_blank
        @ne = params[:ne].present? ? Geokit::LatLng.normalize(params[:ne]) : nil
        @sw = params[:sw].present? ? Geokit::LatLng.normalize(params[:sw]) : nil
        @zoom   = params[:zoom] || DEFAULT_ZOOM
        @center = params[:center].present? ? Geokit::LatLng.normalize(params[:center]) : Geokit::LatLng.normalize(DEFAULT_CENTER)
      else
        @ne     = nil
        @sw     = nil
        @zoom   = DEFAULT_ZOOM
        @center = Geokit::LatLng.normalize(DEFAULT_CENTER)
      end
    end   
    
    def valid?
      (@ne && @sw) || @location_blank
    end
       
  end
  
  attr_reader :bounds
  
  def initialize(*args)
    params = (args.pop || {}).with_indifferent_access    
    location_blank = params[:filter][:location].blank? || params[:filter][:location] == "Zip Code" if params[:filter].present?
    @filter = Filter.new( params[:filter] )    
    @paging = Paging.new( params[:paging] )
    @bounds = Bounds.new( (params[:bounds]||{}).merge(:location_blank => location_blank) )    
    filter.location = "Zip Code" if @bounds.valid? # we have bounds information so don't use zip code
  end
  
  def map?
    true
  end
  
  def latitude
    @bounds.valid? ? @bounds.center.lat : super
  end
  
  def longitude
    @bounds.valid? ? @bounds.center.lng : super
  end
  
  def zoom_level
    @bounds.valid? ? @bounds.zoom : super
  end
  
  
  def perform_search(includes, substitutions, conditions)
    includes << { :advertiser => :stores } # make sure we include stores
    includes << [:translations] # make sure we include translations as well
    results       = DailyDeal.find(:all,:include => includes,:conditions => [conditions, substitutions],:order => order_clause)
    results.sort_by_distance_from(@bounds.center) if @bounds.center
    page_size     = paging.page_size 
    current_page  = paging.current_page
    results.class_eval do
      define_method(:total_entries) do
        results.size
      end
      define_method(:total_pages) do
        (total_entries / page_size.to_f).ceil
      end
      define_method(:current_page) do
        current_page
      end
    end
    results
  end
  
  
end