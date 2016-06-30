namespace :daily_deal_orders do
  
  desc "find pending orders that have at least one captured purchase"
  task :find_pending_orders_with_captured_purchases => :environment do
    raise "please provide a CSV_FILENAME" unless csv_filename = ENV["CSV_FILENAME"]
    bad_purchases = []
    DailyDealOrder.all.each do |ddo|
      ddo.daily_deal_purchases.each do |ddp|
        unless %w( voided refunded ).include?(ddp.payment_status)
          unless ddo.payment_status == ddp.payment_status
            daily_deal = ddp.daily_deal
            advertiser = daily_deal.advertiser
            bad_purchases.push([ddo.id, ddo.payment_status, ddo.consumer.name, ddo.consumer.email, ddo.total_price, daily_deal.id, daily_deal.value_proposition, advertiser.id, advertiser.name])
          end
        end
      end
    end
    
    FasterCSV.open(csv_filename, "w") do |csv|
      csv << ["Order Id", "Order Status", "Consumer Name", "Consumer Email", "Order Total", "Daily Deal Id", "Daily Deal Value Prop", "Advertsier Id", "Advertiser Name"]
      bad_purchases.each do |bad_purchase|
        csv << bad_purchase
      end
    end
    
  end
  
  desc "fix pending orders that have at least one captured purchase"
  task :fix_up_pending_orders_with_captured_purchases => :environment do
    bad_orders = []
    DailyDealOrder.all.each do |ddo|
      ddo.daily_deal_purchases.each do |ddp|
        unless %w( voided refunded ).include?(ddp.payment_status)
          unless ddo.payment_status == ddp.payment_status
            bad_orders.push(ddo)
          end
        end
      end
    end    

    puts "found: #{bad_orders.size} bad orders"

    bad_orders.each do |order|
      order.daily_deal_purchases.each do |purchase|
        if purchase.payment_status == 'pending'
          purchase.update_attribute(:payment_status, 'captured')
          if purchase.errors.present?
            puts "we have an issue on purchase: #{purchase.id}: #{purchase.errors.full_messages}"
          end
        end
      end
      order.update_attribute(:payment_status, 'captured')
      puts "error on order: #{order.id} error: #{order.errors.full_messages}" if order.errors.present?
    end
    puts "completed"
  end
  
  desc "report on any daily deals with braintree redirect results"
  task :find_orders_with_braintree_redirect_errors => :environment do
    BraintreeRedirectResult.find(:all, :conditions => ["error = ? and daily_deal_order_id is not null", true]).each do |result|
      puts "order: #{result.daily_deal_order_id} error: #{result.error_message}"
    end
  end
  
end