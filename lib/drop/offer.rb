module Drop
  class Offer < Liquid::Drop
    include ActionController::UrlWriter
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::AssetTagHelper
    include CouponsHelper

    delegate :publisher, :facebook_description, :value_proposition, :message, :label, :id, :website_url, 
      :terms_with_expiration, :terms_with_expiration_as_textiled, :terms, :terms_as_textiled, :headline, :publisher_id, :to => :offer
    
    def initialize(offer)
      @offer = offer
    end
    
    def advertiser
      Drop::Advertiser.new(offer.advertiser)
    end
    
    def facebook_title
      "[#{publisher.brand_name_or_name} Coupon] #{offer.value_proposition}"
    end    
    
    def facebook_image_src
      url_for_facebook_image(offer)
    end 
    
    def photo
      Drop::Photo.new( offer.photo )
    end 
    
    def offer_image
      Drop::OfferImage.new( offer.offer_image )
    end
    
    def url
      public_offers_url(publisher, :offer_id => offer, :host => publisher.production_host)
    end

    private
    
    def offer
      @offer
    end
    
  end
end