class YelpReview < ActiveRecord::Base
  belongs_to :yelp_business

  validates_presence_of :yelp_id, :excerpt, :user_name, :user_image_url,
                        :rating, :reviewed_at

  def url
    "#{yelp_business.url}#hrid:#{yelp_id}"
  end
end
