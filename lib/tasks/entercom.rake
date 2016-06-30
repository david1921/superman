namespace :entercom do
  
  desc "Export Entercom order/transaction data to a CSV file"
  task :generate_purchases_and_refunds_csv => :environment do
    csv_filename = Export::Entercom::PurchasesAndRefunds.export_to_csv!
    puts "Entercom purchases exported to #{csv_filename}."
  end
  
  desc "Export and upload Entercom order/transaction data as a CSV file"
  task :upload_purchases_and_refunds_csv => :environment do
    Export::Entercom::PurchasesAndRefunds.upload_csv!
  end
  
  desc "Export Entercom consumer and subscriber data to a CSV file"
  task :generate_signups_csv => :environment do
    csv_filename = Export::Entercom::Signups.export_to_csv!
    puts "Entercom signups exported to #{csv_filename}."
  end
  
  desc "Export and upload Entercom consumer and subscriber data as a CSV file"
  task :upload_signups_csv => :environment do
    Export::Entercom::Signups.upload_csv!
  end
  
  desc "Export Entercom merchant data to a CSV file"
  task :generate_merchants_csv => :environment do
    csv_filename = Export::Entercom::Merchants.export_to_csv!
    puts "Entercom merchants exported to #{csv_filename}."
  end
  
  desc "Export and upload Entercom merchant data as a CSV file"
  task :upload_merchants_csv => :environment do
    Export::Entercom::Merchants.upload_csv!
  end
end