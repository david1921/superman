namespace :clickedin do
  
  desc "Export clickedin order/transaction data to a CSV file"
  task :generate_purchases_csv => :environment do
    csv_filename = Export::Twc::PurchasesAndRefunds.export_to_csv!
    puts "Clickedin purchases exported to #{csv_filename}."
  end
  
  desc "Export and upload clickedin order/transaction data as a CSV file"
  task :upload_purchases_csv => :environment do
    Export::Twc::PurchasesAndRefunds.upload_csv!
  end
  
  desc "Export clickedin consumer and subscriber data to a CSV file"
  task :generate_signups_csv => :environment do
    csv_filename = Export::Twc::Signups.export_to_csv!
    puts "Clickedin signups exported to #{csv_filename}."
  end
  
  desc "Export and upload clickedin consumer and subscriber data as a CSV file"
  task :upload_signups_csv => :environment do
    Export::Twc::Signups.upload_csv!
  end
end
