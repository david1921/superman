require File.dirname(__FILE__) + "/../../test_helper"
require File.dirname(__FILE__) + '/../../mocks/test/curl/mock_multi'

# Sender finds next message by a simple round-robin. Need to call enqueue_some enough time to cycle through message types.
# hydra class Messaging::SenderTest
module Messaging
  class SenderTest < ActiveSupport::TestCase
    def setup
      @sender = Sender.new
      @sender.curl_multi = Curl::MockMulti.new
    end

    def test_exception_notification
      e = Exception.new
      e.set_backtrace(["10 print 'I am awesome at BASIC'", "20 goto 10"])
      Exceptional::Catcher.expects(:handle)
      @sender.handle_exception(e)
      # We're just looking for no errors
    end

    test "exit 0 on SystemExit and log only to logger" do
      # times is called on MESSAGE_CLASSES so we use it to fake an error
      Fixnum.any_instance.expects(:times).raises(SystemExit)
      Logger.any_instance.expects(:error)
      assert_raise SystemExit do
        @sender.run
      end
    end

    def test_enqueue_some_voice_messages
      voice_message = leads(:my_space_burger_king).voice_messages.create!(:mobile_number => "(605) 162-9100")
      assert_equal("created", voice_message.status, "Voice message status")

      4.times { assert_nil @sender.enqueue_some, "Added less than MAX_WINDOW should return nil" }

      voice_message.reload
      assert_equal("enqueued", voice_message.status, "Voice message status")
    end

    def test_enqueue_some_no_requests
      assert_nil(@sender.enqueue_some, "Nothing added should return nil")
    end

    # Order-dependent on Sender.MESSAGE_CLASSES, so enqueue at least one of each Message type
    def test_enqueue_some
      txt = Txt.create!(
        :message => "STOP", :mobile_number => "(605) 162-9100"
      )
      assert_equal("created", txt.status, "TXT status")

      voice_message = leads(:my_space_burger_king).voice_messages.create!(:mobile_number => "(605) 162-9100")
      assert_equal("created", voice_message.status, "Voice message status")
      assert_nil(@sender.enqueue_some, "Added less than MAX_WINDOW should return nil")

      txt.reload
      assert_equal("enqueued", txt.status, "TXT status")

      voice_message.reload
      assert_equal("enqueued", voice_message.status, "Voice message status")
    end

    def test_enqueue_some_more_than_max_window
      Timecop.freeze do
        Txt.create!(:message => "STOP", :mobile_number => "(605) 162-9100" )
        Txt.create!(:message => "STOP", :mobile_number => "(605) 162-9101")

        offer = offers(:my_space_burger_king_free_fries)
        4.times do |index|
          lead = offer.leads.create!(
            :publisher => offer.publisher,
            :name => "My Name",
            :email => "me@gmail.com",
            :mobile_number => "(605) 162-910#{index}",
            :txt_me => true
          )
          lead.voice_messages.create!(:mobile_number => "(605) 162-910#{index}", :send_at => (Time.now - 1200))
        end

        assert_equal(0, Txt.count(:conditions => { :status => "enqueued" }), "Txts enqueued")
        assert_equal(0, VoiceMessage.count(:conditions => { :status => "enqueued" }), "VoiceMessages enqueued")

        assert_equal(4, @sender.enqueue_some, "Added more than MAX_WINDOW")

        total_enqueued = Txt.count(:conditions => { :status => "enqueued" }) +
          VoiceMessage.count(:conditions => { :status => "enqueued" })
        assert_equal(4, total_enqueued, "Messages enqueued")
      end
    end

    def test_send_after_send_at
      Timecop.freeze do
        voice_message = leads(:my_space_burger_king).voice_messages.create!(:mobile_number => "(605) 162-9100", :send_at => (Time.now - 1200))
        assert_equal("created", voice_message.status, "Voice message status")

        assert_nil(@sender.enqueue_some, "Added less than MAX_WINDOW should return nil")
        assert_nil(@sender.enqueue_some, "Added less than MAX_WINDOW should return nil")
        assert_nil(@sender.enqueue_some, "Added less than MAX_WINDOW should return nil")

        voice_message.reload
        assert_equal("enqueued", voice_message.status, "Voice message status")
      end
    end

    def test_do_not_send_before_send_at
      Timecop.freeze do
        voice_message = leads(:my_space_burger_king).voice_messages.create!(:mobile_number => "(605) 162-9100", :send_at => (Time.now + 1200))
        assert_equal("created", voice_message.status, "Voice message status")

        assert_nil(@sender.enqueue_some, "Added less than MAX_WINDOW should return nil")
        voice_message.reload
        assert_equal("created", voice_message.status, "Voice message status")
      end
    end
  end
end
