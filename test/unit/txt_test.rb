require File.dirname(__FILE__) + "/../test_helper"

class TxtTest < ActiveSupport::TestCase
  def test_create
    Txt.create!
  end

  def test_lead
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :call_me => true
    )
    txt = Txt.create!(:mobile_number => "19187651010", :message => "go", :source => lead)

    # Test used to used txt.source(true), but polymorphic association force-reloading is busted in Rails 2.3.14
    txt = Txt.find(txt.id)
    assert_equal(lead, txt.source, "Should associate coupon request")
  end

  def test_should_call_back_to_lead_after_sent
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true,
      :call_me => true
    )
    assert_not_nil(txt = Txt.find_by_mobile_number_and_source_type_and_source_id("16051629100", 'Lead', lead.id))

    # Need to add class expectation, as Txt will probably load a different instance
    Lead.any_instance.expects(:after_sent).once

    txt.status = "sent"
    txt.sent_at = Time.now
    txt.save!
  end

  def test_no_call_back_without_lead
    txt = Txt.create!(:mobile_number => "19187651010", :message => "OK")

    # Need to add class expectation, as Txt will probably load a different instance
    Lead.any_instance.expects(:after_sent).never

    txt.status = "sent"
    txt.sent_at = Time.now
    txt.save!
  end

  def test_no_call_back_on_error
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true,
      :call_me => true
    )
    txt = Txt.find_by_mobile_number("16051629100")
    assert_not_nil(txt, "Should create new outbound Txt after creation")

    # Need to add class expectation, as Txt will probably load a different instance
    Lead.any_instance.expects(:after_sent).never

    txt.status = "error"
    txt.gateway_response_code = 9
    txt.gateway_response_message = "Could not connect"
    txt.save!
  end

  def test_no_call_back_on_enqueued
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true,
      :call_me => true
    )
    txt = Txt.find_by_mobile_number("16051629100")
    assert_not_nil(txt, "Should create new outbound Txt after creation")

    # Need to add class expectation, as Txt will probably load a different instance
    Lead.any_instance.expects(:after_sent).never

    txt.status = "enqueued"
    txt.save!
  end

  def test_update_from_gateway
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :call_me => true
    )
    txt = Txt.create!(:mobile_number => "19187651010", :message => "go", :source => lead)

    body = %Q{
      <TxTNotifyResponse>
          <MsgResponseList>
              <MsgResponse type="SMS">
                 <Status>ACCEPTED</Status>
                 <MessageId>1984</MessageId>
              </MsgResponse>
          </MsgResponseList>
      </TxTNotifyResponse>
    }

    txt.update_from_gateway(body)
    assert_nil(txt.gateway_response_code, "TXT error_code")
    assert_equal(txt.gateway_response_message, "ACCEPTED", "TXT error_message")
    assert_equal("sent", txt.status, "status after accepted")
    assert_equal(1984, txt.gateway_response_id, "gateway_response_id")
  end

  # We connected fine, but CellTrust dislikes what we sent
  def test_update_from_gateway_invalid_txt
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :call_me => true
    )
    txt = Txt.new(:mobile_number => "8", :message => "go", :source => lead)
    txt.save_with_validation(false)

    body = %Q{
      <TxTNotifyResponse>
          <Error>
              <ErrorCode>201</ErrorCode>
              <ErrorMessage>Expected Message, PhoneDestination, AdminEmail, and XMLResponse</ErrorMessage>
          </Error>
      </TxTNotifyResponse>
    }

    txt.update_from_gateway(body)
    assert_equal(201, txt.gateway_response_code, "TXT error_code")
    assert_equal("Expected Message, PhoneDestination, AdminEmail, and XMLResponse", txt.gateway_response_message, "TXT error_message")
    assert_nil(txt.sent_at, "TXT sent_at")
    assert_equal("error", txt.status, "status after invalid data")

    txt = Txt.new
    txt.update_from_gateway(%Q{
      <TxTNotifyResponse>
          <Error>
              <ErrorCode>911</ErrorCode>
              <ErrorMessage>Expected Message, PhoneDestination, AdminEmail, and XMLResponse</ErrorMessage>
          </Error>
      </TxTNotifyResponse>
    })
    assert_equal(911, txt.gateway_response_code, "error code")
    assert_equal("Expected Message, PhoneDestination, AdminEmail, and XMLResponse", txt.gateway_response_message, "TXT error_message")

    txt = Txt.new
    txt.update_from_gateway(%Q{
      <TxTNotifyResponse>
          <Error>
              <ErrorCode>911</ErrorCode>
              <ErrorMessage>Expected PhoneDestination</ErrorMessage>
          </Error>
      </TxTNotifyResponse>
    })
    assert_equal(911, txt.gateway_response_code, "error code")
    assert_equal("Expected PhoneDestination", txt.gateway_response_message, "error message")
  end

  # We still want to mark this as an error, even if we can't figure out what CellTrust gateway is telling us
  def test_update_from_gateway_with_unparseable_error
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :call_me => true
    )

    txt = Txt.new(:mobile_number => "8", :message => "go", :source => lead)
    txt.save_with_validation(false)

    body = "Error with no XML"

    txt.update_from_gateway(body)
    assert_nil(txt.gateway_response_code, "TXT error_code")
    assert_not_nil(txt.gateway_response_message, "TXT error_message")
    assert_equal("error", txt.status, "status after unparseable response")
  end

  def test_create_from_gateway
    inbound_txt = InboundTxt.create_from_gateway!("Message" => "WILDGMC START",
                                                 "AcceptedTime" => "27Jun,10 04:11:59",
                                                 "NetworkType" => "gsm",
                                                 "ServerAddress" => "898411",
                                                  "OriginatorAddress" => "13154367819",
                                                  "Carrier" => "tmobile"
    )
    assert_equal("WILDGMC START", inbound_txt.message, "message")
    assert_equal("WILDGMC", inbound_txt.keyword, "keyword")
    assert_equal("START", inbound_txt.subkeyword, "subkeyword")
    assert_equal(Time.utc(2010, 6, 27, 12, 11, 59), inbound_txt.accepted_time, "new txt accepted_time")
    assert_equal("gsm", inbound_txt.network_type, "network_type")
    assert_equal("898411", inbound_txt.server_address, "server_address")
    assert_equal("13154367819", inbound_txt.originator_address, "originator_address")
    assert_equal("tmobile", inbound_txt.carrier, "carrier")
  end

  def test_accepted_time_parsing
    inbound_txt = InboundTxt.create_from_gateway!("Message" => "WILDGMC START",
                                           "AcceptedTime" => "22Aug,08 12:05:04",
                                           "NetworkType" => "gsm",
                                           "ServerAddress" => "898411",
                                           "OriginatorAddress" => "13154367819",
                                           "Carrier" => "tmobile"
    )
    assert_equal(Time.utc(2008, 8, 22, 20, 5, 4), inbound_txt.accepted_time, "new txt accepted_time")
  end

  def test_gateway_uri
    # Defaults from AppConfig in config/environment.rb
    assert_equal("http://0.0.0.0:3000/txt_gateway_messages", Txt.new.gateway_uri, "gateway_uri")
  end

  def test_http_method
    assert_equal(:post, Txt.new.http_method, "http_method")
  end

  def test_to_gateway_format
    txt = Txt.new(:message => "Here is your coupon", :mobile_number => "14152214774")
    hash = txt.to_gateway_format
    assert_equal("Here is your coupon", hash["Message"], "Message")
    assert_equal("TOMCTA", hash["CustomerNickname"], "CustomerNickname")
    assert_equal("898411", hash["Shortcode"], "Shortcode")
    assert_equal("true", hash["XMLResponse"], "XMLResponse")
    assert_equal("14152214774", hash["PhoneDestination"], "mobile_number/PhoneDestination")
  end
end
