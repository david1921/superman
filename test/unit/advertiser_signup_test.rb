require File.dirname(__FILE__) + "/../test_helper"

class AdvertiserSignupTest < ActiveSupport::TestCase
  test "create" do
    AdvertiserSignup.create!(:advertiser => advertisers(:burger_king), :user => users(:quentin), :publisher => publishers(:my_space))
  end
end
