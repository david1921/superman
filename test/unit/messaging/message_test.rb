require File.dirname(__FILE__) + "/../../test_helper"

class MessageTest < ActiveSupport::TestCase
  def setup
    Txt.delete_all
  end
  def test_find_first_message_to_send
    txt = Txt.create!
    assert_equal(txt, Txt.find_first_message_to_send, "find_first_message_to_send")
  end
  
  def test_find_first_message_to_send_should_honor_status
    Txt.create!(:status => "error")
    Txt.create!(:status => "enqueued")
    txt = Txt.create!
    Txt.create!(:status => "enqueued")
    assert_equal(txt, Txt.find_first_message_to_send, "find_first_message_to_send")
  end
  
  def test_find_first_message_to_send_should_honor_send_at
    Timecop.freeze do
      Txt.create!(:send_at => Time.now + 3000)
      txt = Txt.create!
      assert_equal(txt, Txt.find_first_message_to_send, "find_first_message_to_send")
    end
  end
  
  def test_find_first_message_to_send_should_resend
    txt = Txt.create!(:status => "retry")
    assert_equal(txt, Txt.find_first_message_to_send, "find_first_message_to_send")
  end

  def test_enqueued
    txt = Txt.create!
    assert_equal("created", txt.status, "Initial status")
    txt.enqueued
    assert_equal("enqueued", txt.status, "Status after enqueued")
  end
  
  def test_send_failed
    txt = Txt.create!
    assert_equal("created", txt.status, "Initial status")
    txt.send_failed
    assert_equal("retry", txt.status, "Status after send_failed")
    assert_not_nil(txt.send_at, "send_at after send_failed")
    assert_nil(txt.sent_at, "sent_at after send_failed")
  end
  
  def test_retry_send_failed
    Timecop.freeze do
      txt = Txt.create!(:status => "enqueued", :retries => 1, :send_at => Time.now + 60)
      txt.send_failed
      txt.reload
      assert_equal("retry", txt.status, "Status after send_failed")
      assert_not_nil(txt.send_at, "send_at after send_failed")
      assert_nil(txt.sent_at, "sent_at after send_failed")
      assert_equal(2, txt.retries, "retries count")
    end
  end
  
  def test_should_not_update_retries_on_success
    txt = Txt.create!
    assert_equal(0, txt.retries, "retries after create")
    
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
    txt.sent(body)
    txt.reload
    assert_equal(0, txt.retries, "retries after successful send")
  end
  
  def test_retry
    txt = Txt.create!(:status => "enqueued", :retries => 1)
    assert_equal(1, txt.retries, "retries after create")
    assert_nil(txt.send_at, "send_at after create")
    
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
    txt.sent(body)
    txt.reload
    assert_nil(txt.send_at, "send_at after create")
    assert_equal(1, txt.retries, "retries after successful send")
    assert_equal("sent", txt.status, "status after successful retry")
  end
  
  def test_retry_twice
    send_at = Time.zone.now
    txt = Txt.create!(:status => "enqueued", :retries => 2, :send_at => send_at)
    assert_equal(2, txt.retries, "retries after create")
    assert_not_nil(txt.send_at, "send_at after create")
    
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
    txt.sent(body)
    txt.reload
    assert_equal(2, txt.retries, "retries after successful send")
    assert_equal_date_times(send_at, txt.send_at, "send_at after successful retry")
    assert_equal("sent", txt.status, "status after successful retry")
  end
  
  def test_retry_three_times
    send_at = Time.zone.now
    txt = Txt.create!(:status => "enqueued", :retries => 3, :send_at => send_at)
    assert_equal(3, txt.retries, "retries after create")
    assert_not_nil(txt.send_at, "send_at after create")
    
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
    txt.sent(body)
    txt.reload
    assert_equal(3, txt.retries, "retries after successful send")
    assert_equal("sent", txt.status, "status after successful retry")
    assert_equal_date_times(send_at, txt.send_at, "send_at after successful retry")
  end

  def test_retry_and_error
    Timecop.freeze do
      voice_message = VoiceMessage.create!(:status => "enqueued", :mobile_number => "13124567878", :lead => leads(:my_space_burger_king), :voice_response_code => 8771)
      assert_equal(0, voice_message.retries, "retries after create")
      assert_nil(voice_message.send_at, "send_at after create")

      voice_message.sent("error")
      voice_message.reload
      assert_not_nil(voice_message.send_at, "send_at on retry")
      assert(voice_message.send_at >= (Time.now + 50), "send_at should be about 1 minute in the future, but was #{voice_message.send_at - Time.now} seconds from now")
      assert(voice_message.send_at <= (Time.now + 70), "send_at should be about 1 minute in the future, but was #{voice_message.send_at - Time.now} seconds from now")
      assert_equal("retry", voice_message.status, "status after failed retry")
      assert_equal(1, voice_message.retries, "retries after failed retry")
    end
  end

  def test_retry_twice_and_error
    Timecop.freeze do
      send_at = Time.now
      voice_message = VoiceMessage.create!(
        :status => "enqueued", :retries => 1, :send_at => send_at,
        :mobile_number => "13124567878", :lead => leads(:my_space_burger_king), :voice_response_code => 8771)
        assert_equal(1, voice_message.retries, "retries after create")
        assert_not_nil(voice_message.send_at, "send_at after create")

        voice_message.sent("error")
        voice_message.reload
        assert_not_nil(voice_message.send_at, "send_at on retry")
        assert(voice_message.send_at >= (Time.now + 110), "send_at should be about 2 minutes in the future, but was #{voice_message.send_at - Time.now} seconds from now")
        assert(voice_message.send_at <= (Time.now + 130), "send_at should be about 2 minutes in the future, but was #{voice_message.send_at - Time.now} seconds from now")
        assert_equal("retry", voice_message.status, "status after failed retry")
        assert_equal(2, voice_message.retries, "retries after failed retry")
    end
  end

  def test_retry_three_times_and_error
    Timecop.freeze do
      send_at = Time.now
      voice_message = VoiceMessage.create!(
        :status => "enqueued", :retries => 2, :send_at => send_at,
        :mobile_number => "13124567878", :lead => leads(:my_space_burger_king), :voice_response_code => 8771)
        assert_equal(2, voice_message.retries, "retries after create")
        assert_not_nil(voice_message.send_at, "send_at after create")

        voice_message.sent("error")
        voice_message.reload
        assert_not_nil(voice_message.send_at, "send_at on retry")
        assert(voice_message.send_at >= (Time.now + 230), "send_at should be about 4 minutes in the future, but was #{voice_message.send_at - Time.now} seconds from now")
        assert(voice_message.send_at <= (Time.now + 250), "send_at should be about 4 minutes in the future, but was #{voice_message.send_at - Time.now} seconds from now")
        assert_equal("retry", voice_message.status, "status after failed retry")
        assert_equal(3, voice_message.retries, "retries after failed retry")
    end
  end

  def test_should_only_retry_three_times
    Timecop.freeze do
      send_at = Time.zone.now
      voice_message = VoiceMessage.create!(
        :status => "enqueued", :retries => 3, :send_at => send_at,
        :mobile_number => "13124567878", :lead => leads(:my_space_burger_king), :voice_response_code => 8771)
        assert_equal(3, voice_message.retries, "retries after create")
        assert_not_nil(voice_message.send_at, "send_at after create")

        voice_message.sent("error")
        voice_message.reload
        assert_equal(3, voice_message.retries, "retries after failed retry")
        assert_not_nil(voice_message.send_at, "send_at on retry")
        assert_equal_date_times(send_at, voice_message.send_at, "send_at after successful retry")
        assert_equal("error", voice_message.status, "status after failed retry")
    end
  end
end
