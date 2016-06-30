require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::SyndicationRevenueSharingAgreementTest < ActiveSupport::TestCase
  context "associations" do
    should "return syndication_revenue_sharing_agreement" do
      daily_deal = Factory(:daily_deal)
      assert_nil daily_deal.syndication_revenue_sharing_agreement
      srsa = Factory(:syndication_revenue_sharing_agreement, :agreement => daily_deal)
      assert_equal daily_deal.reload.syndication_revenue_sharing_agreement, srsa
    end
  end
end
