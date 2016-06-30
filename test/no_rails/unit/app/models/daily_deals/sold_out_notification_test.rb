require File.dirname(__FILE__) + "/../../models_helper"

class DailyDeals::SoldOutNotificationTest < Test::Unit::TestCase
  def setup
    @obj = Object.new.extend(DailyDeals::SoldOutNotification)
    @obj.stubs(:sold_out_without_purchase_api_sold_out_push_notification!)
    @obj.stubs(:notify_third_party_purchases_api)
  end

  context "#sold_out_with_purchase_api_sold_out_push_notification!" do
    should "call the original sold_out! method" do
      @obj.expects(:sold_out_without_purchase_api_sold_out_push_notification!)
      @obj.sold_out_with_purchase_api_sold_out_push_notification!
    end

    should "notify the third-party purchases API" do
      @obj.expects(:notify_third_party_purchases_api)
      @obj.sold_out_with_purchase_api_sold_out_push_notification!
    end
  end
end