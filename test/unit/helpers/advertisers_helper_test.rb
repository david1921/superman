require File.dirname(__FILE__) + "/../../test_helper"

class AdvertisersHelperTest < ActionView::TestCase
  context "#can_delete_coupon?" do
    should "return true for a full admin" do
      admin = Factory(:admin)
      assert can_delete_coupon? admin
    end

    should "return true for a restricted admin" do
      restricted_admin = Factory(:restricted_admin)
      assert can_delete_coupon? restricted_admin
    end

    should "return false for non-admins" do
      user = Factory(:user)
      assert !can_delete_coupon?(user)
    end
  end

end
