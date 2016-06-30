require File.dirname(__FILE__) + "/../test_helper"

class SubscriberReferrerCodeTest < ActiveSupport::TestCase
  
  test "create with no code supplied" do
    subscriber_referrer_code = SubscriberReferrerCode.create
    assert subscriber_referrer_code.valid?
    assert_not_nil subscriber_referrer_code.code, "should generate the code"
  end
  
  test "create with code supplied" do
    subscriber_referrer_code = SubscriberReferrerCode.create(:code => "MYCODE")
    assert subscriber_referrer_code.valid?
    assert_equal "MYCODE", subscriber_referrer_code.code, "should set the code to the supplied code"
  end
  
  test "create with a code that is already supplied" do
    existing_subscriber_referrer_code = SubscriberReferrerCode.create(:code => "MYCODE")
    subscriber_referrer_code = SubscriberReferrerCode.create(:code => "MYCODE")
    assert !subscriber_referrer_code.valid?
    assert !subscriber_referrer_code.errors.on(:code).empty?    
  end
                                                            
end
