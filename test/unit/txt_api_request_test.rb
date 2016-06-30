require File.dirname(__FILE__) + "/../test_helper"

class TxtApiRequestTest < ActiveSupport::TestCase
  def test_create
    publisher = publishers(:li_press)
    txt_api_request = TxtApiRequest.create(:publisher => publisher, :mobile_number => "6266745901", :message => "test create")
    assert_not_nil txt_api_request
    assert_equal publisher, txt_api_request.publisher
    assert_equal "16266745901", txt_api_request.mobile_number
    assert_equal "test create", txt_api_request.message
  end

  def test_create_creates_txt
    assert_nil Txt.find_by_message("test create")
  
    assert_difference 'Txt.count' do
      publishers(:li_press).txt_api_requests.create! :mobile_number => "6266745901", :message => "test create"
    end
    txt = Txt.find_by_message("TXT411: test create. Std msg chrgs apply. T&Cs at txt411.com")
    assert_not_nil txt, "Should have created TXT with given message"
    assert_equal "16266745901", txt.mobile_number, "New TXT should have the given mobile number"
    assert_equal "created", txt.status, "New TXT status"
  end
  
  def test_mobile_number_validation
    publisher = publishers(:li_press)
    
    txt_api_request = publisher.txt_api_requests.build(:message => "test validation", :mobile_number => "626674590")
    assert !txt_api_request.valid?
    assert txt_api_request.errors.on(:mobile_number)
    
    txt_api_request = publisher.txt_api_requests.build(:message => "test validation", :mobile_number => "62667459012")
    assert !txt_api_request.valid?
    assert txt_api_request.errors.on(:mobile_number)
    
    txt_api_request = publisher.txt_api_requests.build(:message => "test validation", :mobile_number => "626674590a")
    assert !txt_api_request.valid?
    assert txt_api_request.errors.on(:mobile_number)
  end
  
  def test_mobile_number_normalization
    publisher = publishers(:li_press)
    
    txt_api_request = publisher.txt_api_requests.build(:message => "test normalization", :mobile_number => "6265551212")
    assert txt_api_request.valid?
    assert_equal "16265551212", txt_api_request.mobile_number
    
    number = "626-674-5901"
    txt_api_request = publisher.txt_api_requests.build(:message => "test normalization", :mobile_number => "626-555-1212")
    assert txt_api_request.valid?
    assert_equal "16265551212", txt_api_request.mobile_number

    number = "(626) 674-5901"
    txt_api_request = publisher.txt_api_requests.build(:message => "test normalization", :mobile_number => "(626) 555-1212")
    assert txt_api_request.valid?
    assert_equal "16265551212", txt_api_request.mobile_number
  end
end
