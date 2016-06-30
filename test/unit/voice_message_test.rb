require File.dirname(__FILE__) + "/../test_helper"

class VoiceMessageTest < ActiveSupport::TestCase
  def test_create
    voice_message = VoiceMessage.create!(:mobile_number => "13124567878", :lead => leads(:my_space_burger_king), :voice_response_code => 8771)
  end
  
  def test_set_voice_response_code
    assert(VoiceMessage.new(:mobile_number => "13124567878", :lead => leads(:my_space_burger_king)).valid?, "Should set voice_response_code from offer")
  end

  def test_gateway_uri
    # Defaults from AppConfig in config/environment.rb
    assert_equal("http://0.0.0.0:3000/voice_gateway_messages", VoiceMessage.new.gateway_uri, "gateway_uri")
  end

  def test_to_gateway_format
    voice_message = VoiceMessage.new(:voice_response_code => 901, :mobile_number => "12129132961")
  end
  
  def test_http_method
    assert_equal(:post, VoiceMessage.new.http_method, "http_method")
  end

  def test_to_gateway_format
    voice_message = VoiceMessage.new(:voice_response_code => 901, :mobile_number => "12129132961")
    params = voice_message.to_gateway_format
    assert_equal("CTS", params["app"], "app")
    assert_equal("e319fcab70ecdd48749bc97eb2d3abc6390ca675", params["key"], "key")
    assert_equal(901, params["survo_id"], "voice_response_code/survo_id")
    assert_equal("2129132961", params["phone_to_call"], "mobile_number/phone_to_call")
  end
  
  def test_update_from_gateway
    voice_message = VoiceMessage.new
    voice_message.update_from_gateway("connected")
    assert_equal("sent", voice_message.status, "status")
  end
  
  def test_update_from_gateway_eror
    voice_message = VoiceMessage.new
    voice_message.update_from_gateway("error")
    assert_equal("retry", voice_message.status, "status")
  end
  
  def test_create_with_center_phone_number
    advertisers(:burger_king).update_attributes! :call_phone_number => "212-555-1212"
    voice_message = VoiceMessage.create!(
      :mobile_number => "13124567878",
      :lead => leads(:my_space_burger_king),
      :voice_response_code => 8771
    )
    assert_equal "12125551212", voice_message.center_phone_number
  end
  
  def test_to_gateway_format_with_center_phone_number
    advertiser = advertisers(:burger_king)
    advertiser.update_attributes! :call_phone_number => "212-555-1212"
    voice_message = VoiceMessage.create!(
      :mobile_number => "13124567878",
      :lead => leads(:my_space_burger_king),
      :voice_response_code => 8771
    )
    params = voice_message.to_gateway_format
    assert_equal "CTS", params["app"], "params[app]"
    assert_equal "e319fcab70ecdd48749bc97eb2d3abc6390ca675", params["key"], "params[key]"
    assert_equal 8771, params["survo_id"], "params[survo_id]"
    assert_equal "3124567878", params["phone_to_call"], "params[phone_to_call]"
    assert_equal "2125551212", params["first_callerid"], "params[first_callerid]"
    assert_equal "center_phone_number|2125551212", params["user_parameters"], "params[user_parameters]"
  end
end
