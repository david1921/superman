namespace :newsweek do
  
  desc "Export purchases"
  task :export_purchases => :environment do
    Export::Newsweek::PurchaseExport.export_to_1500_record_layout!
  end
  
  desc "Export and upload purchases"
  task :upload_purchases => :environment do
    Export::Newsweek::PurchaseExport.upload_1500_record_layout_file!
  end

end
