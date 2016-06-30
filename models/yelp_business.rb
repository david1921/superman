class YelpBusiness < ActiveRecord::Base
  include YelpBusinesses::Core

  has_many :yelp_reviews

  validates_presence_of :yelp_id, :url, :rating_image_url,
                        :average_rating, :review_count
end
