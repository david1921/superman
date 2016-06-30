require File.dirname(__FILE__) + "/../test_helper"

class YelpReviewTest < ActiveSupport::TestCase
  should belong_to :yelp_business
  should validate_presence_of :yelp_id
  should validate_presence_of :excerpt
  should validate_presence_of :user_name
  should validate_presence_of :user_image_url
  should validate_presence_of :rating
  should validate_presence_of :reviewed_at
end
