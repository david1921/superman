class SearchRequest
  ATTRIBUTES = [ :categories, :city, :radius, :postal_code, :publisher, :state, :text, :sort, :featured ]
  ATTRIBUTES.each { |attribute| attr_accessor attribute }
  
  # Factory. Create SearchRequst from Hash, or simply return SearchRequest.
  def SearchRequest.create(options)
    if options.is_a?(Array)
      options = options.first
    end
    
    case options
    when Hash
      SearchRequest.new(options)      
    when SearchRequest
      options
    else
      raise "Can't create SearchRequest from #{options.class}"
    end
  end
  
  # radius to_i: Nil, blank, and non-numeric all evaluate to 0
  def initialize(options)
    case options
    when Hash
      # Nothing to do
    when Array
      options = options.first
    when SearchRequest
      raise "Can't create SearchRequest from SearchRequest. Use SearchRequest.create"
    else
      raise "Can't create SearchRequest from #{options.class}"
    end
    
    options.assert_valid_keys ATTRIBUTES

    @city = options[:city]
    city.strip! if city

    @publisher = options[:publisher]
    raise "publisher required" unless publisher

    @categories = Array.wrap(options[:categories])

    @radius = options[:radius]
    self.radius = radius.to_i

    @state = options[:state]
    state.strip! if state

    @text = options[:text]
    text.strip! if text

    @postal_code = options[:postal_code]
    postal_code.strip! if postal_code

    @sort = options[:sort]
    sort.strip! if sort
        
    @featured = options[:featured].present? ? options[:featured].to_s == 'true' : false
    
    if postal_code.blank? && text.zip_code?
      self.postal_code = text
      self.text = nil
    else
      if radius == 0 && publisher.default_offer_search_distance
        self.radius = publisher.default_offer_search_distance
      end
    end
    
    # set the default postal code, if we are doing a default search
    # ie, no search text
    if @text.blank?
      @postal_code ||= publisher.default_offer_search_postal_code unless publisher.default_offer_search_postal_code.blank?
    end
        
    self.postal_code = postal_code_from(self.postal_code, city, state)
  end
  
  def postal_code_from(postal_code, city, state)
    return postal_code if postal_code.zip_code? || city.blank? || state.blank?
    
    zip_code = ZipCode.find_by_city_and_state(city, state)
    if zip_code
      zip_code.zip
    else
      postal_code
    end
  end
  
  
  def no_zip_for_city_and_state?
    city.present? && state.present? && postal_code.blank?
  end
  
  def to_s
    "#<SearchRequest cats: #{categories.size}, radius: #{radius}, zip: #{postal_code}, pub: #{publisher.id}, text: #{text}>"
  end  
  
  def featured?
    @featured
  end
end
