namespace :oneoff do
  
  task :correct_refund_amount => :environment do
    doit = ENV["DOIT"] == "1"

    unless doit
      puts "\n@@@@@@@@@@ ** This is a DRY RUN. ** Pass DOIT=1 to actually correct the refund amounts. @@@@@@@@@@"
    end

    serial_number = ENV["SERIAL_NUMBER"]
    unless serial_number.present?
      raise ArgumentError, "you must set the SERIAL_NUMBER environment variable to run this task"
    end

    cert = DailyDealCertificate.find_by_serial_number_and_status_and_refund_amount!(serial_number, "active", 0)
    puts "\nCorrecting refund amount for DailyDealCertificate with serial number #{serial_number}...\n\n" 

    refund_user = User.find_by_admin_privilege_and_email!("F", "brad.bollenbach@analoganalytics.com")
    purchase = cert.daily_deal_purchase 
    DailyDealCertificate.transaction do
      cert.refund!
      purchase.refund_amount += cert.refund_amount
      purchase.payment_status_updated_by_txn_id = "was-#{purchase.payment_status_updated_by_txn_id}-before-manual-refund-correction"
      purchase.refunded_at = Time.zone.now
      purchase.refunded_by  = refund_user.login
      puts "Updating DailyDealPurchase #{purchase.id} as follows:\n"
      purchase.changes.each do |col_name, values|
        puts "    #{col_name}: #{values.first} => #{values.second}"
      end
      puts ""

      if doit
        purchase.set_payment_status!("refunded")
      else
        raise "@@@@@@@@@@ [DRY RUN] Rolling back; no records were updated @@@@@@@@@@"
      end
    end

  end

end
