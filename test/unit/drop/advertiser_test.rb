require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Drop::AdvertiserTest
module Drop
  class AdvertiserTest < ActiveSupport::TestCase
    test "Should delegate specific methods" do
      advertiser = Factory(:advertiser)
      drop = Drop::Advertiser.new(advertiser)
      assert_equal advertiser.store.address_line_1, drop.address_line_1, "address_line_1 should be the same"
      assert_equal advertiser.store.city, drop.city, "city should be the same"
      assert_equal advertiser.store.state, drop.state, "state should be the same"
      assert_equal advertiser.store.zip, drop.zip, "zip should be the same"
    end
  end
end
