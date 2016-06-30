require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealCertificates::StatusTest < ActiveSupport::TestCase
  context "#set_status!" do
    should "update the certificate's status'" do
      cert = Factory(:daily_deal_certificate)
      cert.set_status!('redeemed')
      assert_equal 'redeemed', DailyDealCertificate.find(cert.id).status
    end
  end
end
