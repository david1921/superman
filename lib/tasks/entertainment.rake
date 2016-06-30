namespace :entertainment do

  task :require do
    require 'lib/tasks/delimited_file'
  end

  desc "Temporary alias for backward compatibility.  See generate_deal_email_file."
  task :generate_signups_with_deals_by_city => :environment do
    Rake::Task["entertainment:generate_and_upload_deal_email_file"].execute
  end

  desc "Generates signups with deals by city csv file for entertainment (formerly called: generate_signups_with_deals_by_city)"
  task :generate_and_upload_deal_email_file => [:require, :environment] do
    raise "Entertainment not in the database" unless entertainment = PublishingGroup.find_by_label("entertainment")
    raise "Must specify comma delimited list of publisher labels in env PUBLISHER_LABELS" if ENV['PUBLISHER_LABELS'].nil?
    raise "Must specify TIME_ZONE to use in the file name" if ENV['TIME_ZONE'].nil?

    require File.expand_path("app/models/report/entertainment/deal_email_file")

    publishing_groups_config = UploadConfig.new(:publishing_groups)
    time_zone                = ENV['TIME_ZONE']
    file                     = ENV['FILE'] || "ENTERTAINPUB_DYNDS_DAILYDEAL_#{time_zone}_#{Time.zone.now.strftime("%Y%m%d")}.txt"
    file_base                = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
    file_path                = File.expand_path(file, file_base)
    labels                   = ENV['PUBLISHER_LABELS'].split(",").map(&:strip)

    Rails.logger.info "Generating email file for #{labels.inspect}"

    DelimitedFile.open(file_path, '|') do |file|
      Report::Entertainment.generate_deal_email_file(entertainment, file, labels)
    end
    Uploader.new(publishing_groups_config).upload("entertainment", file_path) unless ENV['DRY_RUN'].present?
    Uploader.new(publishing_groups_config).upload("entertainment_boss", file_path) unless ENV['DRY_RUN'].present?
  end

  desc "Generates entertainment signups summaries by markets and adds to database"
  task :store_deal_email_purchase_counts => :environment do
    require 'lib/export/entertainment/deal_summary_email_task'

    is_dry_run = !ENV['DRY_RUN'].nil?
    input_file = ENV['FILE']
    for_date   = ENV['DATE']

    Export::Entertainment::DealSummaryEmailTask.store_deal_purchase_counts(input_file, for_date, is_dry_run)
  end

  desc "Generates entertainment comparisons by markets as a csv file"
  task :generate_deal_summary_email_file => :environment do
    require 'lib/export/entertainment/deal_summary_email_task'

    is_dry_run = !ENV['DRY_RUN'].nil?

    has_time_zone = !ENV['TIME_ZONE'].nil?
    has_file_name = !ENV['OUTPUT_FILE'].nil?
    raise ArgumentError, "Must specify TIME_ZONE to use in the file name" if !has_file_name && !has_time_zone
    output_file = ENV['OUTPUT_FILE']

    compare_date = ENV['START_DATE']
    for_date = ENV['END_DATE']

    Export::Entertainment::DealSummaryEmailTask.generate_deal_purchase_variance_file(time_zone, output_file, compare_date, for_date, is_dry_run)
  end

  desc "Uploads entertainment signups summaries and comparisons by markets csv file"
  task :upload_deal_summary_email_file => :environment do
    require 'lib/export/entertainment/deal_summary_email_task'

    output_file = ENV['FILE']
    is_dry_run = !ENV['DRY_RUN'].nil?

    Export::Entertainment::DealSummaryEmailTask.upload_deal_purchase_variance_file(output_file, is_dry_run)
  end

  desc "Send Market Summary"
  task :send_market_summary => :environment do
    dry_run = ENV['DRY_RUN'].present?
    time_zone = ENV['TIME_ZONE']

    Jobs::SendDealEmailFileMarketSummaryJob.perform(time_zone, dry_run)
  end

  desc "Generates the BOSS file"
  task :generate_and_upload_boss_file => [:require, :environment] do
    publishing_groups_config = UploadConfig.new(:publishing_groups)
    config                   = publishing_groups_config.fetch!("entertainment_boss")
    file_base                = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
    file_path                = File.expand_path(config[:file], file_base)

    raise "Entertainment not in the database" unless publishing_group = PublishingGroup.find_by_label("entertainment")

    begin
      daily_deal_purchase_ids = nil
      DelimitedFile.open(file_path, '') do |file|
        daily_deal_purchase_ids = Report::Entertainment::Boss.new.generate_for_publishing_group(file, publishing_group)
      end
      Uploader.new(publishing_groups_config).upload("entertainment_boss", file_path)
      # _AFTER_ uploading, update the purchases
      DailyDealPurchase.update_sent_to_publisher_at(Time.now, daily_deal_purchase_ids)
    rescue => ex
      puts "#{ex.class}: #{ex.message}"
    end

  end

  desc "Generates the Merchant file"
  task :generate_and_upload_merchant_file => [:require, :environment] do
    publishing_groups_config = UploadConfig.new(:publishing_groups)
    config                   = publishing_groups_config.fetch!("entertainment_merchant")

    file_base                = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
    file_path                = File.expand_path(config[:file], file_base)

    raise "Entertainment not in the database" unless publishing_group = PublishingGroup.find_by_label("entertainment")
    DelimitedFile.open(file_path, '|') do |file|
      Report::Entertainment::MerchantReport.new.generate(file, publishing_group)
    end
    Uploader.new(publishing_groups_config).upload("entertainment_merchant", file_path)
  end

  desc "Temporary for backwards compatibility"
  task :generate_enrollee_file => :environment do
    Rake::Task["entertainment:generate_and_upload_enrollee_file"].execute
  end

  desc "Generates the Enrollee file"
  task :generate_and_upload_enrollee_file => [:require, :environment] do |t|
    publishing_groups_config = UploadConfig.new(:publishing_groups)
    config                   = publishing_groups_config.fetch!("entertainment_enrollee")

    file_base                = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
    file_path                = File.expand_path(config[:file], file_base)

    raise "Entertainment not in the database" unless publishing_group = PublishingGroup.find_by_label("entertainment")

    Job.run! t.name, :incremental => true do
      DelimitedFile.open(file_path, '|') do |file|
        Report::Entertainment::Enrollee.new.generate(publishing_group, file, true)
      end

      #    upload to two places
      Uploader.new(publishing_groups_config).upload("entertainment_enrollee", file_path)
      Uploader.new(publishing_groups_config).upload("entertainment_enrollee_sftp", file_path)
    end
  end

  desc "Create and upload purchases file (default includes yesterday only)"
  task :create_and_upload_purchases_file => :environment do |t|
    report_days = ENV['NUM_DAYS'] ? ENV['NUM_DAYS'].to_i : 1
    starting = report_days.days.ago
    ending = 1.day.ago

    Job.run! t.name, :incremental => true do
      publishing_groups_config = UploadConfig.new(:publishing_groups)
      config = publishing_groups_config.fetch!("entertainment_purchases")

      file_base = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
      file_path = File.expand_path(config[:file], file_base)

      publishing_group = PublishingGroup.find_by_label!("entertainment")
      FasterCSV.open(file_path, 'w', :col_sep => '|') do |csv|
        publishing_group.daily_deal_purchases_to_csv(csv, (starting..ending))
      end

      #    upload to two places (use same destination as enrollee file)
      Uploader.new(publishing_groups_config).upload("entertainment_enrollee_sftp", file_path)
    end
  end
end
