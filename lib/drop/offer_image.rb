module Drop
  class OfferImage < Liquid::Drop
    delegate :file?,
             :to => :offer_image

    def initialize(offer_image)
      @offer_image = offer_image
    end
    
    def thumbnail_url
      offer_image.url :thumbnail
    end      
    
    def medium_url
      offer_image.url :medium
    end
    
    def large_url
      offer_image.url :large
    end
    
    
    private
    
    def offer_image
      @offer_image
    end
    
  end
end