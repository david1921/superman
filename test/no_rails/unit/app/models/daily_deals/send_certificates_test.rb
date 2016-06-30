require File.dirname(__FILE__) + "/../../models_helper"

class SendCertificatesTest < Test::Unit::TestCase
  should "call send_certificate_or_confirmation_email! on the purchase" do
    purchase = mock('purchase')
    purchase.expects(:send_email!)
    SendCertificates.stubs(:find_purchase).with(123).returns(purchase)
    SendCertificates.perform(123)
  end
end