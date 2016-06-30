require File.dirname(__FILE__) + "/../../controllers_helper"

class ConsumerActionGuardTest < Test::Unit::TestCase

  context "#allow_consumer_action?" do

    should "raise if no publisher_id" do
      controller = mock("controller").extend(DailyDealPurchases::ConsumerActionGuard)
      controller.stubs(:params => {})
      controller.expects(:render_404)
      assert !controller.allow_consumer_action?
    end

    should "raise if publisher_id but no consumer_id" do
      controller = mock("controller").extend(DailyDealPurchases::ConsumerActionGuard)
      controller.stubs(:params => { :publisher_id => 1234 })
      controller.expects(:render_404)
      assert !controller.allow_consumer_action?
    end

    should "redirect to daily deal login if consumer is not logged in" do
      controller = mock("controller").extend(DailyDealPurchases::ConsumerActionGuard)
      controller.stubs(:current_consumer).returns(nil)
      controller.stubs(:admin? => false)
      controller.expects(:redirect_to_daily_deal_login).with("12345").returns(nil)
      params = { :publisher_id => "12345", :consumer_id => "not_nil" }
      controller.stubs(:params => params)
      assert !controller.allow_consumer_action?
    end

    should "log out consumer if not allowed access for this pub" do
      controller = stub("controller").extend(DailyDealPurchases::ConsumerActionGuard)
      current_consumer = stub("current_consumer", :id => 34,
                                                  :publisher_id => 45678,
                                                  :has_admin_privilege? => false)
      controller.stubs(:current_consumer => current_consumer)
      controller.stubs(:admin? => false)
      controller.expects(:store_location)
      controller.expects(:logout_keeping_session!)
      controller.expects(:discard_flash)
      controller.expects(:redirect_to_daily_deal_login).with("12345").returns(nil)
      publisher = stub
      publisher.stubs(:allow_consumer_access?).returns(false)
      controller.stubs(:publisher => publisher)
      params = { :publisher_id => "12345", :consumer_id => "34" }
      controller.stubs(:params => params)
      assert !controller.allow_consumer_action?
    end

    should "logout redirect to signin if consumers don't match" do
      publisher_id = 12345
      consumer_id = 67
      current_consumer = stub("current_consumer", :id => consumer_id + 2,
                                                  :publisher_id => publisher_id,
                                                  :has_admin_privilege? => false)
      controller = stub("controller").extend(DailyDealPurchases::ConsumerActionGuard)
      controller.stubs(:current_consumer).returns(current_consumer)
      controller.expects(:store_location)
      controller.expects(:logout_keeping_session!)
      controller.expects(:discard_flash)
      controller.expects(:redirect_to_daily_deal_login).with("12345").returns(nil)
      controller.stubs(:admin? => false)
      params = { :publisher_id => publisher_id.to_s, :consumer_id => consumer_id.to_s }
      controller.stubs(:params => params)
      assert !controller.allow_consumer_action?
    end

    should "allow normal access" do
      publisher_id = 12345
      consumer_id = 67
      current_consumer = stub("current_consumer", :id => consumer_id,
                                                  :publisher_id => publisher_id,
                                                  :has_admin_privilege? => false)
      controller = stub("controller").extend(DailyDealPurchases::ConsumerActionGuard)
      controller.stubs(:current_consumer).returns(current_consumer)
      controller.stubs(:admin? => false)
      params = { :publisher_id => publisher_id.to_s, :consumer_id => consumer_id.to_s }
      controller.stubs(:params => params)
      assert controller.allow_consumer_action?
    end

  end

  context "current_consumer_matches_params?" do
    setup do
      @current_consumer = stub("current_consumer", :id => 1920)
      @controller = stub("controller").extend(DailyDealPurchases::ConsumerActionGuard)
      @controller.stubs(:current_consumer).returns(@current_consumer)
      @params = { :publisher_id => "12334", :consumer_id => "1920" }
      @controller.stubs(:params => @params)
    end
    should "match when ids match" do
      assert @controller.current_consumer_matches_params?
    end
    should "not match when they do not match" do
      @params[:consumer_id] = 4531
      assert !@controller.current_consumer_matches_params?
    end
  end

  context "admin access" do
    setup do
      publisher_id = 12345
      consumer_id = 67
      @current_consumer = stub("current_consumer", :id => consumer_id, :publisher_id => publisher_id)
      @controller = stub("controller").extend(DailyDealPurchases::ConsumerActionGuard)
      @controller.stubs(:current_consumer).returns(@current_consumer)
      @controller.stubs(:admin? => true)
      @params = { :publisher_id => publisher_id.to_s, :consumer_id => consumer_id.to_s }
      @controller.stubs(:params => @params)
    end
    should "allow admin access when publishers do not match" do
      @current_consumer.stubs(:has_admin_privilege?).returns(true)
      @current_consumer.stubs(:publisher_id).returns(456)
      assert @controller.allow_consumer_action?
    end
  end

  context "current_consumer_allowed_access_to_this_pub" do
    should "delegate to publisher" do
      @controller = stub("controller")
      @controller.extend(DailyDealPurchases::ConsumerActionGuard)
      consumer = stub("consumer")
      publisher = stub("publisher")
      @controller.stubs(:current_consumer_publisher_matches_params?).returns(false)
      @controller.stubs(:current_consumer).returns(consumer)
      @controller.stubs(:publisher).returns(publisher)
      publisher.expects(:allow_consumer_access?).returns(true)
      assert @controller.current_consumer_allowed_access_to_this_publisher?
    end
  end

end

