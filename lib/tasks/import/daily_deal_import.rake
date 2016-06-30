namespace :import do
  desc "import daily deals according to the daily deals api via ftp"
  task :daily_deals_via_ftp => :environment do
    raise "Must set PUBLISHER_LABEL" unless label = ENV['PUBLISHER_LABEL']
    raise "Can't find publisher with label '#{label}'" unless publisher = Publisher.find_by_label(label)
    puts "Daily Deal Import via FTP for #{label}..."

    require File.expand_path("lib/tasks/import/daily_deal_import", RAILS_ROOT)
    include ::Import::DailyDealImport
    
    if publisher_config_name = ENV['PUBLISHER_CONFIG']
      puts "Using alternate publisher config: #{publisher_config_name}"
    else
      puts "Using publisher config based on publisher label"
      publisher_config_name = label
    end

    config_for_all_publishers = UploadConfig.new(:publishers)
    publisher_config = config_for_all_publishers[publisher_config_name]
    uploader = Uploader.new(publisher_config)
    remote_files = uploader.remote_files(publisher_config)
    ready_to_process = FTP.select_files_ready_to_process(publisher, remote_files)

    if ready_to_process.empty?
      puts "No files were found that were ready to process"
    else
      puts "Ready to process: #{ready_to_process}"
    end
    
    FTP.download_files(uploader, publisher_config, ready_to_process)
    FTP.import_files_and_upload_response_files(Publisher.find_by_label(label), ready_to_process, uploader, publisher_config)
    puts "Done."
  end

  desc "Import daily deals for PUBLISHER_LABEL or PUBLISHING_GROUP_LABEL"
  task :daily_deals_via_http => :environment do
    require File.expand_path("lib/tasks/import/daily_deal_import", RAILS_ROOT)
    include ::Import::DailyDealImport
    Import::DailyDeals::Importer.import_daily_deals_via_http!
  end

end
