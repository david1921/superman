module DailyDeals
  module Map
    
    def self.included(base)
      base.send :include, InstanceMethods
    end
    
    module InstanceMethods

      def to_map_json
        stores = advertiser.stores.map do |store|
          {
            :latitude  => store.latitude.to_s, 
            :longitude => store.longitude.to_s
          }
        end

        {
          :daily_deal => {
            :id => id,
            :value_proposition => value_proposition,
            :start_at => start_at.strftime("%m/%d/%Y"),
            :hide_at  => hide_at.strftime("%m/%d/%Y"),
            :price    => number_to_currency( price, :unit => currency_code ),
            :image    => photo.url(:syndication),
            :national_deal => national_deal?,
            :stores   => stores
          }
        }.to_json
      end
      
      def distance_to(origin, opts={})
        distance = 99999 # make the default distance super far away, this for stores with no lat/lng
        return distance unless advertiser && advertiser.stores.any?                
        store_minimum_distance_away = advertiser.stores.min {|a,b| a.distance_to(origin, opts) <=> b.distance_to(origin, opts)}        
        distance = store_minimum_distance_away.distance_to(origin, opts={}) if store_minimum_distance_away.latitude_and_longitude_present?
        distance
      end
      
            
    end
    
  end
end