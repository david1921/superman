module DailyDeals
  module Yelp
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods

      def yelp_api_business_id
        @yelp_api_business_id || yelp_business.try(:yelp_id)
      end

      def set_yelp_business
        return if @yelp_api_business_id == nil || yelp_business.try(:yelp_id) == @yelp_api_business_id

        if @yelp_api_business_id.present?
          credentials = publisher.yelp_credentials

          unless credentials.present?
            errors.add(:base, "Publisher does not have Yelp credentials set")
            return false
          end

          self.yelp_business = YelpBusiness.find_or_initialize_by_business_id_via_api(credentials, @yelp_api_business_id)

          unless self.yelp_business
            errors.add(:base, "No Yelp business found with ID='#{@yelp_api_business_id}'")
            return false
          end
        else
          self.yelp_business = nil
        end

        true
      end

    end
  end
end
