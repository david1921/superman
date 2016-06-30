namespace :oneoff do
  desc "Print URLs for the last captured purchase by CONSUMER_EMAIL"
  task :print_purchase_urls => :environment do
    include ActionController::UrlWriter
    
    publisher_label = "analogapplied"
    raise "CONSUMER_EMAIL is required" unless (email = ENV['CONSUMER_EMAIL'])
    publisher = Publisher.find_by_label(publisher_label)
    raise "Can't find publisher '#{publisher_label}'" unless publisher
    raise "Can't find consumer with email '#{email}' for '#{publisher_label}'" unless (consumer = publisher.consumers.find_by_email(email))
    
    if (purchase = consumer.daily_deal_purchases.captured(nil).last)
      puts "Thank-you page: #{thank_you_daily_deal_purchase_path(purchase)}"
      puts " Vouchers page: #{redeemable_daily_deal_purchase_daily_deal_certificates_path(purchase)}"
    else
      puts "Sorry, consumer '#{email}' has no captured purchases"
    end
  end
end
