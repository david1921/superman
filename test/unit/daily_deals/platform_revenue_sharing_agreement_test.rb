
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::PlatformRevenueSharingAgreement < ActiveSupport::TestCase
  test "revenue sharing agreements" do
    daily_deal = Factory(:daily_deal)
    assert_nil daily_deal.platform_revenue_sharing_agreement
    prsa = Factory(:platform_revenue_sharing_agreement, :agreement => daily_deal)
    assert_equal daily_deal.reload.platform_revenue_sharing_agreement, prsa
  end
end
