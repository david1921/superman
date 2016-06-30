require File.dirname(__FILE__) + "/../test_helper"

class VoiceMessagesControllerTest < ActionController::TestCase
  def test_update_one_call_detail_record_sid
    #
    # Test 1: update VoiceMessage before CallDetailRecord created.
    #
    voice_message = leads(:my_space_burger_king).voice_messages.create!(
      :mobile_number => '8104531100'
    )
    voice_message.save!
    assert_nil(voice_message.call_detail_record, "Should not have a call_detail_record yet")

    post(:update_one_call_detail_record_sid, :id => voice_message.id, :call_detail_record_sid => '0809155901490409')

    assert_response(:success)
    voice_message.reload
    assert_nil(voice_message.call_detail_record, "Should not have a call_detail_record yet")

    cdr = CallDetailRecord.create!(
      :sid => '0809155901490409',
      :date_time => '2008-09-16 12:14:56',
      :viewer_phone_number => '8104531100'
    )
    assert_equal cdr, voice_message.call_detail_record(true), "Should have a call_detail_record"
    assert_equal(voice_message, cdr.voice_message, "Should have a voice_message")
    #
    # Test 2: create CallDetailRecord before updating VoiceMessage.
    #
    voice_message = leads(:my_space_burger_king).voice_messages.create!(
      :mobile_number => '8104531101'
    )
    voice_message.save!
    assert_nil(voice_message.call_detail_record, "Should not have a call_detail_record yet")

    cdr = CallDetailRecord.create!(
      :sid => '0809155901490410',
      :date_time => '2008-09-16 12:14:56',
      :viewer_phone_number => '8104531101'
    )
    assert_nil(cdr.voice_message, "Should not have a voice_message yet")

    post(:update_one_call_detail_record_sid, :id => voice_message.id, :call_detail_record_sid => '0809155901490410')

    assert_response(:success)
    voice_message.reload
    cdr.reload

    assert_equal(cdr, voice_message.call_detail_record, "Should have a call_detail_record")
    assert_equal(voice_message, cdr.voice_message, "Should have a voice_message")
  end
end
