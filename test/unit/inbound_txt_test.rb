require File.dirname(__FILE__) + "/../test_helper"

class InboundTxtTest < ActiveSupport::TestCase
  def setup
    TxtOffer.clear_cache
  end
  
  def test_reply_to_stop_and_start_keywords
    assert_txts_to(0, "15147778181")
    
    InboundTxt.create!(
      :message => "STOP PLZ",
      :keyword => "STOP",
      :subkeyword => "PLZ",
      :accepted_time => Time.now,
      :network_type => "gsm",
      :server_address => "898411",
      :originator_address => "15147778181",
      :carrier => "verizon"
    )
    assert_txts_to(1, "15147778181")
    assert_last_txt_message_to(/you won't receive messages/i, "15147778181")

    mobile_phone = MobilePhone.find_by_number("15147778181")
    assert_not_nil(mobile_phone, "Should add mobile phone to opt-out list")
    assert(mobile_phone.opt_out, "Should be opted-out")

    InboundTxt.create!(
      :message => "START PLZ",
      :keyword => "START",
      :subkeyword => "PLZ",
      :accepted_time => Time.now,
      :network_type => "gsm",
      :server_address => "898411",
      :originator_address => "15147778181",
      :carrier => "verizon"
    )
    assert_txts_to(2, "15147778181")
    assert_last_txt_message_to(/messaging service reactivated/i, "15147778181")

    mobile_phone = MobilePhone.find_by_number("15147778181")
    assert_not_nil(mobile_phone, "Should still have mobile phone record")
    assert(!mobile_phone.opt_out, "Should not be opted-out")

    InboundTxt.create!(
      :message => "STOP AGAIN",
      :keyword => "STOP",
      :subkeyword => "AGAIN",
      :accepted_time => Time.now,
      :network_type => "gsm",
      :server_address => "898411",
      :originator_address => "15147778181",
      :carrier => "verizon"
    )
    assert_txts_to(3, "15147778181")
    assert_last_txt_message_to(/you won't receive messages/i, "15147778181")

    mobile_phone.reload
    assert(mobile_phone.opt_out, "Should be opted-out again")
  end
  
  def test_reply_to_quit_and_start_keywords
    assert_txts_to(0, "15147778181")
    
    InboundTxt.create!(
      :message => "quit it",
      :keyword => "quit",
      :subkeyword => "it",
      :accepted_time => Time.now,
      :network_type => "gsm",
      :server_address => "898411",
      :originator_address => "15147778181",
      :carrier => "verizon"
    )
    assert_txts_to(1, "15147778181")
    assert_last_txt_message_to(/you won't receive messages/i, "15147778181")

    mobile_phone = MobilePhone.find_by_number("15147778181")
    assert_not_nil(mobile_phone, "Should add mobile phone to opt-out list")
    assert(mobile_phone.opt_out, "Should be opted-out")

    InboundTxt.create!(
      :message => "START PLZ",
      :keyword => "START",
      :subkeyword => "PLZ",
      :accepted_time => Time.now,
      :network_type => "gsm",
      :server_address => "898411",
      :originator_address => "15147778181",
      :carrier => "verizon"
    )
    assert_txts_to(2, "15147778181")
    assert_last_txt_message_to(/messaging service reactivated/i, "15147778181")

    mobile_phone = MobilePhone.find_by_number("15147778181")
    assert_not_nil(mobile_phone, "Should still have mobile phone record")
    assert(!mobile_phone.opt_out, "Should not be opted-out")
  end
  
  def test_reply_to_help_keyword
    assert_txts_to(0, "15147778181")
    
    InboundTxt.create!(
      :message => "HELP ME",
      :keyword => "HELP",
      :subkeyword => "ME",
      :accepted_time => Time.now,
      :network_type => "gsm",
      :server_address => "898411",
      :originator_address => "15147778181",
      :carrier => "verizon"
    )
    assert_txts_to(1, "15147778181")
    assert_last_txt_message_to(/for help email support@txt411.com/i, "15147778181")

    assert !MobilePhone.number_opted_out?("15147778181"), "Should not add mobile phone to opt-out list"
  end

  def test_reply_to_nil_keyword
    assert_txts_to(0, "15147778181")

    inbound_txt = InboundTxt.create!(
      :message => nil,
      :keyword => nil,
      :subkeyword => nil,
      :accepted_time => Time.now,
      :network_type => "gsm",
      :server_address => "898411",
      :originator_address => "15147778181",
      :carrier => "verizon"
    )

    inbound_txt.reload
    assert_equal("", inbound_txt.message, "message")
    assert_equal("", inbound_txt.keyword, "keyword")
    assert_equal("", inbound_txt.subkeyword, "subkeyword")

    assert_txts_to(0, "15147778181")
    assert_nil(MobilePhone.find_by_number("15147778181"), "Should not create mobile phone record")
  end

  def test_keywords_are_case_insensitive
    assert_txts_to(0, "15147778181")
    
    InboundTxt.create!(
      :message => "stop PLZ",
      :keyword => "stop",
      :subkeyword => "PLZ",
      :accepted_time => Time.now,
      :network_type => "gsm",
      :server_address => "898411",
      :originator_address => "15147778181",
      :carrier => "verizon"
    )
    assert_txts_to(1, "15147778181")
    assert_last_txt_message_to(/you won't receive messages/i, "15147778181")

    mobile_phone = MobilePhone.find_by_number("15147778181")
    assert_not_nil(mobile_phone, "Should add mobile phone to opt-out list")
    assert(mobile_phone.opt_out, "Should be opted-out")
  end

  def test_send_help_to_stopped_mobile_phone
    assert_txts_to(0, "15147778181")
    
    InboundTxt.create!(
      :message => "stop PLZ",
      :keyword => "stop",
      :subkeyword => "PLZ",
      :accepted_time => Time.now,
      :network_type => "gsm",
      :server_address => "898411",
      :originator_address => "15147778181",
      :carrier => "verizon"
    )
    assert_txts_to(1, "15147778181")
    assert_last_txt_message_to(/you won't receive messages/i, "15147778181")

    mobile_phone = MobilePhone.find_by_number("15147778181")
    assert_not_nil(mobile_phone, "Should add mobile phone to opt-out list")
    assert(mobile_phone.opt_out, "Should be opted-out")
  
    InboundTxt.create!(
      :message => "HELP ME",
      :keyword => "HELP",
      :subkeyword => "ME",
      :accepted_time => Time.now,
      :network_type => "gsm",
      :server_address => "898411",
      :originator_address => "15147778181",
      :carrier => "verizon"
    )
    assert_txts_to(2, "15147778181")
    assert_last_txt_message_to(/for help email support@txt411.com/i, "15147778181")
    mobile_phone = MobilePhone.find_by_number("15147778181")
    assert_not_nil(mobile_phone, "mobile phone should still be opted-out")
    assert(mobile_phone.opt_out, "Should be opted-out")
  end
  
  def test_no_reply_to_unknown_keyword
    assert_txts_to(0, "15147778181")

    inbound_txt = InboundTxt.create!(
      :message => "PIZZA 90210",
      :keyword => "PIZZA",
      :subkeyword => "90210",
      :accepted_time => Time.now,
      :network_type => "gsm",
      :server_address => "898411",
      :originator_address => "15147778181",
      :carrier => "verizon"
    )
    inbound_txt.reload
    assert_equal("PIZZA 90210", inbound_txt.message, "message")
    assert_equal("PIZZA", inbound_txt.keyword, "keyword")
    assert_equal("90210", inbound_txt.subkeyword, "subkeyword")

    assert_txts_to(0, "15147778181")
    assert_nil(MobilePhone.find_by_number("15147778181"), "Should not create mobile phone record")
  end
  
  def test_reply_to_configured_keyword_without_intro_txt
    advertisers(:changos).txt_offers.create!(
      :short_code => "898411",
      :keyword => "sdhtaco",
      :message => "Buy one taco, get another free"
    )
    mobile_number = "16266745901"
    inbound_txt = InboundTxt.create_from_gateway!(
      "Message"           => "Sdhtaco plz",
      "AcceptedTime"      => "27Nov,08 12:34:56",
      "NetworkType"       => "gsm",
      "ServerAddress"     => "898411",
      "OriginatorAddress" => mobile_number,
      "Carrier"           => "t-mobile"
    )
    assert_equal "Sdhtaco", inbound_txt.keyword
    assert_equal "898411", inbound_txt.server_address
    assert_equal DateTime.parse("27 Nov 2008 20:34:56Z").to_time, inbound_txt.accepted_time
    
    expected_response = "MySDH.com: Buy one taco, get another free. Std msg chrgs apply. T&Cs at txt411.com"
    assert_txts_to 1, mobile_number
    assert_last_txt_message_to expected_response, mobile_number
  end
  
  def test_reply_to_configured_keyword_with_intro_txt
    advertiser = advertisers(:changos)
    advertiser.publisher.update_attributes! :send_intro_txt => true
    
    advertiser.txt_offers.create!(
      :short_code => "898411",
      :keyword => "sdhtaco",
      :message => "Buy one taco, get another free"
    )
    mobile_number = "16266745901"
    inbound_txt = InboundTxt.create_from_gateway!(
      "Message"           => "Sdhtaco plz",
      "AcceptedTime"      => "27Nov,08 12:34:56",
      "NetworkType"       => "gsm",
      "ServerAddress"     => "898411",
      "OriginatorAddress" => mobile_number,
      "Carrier"           => "t-mobile"
    )
    assert_equal "Sdhtaco", inbound_txt.keyword
    assert_equal "898411", inbound_txt.server_address
    assert_equal DateTime.parse("27 Nov 2008 20:34:56Z").to_time, inbound_txt.accepted_time
    
    assert_txts_to 2, mobile_number
    assert_txt_message_to 0, mobile_number, /\AMySDH.com: Coupons to your mobile.*Std msg chrgs apply. T&Cs at txt411.com\z/
    assert_txt_message_to 1, mobile_number, "MySDH.com: Buy one taco, get another free. Std msg chrgs apply"
  end
  
  def test_no_reply_to_deleted_keyword
    advertisers(:changos).txt_offers.create!(
      :short_code => "898411",
      :keyword => "sdhtaco",
      :message => "Buy one taco, get another free",
      :deleted => true
    )
    mobile_number = "16266745901"
    inbound_txt = InboundTxt.create_from_gateway!(
      "Message"           => "Sdhtaco plz",
      "AcceptedTime"      => "27Nov,08 12:34:56",
      "NetworkType"       => "gsm",
      "ServerAddress"     => "898411",
      "OriginatorAddress" => mobile_number,
      "Carrier"           => "t-mobile"
    )
    assert_equal "Sdhtaco", inbound_txt.keyword
    assert_equal "898411", inbound_txt.server_address
    assert_equal DateTime.parse("27 Nov 2008 20:34:56Z").to_time, inbound_txt.accepted_time
    
    assert_txts_to 0, mobile_number
    assert_nil MobilePhone.find_by_number(mobile_number), "Should not create mobile phone record"
  end
  
  private
  
  def assert_txts_to(count, mobile_number)
    assert_equal(count, Txt.count(:conditions => { :mobile_number => mobile_number }), "Txt count for #{mobile_number}")
  end
  
  def assert_txt_message_to(index, mobile_number, message)
    txt = Txt.all(:conditions => { :mobile_number => mobile_number }, :order => "id asc")[index]
    assert_not_nil(txt, "No TXT at index #{index} for #{mobile_number}")
    case
    when message.kind_of?(Regexp)
      assert_match message, txt.message, "Txt message #{index} to #{mobile_number}"
    when message.kind_of?(String)
      assert_equal message, txt.message, "Txt message #{index} to #{mobile_number}"
    else
      assert_nil "message must be a regexp or string"
    end
  end

  def assert_last_txt_message_to(message, mobile_number)
    assert_txt_message_to(-1, mobile_number, message)
  end
end
