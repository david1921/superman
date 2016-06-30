module Yelp
  class Client
    def initialize(credentials)
    end

    def find_business(business_id)
      if business_id == "a-test-business"
        {
          :id => "a-test-business",
          :name => "Test Business",
          :url => "http://www.yelp.com/biz/a-test-business",
          :rating => 2.0,
          :rating_img_url =>
            "http://example.com/rating_image.png",
          :review_count => 220,
          :reviews => [
            {
              :id => "JnGtgOPpkjyWOvWM0SYEXg",
              :rating => 5,
              :excerpt => "A great business!",
              :time_created => 1317918655,
              :user => {
                :image_url =>
                  "http://example.com/user_image.jpg",
                :name => "Hen A."
              }
            }
          ]
        }
      end
    end
  end
end
