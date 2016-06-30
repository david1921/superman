require File.dirname(__FILE__) + "/../test_helper"

class InboundTxtsControllerTest < ActionController::TestCase
  def test_create
    count = InboundTxt.count
    
    post(:create, "Message" => "ITUNES HELP",
                  "AcceptedTime" => "22May,08 14:18:35",
                  "NetworkType" => "gsm",
                  "ServerAddress" => "32075",
                  "OriginatorAddress" => "15147778181",
                  "Carrier" => "att")
    
    assert_response(:success)
    
    assert_equal(count + 1, InboundTxt.count, "Should be one more txt in database")
    new_txt = InboundTxt.find_by_originator_address("15147778181")
    assert_not_nil(new_txt, "Should be new txt with originator address 15147778181")
    assert_equal("ITUNES HELP", new_txt.message, "new txt message")
    assert_equal("ITUNES", new_txt.keyword, "new txt keyword")
    assert_equal("HELP", new_txt.subkeyword, "new txt subkeyword")
    assert_equal("32075", new_txt.server_address, "new txt server address")
    assert_equal("gsm", new_txt.network_type, "new txt network type")
    assert_equal("att", new_txt.carrier, "new txt carrier")
    assert_equal(Time.utc(2008, 5, 22, 22, 18, 35), new_txt.accepted_time, "new txt accepted_time")
  end

  def test_incomplete_help_msg
    count = InboundTxt.count
    
    post(:create,
      "Message"=>"HELP",
      "CustomerNickname"=>"",
      "OriginatorAddress"=>"12707343435",
      "Option"=>"",
      "Data"=>"HELP",
      "DeliveryType"=>"SMS",
      "ServerAddress"=>"898411",
      "ResponseType"=>"NORMAL",
      "Keyword"=>"",
      "AcceptedTime"=>"22May,09 09:01:32"
    )
    
    assert_response(:success)
    
    assert_equal(count + 1, InboundTxt.count, "Should be one more txt in database")
    new_txt = InboundTxt.find_by_originator_address("12707343435")
    assert_not_nil(new_txt, "Should be new txt with originator address 15147778181")
    assert_equal("HELP", new_txt.message, "new txt message")
    assert_equal("HELP", new_txt.keyword, "new txt keyword")
    assert_equal("", new_txt.subkeyword, "new txt subkeyword")
    assert_equal("898411", new_txt.server_address, "new txt server address")
    assert_equal(nil, new_txt.network_type, "new txt network type")
    assert_equal(nil, new_txt.carrier, "new txt carrier")
    assert_equal(Time.utc(2009, 5, 22, 17, 1, 32), new_txt.accepted_time, "new txt accepted_time")
  end
  
  test "create for daily deal certificate validation" do
    ddp = Factory(:captured_daily_deal_purchase)
    ddc = ddp.daily_deal_certificates.create!(:redeemer_name => ddp.consumer.name)
    InboundTxt.destroy_all
    
    assert_difference 'Txt.count' do
      post(:create,
        "Message" => "BBD V #{ddc.serial_number.gsub(/\D/, '')}",
        "CustomerNickname" => "TOMCTA",
        "OriginatorAddress" => "12707343435",
        "DeliveryType" => "SMS",
        "ServerAddress" => "898411",
        "ResponseType" => "NORMAL",
        "Keyword" => "BBD",
        "AcceptedTime" => "30Aug,10 12:34:56",
        "NetworkType" => "gsm",
        "ServerAddress" => "898411",
        "Carrier" => "t-mobile"
      )
    end
    assert_equal 1, InboundTxt.count
    inbound_txt = InboundTxt.first
    assert_equal "BBD", inbound_txt.keyword
    assert_equal "V", inbound_txt.subkeyword
    assert_equal Time.utc(2010, 8, 30, 20, 34, 56), inbound_txt.accepted_time
  
    txt = Txt.last
    assert_equal "created", txt.status
    assert_equal inbound_txt, txt.source
    assert_equal "12707343435", txt.mobile_number
    assert_equal "TXT411: Voucher #{ddc.serial_number} is VALID for $30.00. Std msg chrgs apply. T&Cs at txt411.com", txt.message
  end
end
