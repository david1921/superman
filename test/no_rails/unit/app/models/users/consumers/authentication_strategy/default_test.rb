require File.dirname(__FILE__) + "/../../../../models_helper"

class DefaultTest < Test::Unit::TestCase

  context "#authenticate" do
    setup do
      @strategy = Consumers::AuthenticationStrategy::Default.new
      @consumer = mock("consumer")
    end
    should "delegate to user's restful auth" do
      @consumer.expects(:authenticated?).with("mypassword").returns(true)
      @consumer.expects(:successful_login!)
      assert @strategy.authenticate(@consumer, "mypassword")
    end
    should "return result of result auth" do
      @consumer.expects(:authenticated?).with("mypassword").returns(false)
      @consumer.expects(:failed_login!)
      @consumer.expects(:access_locked?).returns(false)
      assert !@strategy.authenticate(@consumer, "mypassword")
    end
  end

end
