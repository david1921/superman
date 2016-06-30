require File.dirname(__FILE__) + "/../test_helper"

class CallDetailRecordTest < ActiveSupport::TestCase
  def test_create
    cdr = CallDetailRecord.create!(
      :sid => '0809155901490409',
      :date_time => '2008-09-16 12:14:56',
      :viewer_phone_number => '8104531100',
      :center_phone_number => 'Transfer | 6266745901',
      :intelligent_minutes => 0.6,
      :talk_minutes => 5.3,
      :enhanced_minutes => 0.0
    )
    assert "0809155901490409" != cdr.id, "sid is not primary key"
    assert_equal "0809155901490409", cdr.sid, "sid"
    assert_equal(Time.utc(2008, 9, 16, 16, 14, 56), cdr.date_time, "date_time normalized")
    assert_equal('18104531100', cdr.viewer_phone_number, "viewer_phone_number normalized")
    assert_equal('16266745901', cdr.center_phone_number, "center_phone_number normalized")
    assert_equal(0.6, cdr.intelligent_minutes, "intelligent_minutes")
    assert_equal(5.3, cdr.talk_minutes, "talk_minutes")
    assert_equal(0.0, cdr.enhanced_minutes, "enhanced_minutes")
  end

  def test_create_with_blank_center_phone_number
    cdr = CallDetailRecord.create!(
      :sid => '0809155901490409',
      :date_time => '2008-09-16 12:14:56',
      :viewer_phone_number => '8104531100'
    )
    assert "0809155901490409" != cdr.id, "sid is not primary key"
    assert_equal "0809155901490409", cdr.sid, "sid"
    assert_equal(Time.utc(2008, 9, 16, 16, 14, 56), cdr.date_time, "date_time normalized")
    assert_equal('18104531100', cdr.viewer_phone_number, "viewer_phone_number normalized")
    assert_nil(cdr.center_phone_number, "center_phone_number NULL")
    assert_nil(cdr.intelligent_minutes, "intelligent_minutes NULL")
    assert_nil(cdr.talk_minutes, "talk_minutes NULL")
    assert_nil(cdr.enhanced_minutes, "enhanced_minutes NULL")

    cdr = CallDetailRecord.create!(
      :sid => '0809155901490410',
      :date_time => '2008-09-16 12:14:56',
      :viewer_phone_number => '8104531100',
      :center_phone_number => ''
    )
    assert "0809155901490410" != cdr.id, "sid is not primary key"
    assert_equal "0809155901490410", cdr.sid, "sid"
    assert_equal(Time.utc(2008, 9, 16, 16, 14, 56), cdr.date_time, "date_time normalized")
    assert_equal('18104531100', cdr.viewer_phone_number, "viewer_phone_number normalized")
    assert_equal('', cdr.center_phone_number, "center_phone_number empty")
    assert_nil(cdr.intelligent_minutes, "intelligent_minutes NULL")
    assert_nil(cdr.talk_minutes, "talk_minutes NULL")
    assert_nil(cdr.enhanced_minutes, "enhanced_minutes NULL")
  end

  def test_dst_handling_in_create
    #
    # Eastern time is EST on this date.
    #
    cdr = CallDetailRecord.create!(
      :sid => '0809155901490409',
      :date_time => '2008-02-15 12:34:56',
      :viewer_phone_number => '8104531100'
    )
    assert "0809155901490409" != cdr.id, "sid is not primary key"
    assert_equal "0809155901490409", cdr.sid, "sid"
    assert_equal(Time.utc(2008, 2, 15, 17, 34, 56), cdr.date_time, "date_time normalized")
    assert_equal('18104531100', cdr.viewer_phone_number, "viewer_phone_number normalized")
    assert_nil(cdr.center_phone_number, "center_phone_number NULL")
    assert_nil(cdr.intelligent_minutes, "intelligent_minutes NULL")
    assert_nil(cdr.talk_minutes, "talk_minutes NULL")
    assert_nil(cdr.enhanced_minutes, "enhanced_minutes NULL")
    #
    # Eastern time is EDT on this date.
    #
    cdr = CallDetailRecord.create!(
      :sid => '0809155901490410',
      :date_time => '2008-08-15 12:34:56',
      :viewer_phone_number => '8104531100'
    )
    assert "0809155901490410" != cdr.id, "sid is not primary key"
    assert_equal "0809155901490410", cdr.sid, "sid"
    assert_equal(Time.utc(2008, 8, 15, 16, 34, 56), cdr.date_time, "date_time normalized")
    assert_equal('18104531100', cdr.viewer_phone_number, "viewer_phone_number normalized")
    assert_nil(cdr.center_phone_number, "center_phone_number NULL")
    assert_nil(cdr.intelligent_minutes, "intelligent_minutes NULL")
    assert_nil(cdr.talk_minutes, "talk_minutes NULL")
    assert_nil(cdr.enhanced_minutes, "enhanced_minutes NULL")
  end

  def test_voice_message_association
    cdr = CallDetailRecord.create!(
      :sid => '0809155901490411',
      :date_time => '2008-09-16 12:14:56',
      :viewer_phone_number => '8104531100',
      :center_phone_number => 'Transfer | 6266745901',
      :intelligent_minutes => 0.3,
      :talk_minutes => 4.2,
      :enhanced_minutes => 1.0
    )
    voice_message = leads(:my_space_burger_king).voice_messages.create!(
      :mobile_number => '8104531100',
      :call_detail_record_sid => '0809155901490411'
    )
    cdr.reload

    assert "0809155901490411" != cdr.id, "sid is not primary key"
    assert_equal "0809155901490411", cdr.sid, "sid"
    assert "0809155901490411" != cdr.voice_message_id, "sid is not foreign key"
    assert_equal voice_message.id, cdr.voice_message_id, "voice_message_id is foreign key"

    assert_equal('0809155901490411', voice_message.call_detail_record_sid, "voice_message call_detail_record_sid")
    assert_equal(voice_message, cdr.voice_message, "call_detail_record has_one voice_message")
    assert_equal(cdr, voice_message.call_detail_record, "voice_message belongs_to call_detail_record")
  end
end
