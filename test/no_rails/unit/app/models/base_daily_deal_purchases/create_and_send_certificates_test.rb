require File.dirname(__FILE__) + "/../../models_helper"

class BaseDailyDealPurchases::CreateAndSendCertificatesTest < Test::Unit::TestCase
  
  def setup
    @purchase = Object.new.extend(BaseDailyDealPurchases::CreateAndSendCertificates)
  end
  
  context "daily deal purchase" do
    should "create certificates and send email" do
      @purchase.expects(:create_certificates!)
      @purchase.expects(:should_send_email?).returns(true)
      @purchase.expects(:enqueue_email)
      @purchase.expects(:post_to_facebook?).returns(false)
      @purchase.create_certificates_and_send_email!
    end
  end
  
  context "off platform daily deal purchase" do
    should "create certificates but not send email" do
      @purchase.expects(:create_certificates!)
      @purchase.expects(:should_send_email?).returns(false)
      @purchase.expects(:enqueue_email).never
      @purchase.expects(:post_to_facebook?).returns(false)
      @purchase.create_certificates_and_send_email!
    end
  end

  context "#should_send_certificates?" do
    should "return true when is not a off-platform purchase" do
      @purchase.expects(:is_off_platform_purchase?).returns(false)
      assert @purchase.should_send_email?
    end

    should "return false for off platform purchases" do
      @purchase.expects(:is_off_platform_purchase?).returns(true)
      assert !@purchase.should_send_email?
    end

  end
end