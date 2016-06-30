require File.dirname(__FILE__) + "/../test_helper"

class ReportApiRequestTest < ActiveSupport::TestCase
  def test_create
    publisher = publishers(:li_press)

    report_api_request = ReportApiRequest.create(:publisher => publisher, :dates_begin => "2009-09-01", :dates_end => "2009-09-30")
    assert_not_nil report_api_request
    assert_equal publisher, report_api_request.publisher
    assert_equal Date.new(2009, 9,  1), report_api_request.dates_begin
    assert_equal Date.new(2009, 9, 30), report_api_request.dates_end
    
    assert_nil report_api_request.error
  end
  
  def test_date_validation
    publisher = publishers(:li_press)
    
    assert_invalid_date(publisher, :dates_begin => "20090901")
    assert_invalid_date(publisher, :dates_begin => "2009-9-01")
    assert_invalid_date(publisher, :dates_begin => "x009-09-01")
    assert_invalid_date(publisher, :dates_begin => "2009/09/01")
    assert_invalid_date(publisher, :dates_begin => "01-09-2009")
    
    assert_invalid_date(publisher, :dates_end => "20090901")
    assert_invalid_date(publisher, :dates_end => "2009-9-01")
    assert_invalid_date(publisher, :dates_end => "x009-09-01")
    assert_invalid_date(publisher, :dates_end => "2009/09/01")
    assert_invalid_date(publisher, :dates_end => "01-09-2009")
  end
  
  def test_advertisers_with_offers_and_txt_offers
    publisher = publishers(:houston_press)
    publisher.advertisers.destroy_all
    
    report_api_request = ReportApiRequest.create!(:publisher => publisher, :dates_begin => "2009-09-01", :dates_end => "2009-09-30")
    expected = {}
    assert_equal expected, report_api_request.advertisers_with_offers_and_txt_offers, "No advertisers"
    
    advertiser_1 = publisher.advertisers.create!(:name => "A1", :listing => "1")
    expected = {}
    assert_equal expected, report_api_request.advertisers_with_offers_and_txt_offers, "Advertiser but no offers"
    
    offer_1_1 = advertiser_1.offers.create!(:message => "A1O1")
    expected = { advertiser_1 => { :offers => [offer_1_1] }}
    assert_equal expected, report_api_request.advertisers_with_offers_and_txt_offers, "One advertiser with one offer"

    advertiser_2 = publisher.advertisers.create!(:name => "A2", :listing => "2")
    
    offer_2_1 = advertiser_2.offers.create!(:message => "A2O1")
    keyword = advertiser_2.txt_keyword_prefixes.first + "A2T1"
    txt_offer_2_1 = advertiser_2.txt_offers.create!(:short_code => "898411", :keyword => keyword, :message => "A2T1")
    expected = { advertiser_1 => { :offers => [offer_1_1] }, advertiser_2 => { :offers => [offer_2_1], :txt_offers => [txt_offer_2_1] }}
    assert_equal expected, report_api_request.advertisers_with_offers_and_txt_offers, "Two advertisers"
  end
  
  private
  
  def assert_invalid_date(publisher, options)
    attrs = { :dates_begin => "2009-09-01", :dates_end => "2009-09-30" }.merge(options)
    report_api_request = publisher.report_api_requests.build(attrs)
    assert !report_api_request.valid?
    assert_kind_of ApiRequest::InvalidDateError, report_api_request.error
  end
end
