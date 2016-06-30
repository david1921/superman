require File.dirname(__FILE__) + "/../test_helper"

class NotifyPublisherOfConsumerCreationTest < ActiveSupport::TestCase

  context "publisher notification of consumer creation" do
    setup do
      @consumer = Factory(:consumer, :referral_code => "12345")
    end

    should "enqueue a job" do
      NotifyPublisherOfConsumerCreation.expects(:perform)
      Resque.enqueue(NotifyPublisherOfConsumerCreation, @consumer.id)
    end

    # These are suffering from some obscure issue... expectations not being changed
    # see https://github.com/floehopper/mocha/issues/18
    # and http://mediumexposure.com/getting-rails-233-and-mocha-096-play-nice-testunit-and-shoulda/
    #should "POST to the correct URL with consumer id in the query params" do
    #  response = mock()
    #  response.expects(:code).returns("200")
    #  Net::HTTP.expects(:post_form).with(URI.parse("http://dev.api.tinyinfo.us/user/create/userId:#{@consumer.id},rUserId:#{@consumer.referral_code},token:af1a3e91cc6ccafbeadd81d48ffc2b95"), "").returns(response)
    #  NotifyPublisherOfConsumerCreation.expects(:handle_failed_response).never
    #  Resque.enqueue(NotifyPublisherOfConsumerCreation, @consumer.id)
    #end
    #
    #should "handle failed responses if the POST is not a success" do
    #  response = mock()
    #  response.expects(:code).returns("500")
    #  Net::HTTP.expects(:post_form).with(URI.parse("http://dev.api.tinyinfo.us/user/create/userId:#{@consumer.id},rUserId:#{@consumer.referral_code},token:af1a3e91cc6ccafbeadd81d48ffc2b95"), "").returns(response)
    #  NotifyPublisherOfConsumerCreation.expects(:handle_failed_response).once # Not ideal. Need to figure out how to inspect error queue and verify the exception is thrown.
    #  Resque.enqueue(NotifyPublisherOfConsumerCreation, @consumer.id)
    #end
  end

end
