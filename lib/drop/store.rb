module Drop
  class Store < Liquid::Drop
    delegate :city,
             :state,
             :formatted_phone_number,
             :address_line_1, 
             :address_line_2, 
             :zip,
             :latitude, 
             :longitude,
             :to => :store

    def initialize(store)
      @store = store
    end
    
    def id
      store.id
    end

    def google_map_url
      store.google_map_url( store.advertiser.name )
    end

    def country
      Drop::Country.new(store.country)
    end

    def address_line_2_blank?
      store.address_line_2.blank?
    end

    private
    
    def store
      @store
    end
  end
end
