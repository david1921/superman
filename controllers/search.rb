# common search functionality for controllers, see offers and advertisers controller.
module Search

  # Remember search request params as assigned variable. As-is.
  def assign_search_params
    self.class.benchmark "#{self.class}#assign_search_params" do
      # Local.com passes us their "SiteID" which correlates to Publisher#label
      if request.host[/^locm./]
        @publisher = Publisher.find_by_label!(params[:publisher_id])
      else
        @publisher ||= Publisher.find(params[:publisher_id])
      end
      @background_color = params[:background_color]
      @city             = params[:city]
      @foreground_color = params[:foreground_color]
      @iframe_height    = params[:iframe_height]
      @iframe_width     = params[:iframe_width]
      @layout           = params[:layout]
      @postal_code      = params[:postal_code]
      @publisher_id     ||= params[:publisher_id]
      @radius           = params[:radius]
      @state            = params[:state]
      @text             = params[:text] 
      @sort             = params[:sort]
    end
  end

  def create_search_request
    self.class.benchmark "#{self.class}#create_search_request" do
      search_params = params.symbolize_keys
      search_params[:postal_code] = search_params[:zip] if search_params[:zip].present?
      search_params = search_params.slice(*SearchRequest::ATTRIBUTES).merge(:publisher => @publisher, :categories => @categories)
      SearchRequest.create(search_params)
    end
  end
  
  def randomize_coupons(search_request)
    self.class.benchmark "#{self.class}#randomize_coupons", Logger::DEBUG, false do
      if (randomize = @publisher.random_coupon_order?)
        order = @order = params[:order].try(:to_i) || rand(2**32)
      else
        order = 0
      end
      @offers.sort! do |a, b|
        Offer.compare(a, b, search_request.categories.present?, randomize, order)
      end
    end
  end 
  
  def update_search_params(search_request)
    publisher = search_request.publisher
    @postal_code ||= publisher.default_offer_search_postal_code unless publisher.default_offer_search_postal_code.blank?
    @radius      ||= publisher.default_offer_search_distance    unless publisher.default_offer_search_distance.blank?
  end
  
end