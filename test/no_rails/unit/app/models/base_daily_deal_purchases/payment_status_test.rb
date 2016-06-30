require File.dirname(__FILE__) + "/../../models_helper"

class BaseDailyDealPurchases::PaymentStatusTest < Test::Unit::TestCase
  def setup
    @obj = Object.new.extend(BaseDailyDealPurchases::PaymentStatus)
  end

  context "#after_captured" do
    setup do
      @obj.stubs(:consumer_daily_deal_purchase_captured!)
      #@obj.stubs(:logger).returns(mock("logger"))
      #@obj.stubs(:uuid).returns("some uuid")
      @obj.stubs(:daily_deal_certificates).returns([])
      @obj.stubs(:create_certificates_and_send_email!)
      @certs = [mock('daily_deal_certificate')]
      @certs.each{|c| c.stubs(:activate!)}
    end

    should "create a promotion discount if responds to method" do
      @obj.expects(:create_promotion_discount)
      @obj.send(:after_captured)
    end

    should "create and send certificates" do
      @obj.expects(:create_certificates_and_send_email!)
      @obj.send(:after_captured)
    end

    should "activate the certificates" do
      @obj.stubs(:daily_deal_certificates).returns(@certs)
      @certs.each{|c| c.expects(:activate!)}
      @obj.send(:after_captured)
    end

    should "tell the consumer model that a purchase was captured" do
      @obj.expects(:consumer_daily_deal_purchase_captured!)
      @obj.send(:after_captured)
    end

    should "log exception" do
      @obj.stubs(:uuid).returns("12345")
      mock_logger = mock("logger")
      mock_logger.expects(:error).with(regexp_matches(/after_captured failed.*#{12345}/))
      @obj.expects(:consumer_daily_deal_purchase_captured!).raises(Exception)
      @obj.stubs(:logger).returns(mock_logger)
      assert_raise Exception do
        @obj.send(:after_captured)
      end
    end
  end
end
