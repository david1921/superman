require File.dirname(__FILE__) + "/../../test_helper"

class Users::NamedScopesTest < ActiveSupport::TestCase
  context "#with_off_platform_purchases" do
    should "return users that have off-platform purchases" do
      assert User.with_off_platform_purchases.empty?
      user = Factory(:user)
      opp = Factory(:off_platform_daily_deal_purchase, :api_user => user)
      assert_contains User.with_off_platform_purchases, user
    end
  end

  context "#with_id" do
    should "return the user with the specified id" do
      user = Factory(:user)
      assert_equal [user], User.with_id(user.id)
    end

    should "return empty array if no matching user" do
      assert_equal [], User.with_id(-1)
    end
  end
end
