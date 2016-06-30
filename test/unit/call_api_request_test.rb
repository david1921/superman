require File.dirname(__FILE__) + "/../test_helper"

class CallApiRequestTest < ActiveSupport::TestCase
  def test_create
    publisher = publishers(:li_press)
    call_api_request = CallApiRequest.create(
      :publisher => publisher,
      :consumer_phone_number => "6266745901",
      :merchant_phone_number => "8005551212"
    )
    assert_not_nil call_api_request
    assert_equal publisher, call_api_request.publisher
    assert_equal "16266745901", call_api_request.consumer_phone_number
    assert_equal "18005551212", call_api_request.merchant_phone_number
  end

  def test_create_creates_voice_message
    assert_nil VoiceMessage.find_by_mobile_number("16266745901")
  
    assert_difference 'VoiceMessage.count' do
      publishers(:li_press).call_api_requests.create! :consumer_phone_number => "6266745901", :merchant_phone_number => "8005551212"
    end
    voice_message = VoiceMessage.find_by_mobile_number("16266745901")
    assert_not_nil voice_message, "Should have created voice message with given mobile number"
    assert_equal "18005551212", voice_message.center_phone_number, "New voice message should have the given center phone number"
    assert_equal "created", voice_message.status, "New voice message status"
  end
  
  def test_consumer_phone_number_validation
    publisher = publishers(:li_press)
    mpn = "8005551212"
    
    call_api_request = publisher.call_api_requests.build(:consumer_phone_number => "626674590", :merchant_phone_number => mpn)
    assert !call_api_request.valid?
    assert call_api_request.errors.on(:consumer_phone_number)
    
    call_api_request = publisher.call_api_requests.build(:consumer_phone_number => "62667459012", :merchant_phone_number => mpn)
    assert !call_api_request.valid?
    assert call_api_request.errors.on(:consumer_phone_number)
    
    call_api_request = publisher.call_api_requests.build(:consumer_phone_number => "626674590x", :merchant_phone_number => mpn)
    assert !call_api_request.valid?
    assert call_api_request.errors.on(:consumer_phone_number)
  end
  
  def test_consumer_phone_number_normalization
    publisher = publishers(:li_press)
    mpn = "8005551212"
    
    call_api_request = publisher.call_api_requests.build(:consumer_phone_number => "6266745901", :merchant_phone_number => mpn)
    assert call_api_request.valid?
    assert_equal "16266745901", call_api_request.consumer_phone_number
    
    call_api_request = publisher.call_api_requests.build(:consumer_phone_number => "626-674-5901", :merchant_phone_number => mpn)
    assert call_api_request.valid?
    assert_equal "16266745901", call_api_request.consumer_phone_number
    
    call_api_request = publisher.call_api_requests.build(:consumer_phone_number => "(626) 674-5901", :merchant_phone_number => mpn)
    assert call_api_request.valid?
    assert_equal "16266745901", call_api_request.consumer_phone_number
  end
  
  def test_merchant_phone_number_validation
    publisher = publishers(:li_press)
    cpn = "6266745901"
    
    call_api_request = publisher.call_api_requests.build(:consumer_phone_number => cpn, :merchant_phone_number => "800555121")
    assert !call_api_request.valid?
    assert call_api_request.errors.on(:merchant_phone_number)
    
    call_api_request = publisher.call_api_requests.build(:consumer_phone_number => cpn, :merchant_phone_number => "80055512123")
    assert !call_api_request.valid?
    assert call_api_request.errors.on(:merchant_phone_number)
    
    call_api_request = publisher.call_api_requests.build(:consumer_phone_number => cpn, :merchant_phone_number => "800555121x")
    assert !call_api_request.valid?
    assert call_api_request.errors.on(:merchant_phone_number)
  end
  
  def test_merchant_phone_number_normalization
    publisher = publishers(:li_press)
    cpn = "6266745901"
    
    call_api_request = publisher.call_api_requests.build(:consumer_phone_number => cpn, :merchant_phone_number=> "8005551212")
    assert call_api_request.valid?
    assert_equal "18005551212", call_api_request.merchant_phone_number
    
    call_api_request = publisher.call_api_requests.build(:consumer_phone_number => cpn, :merchant_phone_number => "800-555-1212")
    assert call_api_request.valid?
    assert_equal "18005551212", call_api_request.merchant_phone_number
    
    call_api_request = publisher.call_api_requests.build(:consumer_phone_number => cpn, :merchant_phone_number => "(800) 555-1212")
    assert call_api_request.valid?
    assert_equal "18005551212", call_api_request.merchant_phone_number
  end
end
