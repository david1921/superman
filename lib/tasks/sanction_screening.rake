namespace :sanction_screening do
  
  desc "Export publisher sanction screening file (only for testing)"
  task :export_publisher_file => :environment do
    Export::SanctionScreening::Publishers.export_to_pipe_delimited_file!
  end

  desc "Export, encrypt, and upload publisher sanction screening file"
  task :export_and_uploaded_encrypted_publisher_file => :environment do
    passphrase = ENV['PASSPHRASE'] || raise("Must set PASSPHRASE environment variable")
    Export::SanctionScreening::Publishers.export_encrypt_and_upload!(passphrase, SanctionsConfig.gpg_recipient)
  end
  
  desc "Export consumer screening file"
  task :export_consumer_file => :environment do
    Export::SanctionScreening::Consumers.export_to_pipe_delimited_file!(SanctionsConfig.screening_start_date)
  end

  desc "Export, encrypt, and upload consumer sanction screening file"
  task :export_and_uploaded_encrypted_consumer_file => :environment do
    passphrase = ENV['PASSPHRASE'] || raise("Must set PASSPHRASE environment variable")
    Export::SanctionScreening::Consumers.export_encrypt_and_upload!(passphrase, SanctionsConfig.gpg_recipient, SanctionsConfig.screening_start_date)
  end

  desc "Export advertiser screening file (for testing)"
  task :export_advertiser_file => :environment do
    Export::SanctionScreening::Advertisers.export_to_pipe_delimited_file!(SanctionsConfig.screening_start_date)
  end

  desc "Export, encrypt, and upload advertiser sanction screening file"
  task :export_and_uploaded_encrypted_advertiser_file => :environment do
    passphrase = ENV['PASSPHRASE'] || raise("Must set PASSPHRASE environment variable")
    Export::SanctionScreening::Advertisers.export_encrypt_and_upload!(passphrase, SanctionsConfig.gpg_recipient, SanctionsConfig.screening_start_date)
  end

  desc "Clean up daily deal payments"
  task :cleanup_daily_deal_payments => :environment do
    Export::SanctionScreening::DailyDealPayment.cleanup
  end

end
