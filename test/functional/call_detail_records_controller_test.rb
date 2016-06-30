require File.dirname(__FILE__) + "/../test_helper"

class CallDetailRecordsControllerTest < ActionController::TestCase
  def test_create
    assert_raise(ActiveRecord::RecordNotFound) {CallDetailRecord.find('0809155901490409')}

    params = {
      :sid => '0809155901490409',
      :date_time => '2008-09-16 12:14:56',
      :viewer_phone_number => '8104531100',
      :center_phone_number => 'Transfer | 6266745901',
      :intelligent_minutes => 0.6,
      :talk_minutes => 5.3,
      :enhanced_minutes => 0.0
    }
    post(:create, params)

    assert_response(:success)

    call_detail_record = CallDetailRecord.find_by_sid("0809155901490409")
    assert_not_nil(call_detail_record)
    assert_nil(call_detail_record.voice_message, "Should not have a VoiceMessage")
  end
end
