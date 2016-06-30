require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Api::ThirdPartyPurchases::SoldOutPushNotificationTest

module Api::ThirdPartyPurchases
  class SoldOutPushNotificationTest < ActiveSupport::TestCase

    def setup
      @deal = Factory(:daily_deal, :quantity => 1)
    end

    should "POST to all third party purchase api configs with a url when a deal sells out" do
      Api::ThirdPartyPurchases::SoldOutPushNotification.expects(:perform).with(@deal.id)
      purchase = Factory(:off_platform_daily_deal_purchase, :daily_deal => @deal, :quantity => 1)
      purchase.capture!
    end
  end
end
