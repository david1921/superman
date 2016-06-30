module Drop
  class Advertiser < Liquid::Drop
    delegate :address,
             :address?,
             :logo_dimension_valid_for_facebook?,
             :map_url,
             :name,
             :website_url, 
             :standard_logo_width,
             :standard_logo_height,
             :formatted_phone_number,
             :to_map_json,
             :do_not_show_map?,
             :to => :advertiser
             
    delegate :city,
             :state,
             :address_line_1, 
             :address_line_2, 
             :zip,
             :latitude,
             :longitude,
             :to => :store,
             :allow_nil => true

    def initialize(advertiser)
      @advertiser = advertiser
    end
    
    def google_map_url
      if stores.present?
        store.google_map_url advertiser.name
      end
    end

    def logo
      Drop::Logo.new advertiser.logo
    end
    
    def standard_logo_height
      standard_logo_geometry.height
    rescue
      ""
    end
    
    def standard_logo_width
      standard_logo_geometry.width
    rescue
      ""
    end
    
    def stores
      @stores ||= advertiser.stores.map { |store| Drop::Store.new(store) }
    end
    
    def num_stores
      advertiser.stores.size
    end
    
    def id
      advertiser.id
    end
    
    def website_url_without_http
      advertiser.website_url.try(:gsub, "http://", "")
    end
    
    def standard_logo_geometry
      @standard_logo_geometry ||= Paperclip::Geometry.from_file(logo.to_file(:standard))
    end
    
    def advertiser
      @advertiser
    end
    
    def store
      advertiser.store
    end

    def country
      Drop::Country.new(store.try(:country))
    end
    
    def offers
    end

  end
end
