require File.dirname(__FILE__) + "/../../test_helper"

class BaseDailyDealPurchases::RefundsAndVoidsTest < ActiveSupport::TestCase
  context "#partial_refund!" do
    should "work for off-platform purchases" do
      opddp = Factory(:off_platform_daily_deal_purchase)
      opddp.capture!
      opddp.partial_refund!(Factory(:admin), opddp.daily_deal_certificate_ids)
      opddp.daily_deal_certificates.each do |cert|
        assert cert.refunded?
      end
    end
  end
end
