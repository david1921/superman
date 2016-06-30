namespace :oneoff do

  desc "Print out IDs of purchases that are captured or refunded, but have no vouchers"
  task :print_ids_of_purchases_with_no_vouchers => :environment do
    broken_purchases = DailyDealPurchase.find_by_sql(%Q{
SELECT ddp.id
FROM daily_deal_purchases ddp
  LEFT OUTER JOIN daily_deal_certificates ddc ON ddc.daily_deal_purchase_id = ddp.id
WHERE ddp.payment_status IN ('captured', 'refunded')
  AND ddp.type = 'DailyDealPurchase'
  AND ddc.id IS NULL
})

    broken_purchases.each do |p|
      puts p.id
    end
    puts "#{broken_purchases.size} records found"
  end

  desc "Generate a report for the purchases listed in the PURCHASE_IDS_FILE"
  task :generate_broken_purchases_and_vouchers_report => :environment do
    Oneoff::DailyDealPurchaseFixer.new.generate_broken_purchases_and_vouchers_report!
  end
  
  desc "Regenerate vouchers for captured and refunded purchases that have no vouchers"
  task :generate_vouchers_for_purchases_missing_vouchers => :environment do
    successful_count, errors = Oneoff::DailyDealPurchaseFixer.new.fix_purchases_with_missing_vouchers!
    if errors.present?
      puts "******************************************************"
      puts "Errors occurred trying to fix the following purchases:"
      puts "******************************************************"
      errors.each do |purchase, exception|
        puts "-" * 72
        puts "DailyDealPurchase #{purchase.id}: #{exception.message}"
        puts exception.backtrace
        puts "-" * 72
      end
      puts ""
      puts "#{successful_count} records fixed successfully, #{errors.size} errors"
    end
  end

  task :finish_updating_purchases_that_had_errors_regenerating_vouchers => :environment do
    successful_count, errors = Oneoff::DailyDealPurchaseFixer.new.fix_purchases_with_missing_vouchers!(:skip_generating_certs => true, :skip_purchase_validation_on_save => true)
    if errors.present?
      puts "******************************************************"
      puts "Errors occurred trying to fix the following purchases:"
      puts "******************************************************"
      errors.each do |purchase, exception|
        puts "-" * 72
        puts "DailyDealPurchase #{purchase.id} - #{exception.class.name}: #{exception.message}"
        puts exception.backtrace
        puts "-" * 72
      end
      puts ""
      puts "#{successful_count} records fixed successfully, #{errors.size} errors"
    end
  end

end
