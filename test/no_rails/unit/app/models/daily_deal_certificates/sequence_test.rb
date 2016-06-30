require File.dirname(__FILE__) + "/../../models_helper"

class DailyDealCertificates::SequenceTest < Test::Unit::TestCase
  should "match the recipient's index in the purchase recipients" do
    purchase = stub('purchase', :recipient_names => ['one', 'two'])
    cert = stub('Certificate', :redeemer_name => 'two', :daily_deal_purchase => purchase)
    cert.extend(DailyDealCertificates::Sequence)
    assert_equal 2, cert.sequence
  end
end