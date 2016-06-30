require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealCertificates::SequenceTest < ActiveSupport::TestCase
  context "#sequence" do
    should "match the recipient's index in the purchase recipients" do
      purchase = Factory(:off_platform_daily_deal_purchase, :recipient_names => ['one', 'two'], :quantity => 2)
      purchase.capture!
      cert_two = purchase.daily_deal_certificates.select { |cert| cert.redeemer_name == 'two' }.first
      assert_equal 2, cert_two.sequence
    end
  end
end
