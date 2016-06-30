require File.dirname(__FILE__) + "/../test_helper"

# FIXME Move this, and other test cases with daily_deal_ prefixes into daily_deals directory
class DailyDealApiTest < ActiveSupport::TestCase
  
  context ".send_push_notifications!" do
    
    setup do
      ENV.delete("DRY_RUN")
    end
    
    should "truncate the value proposition when it exceeds 120 characters" do
      daily_deal = Factory :daily_deal, :value_proposition => "One of the most amazing deals you've ever seen! You will absolutely NEVER believe how much you'll save! This is so incredible!"
      Factory :push_notification_device, :token => "token-1", :publisher => daily_deal.publisher      
      APNS.expects(:send_notification).with("token-1", "One of the most amazing deals you've ever seen! You will absolutely NEVER believe how much you'll save! This is so in...").once
      DailyDealApi.send_push_notifications!
    end
  
    should "call #send_deal_notification! for each registered PushNotificationDevice" do
      daily_deal = Factory :daily_deal, :value_proposition => "An amazing deal!"
      
      Factory :push_notification_device, :token => "token-1", :publisher => daily_deal.publisher
      Factory :push_notification_device, :token => "token-2", :publisher => daily_deal.publisher
      
      APNS.expects(:send_notification).with("token-1", "An amazing deal!").once
      APNS.expects(:send_notification).with("token-2", "An amazing deal!").once

      DailyDealApi.send_push_notifications!
    end
    
    should "not call #send_push_notifications! on a dry run" do
      ENV["DRY_RUN"] = "1"
      daily_deal = Factory :daily_deal, :value_proposition => "An amazing deal!"
      Factory :push_notification_device, :token => "token-1", :publisher => daily_deal.publisher
      APNS.expects(:send_notification).never
      DailyDealApi.send_push_notifications!
    end
    
  end
  
end