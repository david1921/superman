module YelpBusinesses
  module Core
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def new_via_api(credentials, business_id)
        client = Yelp::Client.new(credentials)

        if response = client.find_business(business_id)
          new_from_api_response(response)
        end
      end

      def find_or_initialize_by_business_id_via_api(credentials, business_id)
        find_by_yelp_id(business_id) || new_via_api(credentials, business_id)
      end

      private

      def new_from_api_response(response)
        business = new(
          :yelp_id => response[:id],
          :name => response[:name],
          :url => response[:url],
          :average_rating => response[:rating],
          :rating_image_url => response[:rating_img_url],
          :review_count => response[:review_count]
        )

        response[:reviews].each do |review_response|
          business.yelp_reviews.build(
            :yelp_id => review_response[:id],
            :excerpt => review_response[:excerpt],
            :user_name => review_response[:user][:name],
            :user_image_url => review_response[:user][:image_url],
            :rating => review_response[:rating],
            :reviewed_at => Time.at(review_response[:time_created])
          )
        end

        business
      end
    end
  end
end
