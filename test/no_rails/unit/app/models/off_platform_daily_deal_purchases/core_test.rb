require File.dirname(__FILE__) + "/../../models_helper"

class OffPlatformDailyDealPurchases::CoreTest < Test::Unit::TestCase
  def setup
    @obj = Object.new.extend(OffPlatformDailyDealPurchases::Core)
  end

  context "#capture!" do
    should "set the payment status to 'captured'" do
      @obj.expects(:set_payment_status!).with('captured')
      @obj.capture!
    end
  end

  context "#origin_name" do
    should "return the API user's name" do
      api_user = stub
      api_user.expects(:name).returns("Test API user name")
      @obj.expects(:api_user).returns(api_user)
      assert_equal "Test API user name", @obj.origin_name
    end
  end
end
