namespace :export do
  namespace :seattlepi do
    desc "Generate a subscriber file that in what counts format"
    task :signups_for_what_counts => :environment do
      raise "Must set PUBLISHER_LABEL" unless publisher_label = ENV['PUBLISHER_LABEL']
      upload = ENV['UPLOAD']
      interval_in_hours = ENV['INTERVAL_IN_HOURS']
      interval_in_hours = interval_in_hours.nil? ? nil : interval_in_hours.to_i
      publisher_config = UploadConfig.new(:publishers).fetch!(publisher_label)
      raise "Must provide :what_counts_realm in config" unless what_counts_realm = publisher_config[:what_counts_realm]
      raise "Must provide :what_counts_api_password in config" unless what_counts_api_password = publisher_config[:what_counts_api_password]
      raise "Must provide :what_counts_list_id in config" unless what_counts_list_id = publisher_config[:what_counts_list_id]
      raise "Must provide :what_counts_confirmation_email in config" unless what_counts_confirmation_email = publisher_config[:what_counts_confirmation_email]
      raise "Must provide :what_counts_file in config" unless file_name = publisher_config[:what_counts_file]

      puts "No interval was specified, will export all signups" if interval_in_hours.nil?
      puts "Will upload signups" if upload

      file_base = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
      raise "Must set :what_counts_file in config" unless file_name
      file_path = File.expand_path(file_name, file_base)
      publisher = Publisher.find_by_label(publisher_label)

      signups = publisher.signups(interval_in_hours)
      puts "Writing #{signups.size} signups to #{file_path}"
      File.open(file_path, "w") do |file|
        what_counts_xml_file = Export::WhatCounts::SubscribeFile.new(file,
                                                                     what_counts_realm,
                                                                     what_counts_api_password,
                                                                     what_counts_list_id,
                                                                     what_counts_confirmation_email)
        what_counts_xml_file.export_subscribers(signups)
      end
      if upload
        puts "Uploading subscribe file"
        uploader = Uploader.new(publisher_config)
        uploader.upload(publisher_config, file_path)
        sig_file_path = file_path.gsub(/.xml$/, ".sig")
        File.open(sig_file_path, "w") { |file| file << "This is the signal file" }
        puts "Uploading signal file"
        uploader.upload(publisher_config, sig_file_path)
      end
    end
  end
end
