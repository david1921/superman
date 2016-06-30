namespace :debug do
  
  desc "Print a list of IDs of captured and refunded purchases that don't have vouchers"
  task :purchases_missing_vouchers => :environment do
    purchases = DailyDealPurchase.purchases_that_should_have_vouchers_but_dont
    if purchases.present?
      puts "Found #{purchases.count} purchases missing vouchers"
      puts purchases.map(&:id).join("\n")
    else
      puts "No purchases missing vouchers were found" 
    end
  end

end
