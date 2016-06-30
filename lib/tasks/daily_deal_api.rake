namespace :daily_deal_api do
  
  desc "Send a push notification containing the current deal to iPhones registered with the api"
  task :send_push_notifications => :environment do
    DailyDealApi.send_push_notifications!
  end
  
end