namespace :mcclatchy do

  desc "Create consumers with preset purchase credit"
  task :download_and_import_offers_for_today => :environment do
    Import::McclatchyOffers.download_and_import_offers_for_today("ftp.travidia.com", "analoganalytics", "211xrl")
  end

end