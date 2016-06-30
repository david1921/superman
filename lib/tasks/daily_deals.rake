namespace :daily_deals do
  
  desc "Unsellout a daily deal, given an id, optionally you can also give a new quantity"
  task :unsellout, [:daily_deal_id, :new_sellout_quantity] => :environment do |t|
    raise "Must supply daily deal id" unless args.daily_deal_id.present?
    dd = DailyDeal.find(args.daily_deal_id)
    dd.sold_out_at = nil
    dd.quantity = args.new_sellout_quantity if args.new_sellout_quantity.present?
    dd.save
  end

  desc "Generate (WITHOUT uploading) consumers CSV for PUBLISHER_LABEL"
  task :generate_consumers_csv => :environment do |t|
    raise "Must set PUBLISHER_LABEL" unless label = ENV['PUBLISHER_LABEL']
    raise "Can't find publisher with label '#{label}'" unless publisher = Publisher.find_by_label(label)

    publishers_config = UploadConfig.new(:publishers)
    config = publishers_config.fetch!(label)

    file_base = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
    file_path = File.expand_path(config[:file], file_base)
    csv_options = { :force_quotes => true }
    csv_options.merge!(:col_sep => "\t") if ".xls" == File.extname(file_path).downcase

    FasterCSV.open(file_path, "w", csv_options) do |csv|
      publisher.generate_consumers_list(csv, :columns => config[:cols], :allow_duplicates => config[:dups] || false, :column_title_map => config[:cmap], :interval_in_hours => config[:hour])
    end
  end

  desc "Generate CSVs of all daily deal data for PUBLISHING_GROUP_LABEL"
  task :publishing_group_to_csv => :environment do
    label = ENV['PUBLISHING_GROUP_LABEL']
    raise "Must set PUBLISHING_GROUP_LABEL" if label.blank?

    publishing_group = PublishingGroup.find_by_label!(label)

    file_base = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)

    file_path = File.expand_path("consumers.csv", file_base)
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      publishing_group.consumers_to_csv csv
    end

    file_path = File.expand_path("subscribers.csv", file_base)
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      publishing_group.subscribers_to_csv csv
    end

    file_path = File.expand_path("purchased_daily_deals.csv", file_base)
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      publishing_group.daily_deal_purchases_to_csv csv
    end

    file_path = File.expand_path("advertisers.csv", file_base)
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      publishing_group.advertisers_to_csv csv
    end

    file_path = File.expand_path("daily_deals.csv", file_base)
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      publishing_group.daily_deals_to_csv csv
    end

    file_path = File.expand_path("daily_deal_certificates.csv", file_base)
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      publishing_group.daily_deal_certificates_to_csv csv
    end

    file_path = File.expand_path("daily_deal_revenue.csv", file_base)
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      publishing_group.daily_deal_revenue_to_csv csv
    end

    file_path = File.expand_path("daily_deal_active_discounts.csv", file_base)
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      publishing_group.active_discounts_to_csv csv
    end
  end

  desc "Generate and weekly email CSV of redeemed daily deal certificates for PUBLISHING_GROUP_LABEL"
  task :email_redeemed_daily_deal_certificates_csv => :environment do
    label = ENV['PUBLISHING_GROUP_LABEL']
    email = ENV['EMAIL']

    unless label and email
      raise "Must set PUBLISHING_GROUP_LABEL and EMAIL"
    end

    publishing_group = PublishingGroup.find_by_label(label)
    file_base        = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
    file_path        = File.expand_path("redeemed_daily_deal_certificates.csv", file_base)

    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      publishing_group.daily_deal_certificates_to_csv(csv, ["redeemed_at > ?", 1.week.ago])
    end

    FileMailer.deliver_file(email, "Redeemed voucher information", file_path)
  end

  desc "Generate and upload consumers CSV for PUBLISHER_LABEL"
  task :upload_consumers_csv => :environment do |t|
    raise "Must set PUBLISHER_LABEL" unless label = ENV['PUBLISHER_LABEL']
    raise "Can't find pubisher with label '#{label}'" unless publisher = Publisher.find_by_label(label)

    publishers_config = UploadConfig.new(:publishers)
    config = publishers_config.fetch!(label)
    config[:mail] ||= ENV['EMAIL']

    file_base = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
    file_path = File.expand_path(config[:file], file_base)
    csv_options = { :force_quotes => true }
    csv_options.merge!(:col_sep => "\t") if ".xls" == File.extname(file_path).downcase

    FasterCSV.open(file_path, "w", csv_options) do |csv|
      publisher.generate_consumers_list(csv, :columns => config[:cols], :allow_duplicates => config[:dups] || false, :column_title_map => config[:cmap], :interval_in_hours => config[:hour])
    end

    if config[:mail]
      PublishersMailer.deliver_latest_consumers_and_subscribers(publisher, file_path) unless publisher.subscriber_recipients.blank?
    else
      Uploader.new(publishers_config).upload(label, file_path)
    end

  end
  
  desc "Generate consumer CSV of all daily deal data for PUBLISHING_GROUP_LABEL"
  task :publishing_group_consumers_to_csv => :environment do
    label = ENV['PUBLISHING_GROUP_LABEL']
    raise "Must set PUBLISHING_GROUP_LABEL" if label.blank?

    publishing_group = PublishingGroup.find_by_label!(label)

    file_base = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)

    file_path = File.expand_path("#{label}_consumers.csv", file_base)
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      publishing_group.consumers_to_csv csv
    end
  end

  desc "Generate and upload consumers CSV for PUBLISHING_GROUP_NAME or PUBLISHING_GROUP_LABEL"
  task :upload_publishing_group_consumers_csv => :environment do |t|
    name  = ENV['PUBLISHING_GROUP_NAME']
    label = ENV['PUBLISHING_GROUP_LABEL']
    
    raise "Must supply a PUBLISHING_GROUP_NAME or PUBLISHING_GROUP_LABEL" unless name or label
    publishing_group = name.present? ? PublishingGroup.find_by_name(name) : PublishingGroup.find_by_label(label)
    raise "Can't find pubishing group with the given name or label" unless publishing_group

    publishing_groups_config = UploadConfig.new(:publishing_groups)
    config = publishing_groups_config.fetch!(publishing_group.label)

    file_base = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
    file_path = File.expand_path(config[:file] || "consumers_#{publishing_group.label}_#{Time.zone.now.strftime("%Y%m%d")}", file_base)

    list_options = {
      :publisher_labels => config[:pubs],
      :columns => config[:cols],
      :column_title_map => config[:cmap],
      :interval_in_hours => config[:hour],
      :include_publisher_bitmap => config[:bitmap]
    }


    if config[:pipe_delimited]
      File.open(file_path, "w") do |csv|
        def csv.<<(list)
          self.write(list.join("|") << "\n")
        end
        publishing_group.generate_consumers_list csv, list_options
      end
    else
      csv_options = { :col_sep => config[:separator] || "," }
      FasterCSV.open(file_path, "w", csv_options) do |csv|
        publishing_group.generate_consumers_list csv, list_options
      end
    end

    unless ENV['DRY_RUN']
      if config[:mail]
        PublishingGroupsMailer.deliver_latest_consumers_and_subscribers(publishing_group, file_path)
      else
        Uploader.new(publishing_groups_config).upload(publishing_group.label, file_path)
      end
    end
  end

  desc "Validates ftp account info for PUBLISHER_LABEL"
  task :validate_upload_info => :environment do |t|
    raise "Must set PUBLISHER_LABEL" unless label = ENV['PUBLISHER_LABEL']
    publishers_config = UploadConfig.new(:publishers)
    raise "No config for publisher label '#{label}'" unless publishers_config.has_key?(label)
    uploader = Uploader.new(publishers_config)
    uploader.test_upload_config(publishers_config[label])
    puts "Ftp connection info for #{label} looks good."
  end

  desc "Validate all ftp account info in config/tasks/daily_deals/upload_coonsumers_csv.yml"
  task :validate_all_upload_info => :environment do |t|
    publishers_config = UploadConfig.new(:publishers)
    uploader = Uploader.new(publishers_config)
    errors = false
    publishers_config.labels.each do |label|
      begin
        print "Trying #{label}..."
        config = publishers_config[label]
        if config[:mail]
          puts "Email (No FTP)"
        else
          uploader.test_upload_config(config)
          puts "OK"
        end
      rescue
        puts "#{$!}"
        errors = true
      end
    end
    if errors
      puts "There were errors"
    else
      puts "All ftp info looks good!"
    end
  end

  desc "Generate consumers CSV for PUBLISHER_LABEL without uploading or emailing"
  task :export_consumers_csv => :environment do |t|
    raise "Must set PUBLISHER_LABEL" unless label = ENV['PUBLISHER_LABEL']
    raise "Can't find pubisher with label '#{label}'" unless publisher = Publisher.find_by_label(label)
    file = ENV['FILE'] || "#{label}.csv"

    cols = cols ? ENV['COLS'].split(',').map(&:strip) : ["status", "email", "name"]

    file_base = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
    file_path = File.expand_path(file, file_base)
    csv_options = { :force_quotes => true }
    csv_options.merge!(:col_sep => "\t") if ".xls" == File.extname(file_path).downcase

    FasterCSV.open(file_path, "w", csv_options) do |csv|
      publisher.generate_consumers_list(csv, :columns           => cols,
                                             :allow_duplicates  => ENV['DUPS'] || false,
                                             :interval_in_hours => ENV['HOUR'])
    end
  end

  desc "Export (without uploading) daily deal purchases, consumers, and subscribers for publisher nydailynews"
  task :export_nydn_purchases_and_consumers => :environment do
    publishers_config = UploadConfig.new(:publishers)
    config = publishers_config.fetch!("nydailynews")
    file_base = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
    absolute_csv_file_path = File.expand_path(config[:file], file_base)

    options = {}
    options[:file_name] = absolute_csv_file_path
    options[:incremental] = ENV["INCREMENTAL"].present?

    Publisher.export_nydn_purchases_and_consumers!(options)
  end

  desc "Export and upload daily deal purchases, consumers, and subscribers for publisher nydailynews"
  task :upload_nydn_purchases_and_consumers => [:environment, :export_nydn_purchases_and_consumers] do
    publishers_config = UploadConfig.new(:publishers)
    config = publishers_config.fetch!("nydailynews")
    if config[:host].empty?
      raise "NYDN export expects to be able to upload the exported file via (S)FTP, but no FTP host was found"
    end

    file_base = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
    absolute_csv_file_path = File.expand_path(config[:file], file_base)
    Uploader.new(publishers_config).upload("nydailynews", absolute_csv_file_path)
  end

  # GiftCertificate                       DailyDeal
  # -----------------------------------------------------
  # - advertiser_id                       - advertiser_id
  # - message                             - value_proposition
  # * description                         - description
  # * terms                               - terms
  # - value                               - value
  # - price                               - price
  # - show_on                             - start_at
  # - deleted                             - deleted_at
  # - physical_gift_certificate           - TBD
  # - number_allocated                    - quantity
  # - logo_file_name                      - photo_file_name
  # - bit_ly_url                          - bit_ly_url
  # - handling_fee                        - TBD
  # - collect_address                     - TBD
  # - N/A                                 - featured = false
  # - N/A                                 - expires_on (will be set manually by AMs)
  # - N/A                                 - category (will be set manually by AMs)
  desc "Create DailyDeals to replace GiftCertificates from publisher label FROM to publisher label TO"
  task [ :replace_gift_certificates, :from, :to ] => :environment do |t, args|

    from     = ENV["FROM"]     || args[:from]
    to       = ENV["TO"]       || args[:to]
    category = ENV["CATEGORY"] || args[:category]
    if from.blank? && to.blank?
      puts "please supply a FROM publisher label and a TO publisher label, or pass in from and to as args."
      exit
    end

    puts "migrating #{from} to #{to}"
    puts "--------------------------"

    GiftCertificate.transaction do
      will_be_set_manually_by_AMs = nil
      category_to_be_set_by_AMS = DailyDealCategory.find_by_name("Other")
      DailyDeal.transaction do
        from_publisher = Publisher.find_by_label!(from)
        to_publisher = Publisher.find_by_label!(to)

        gcs = from_publisher.gift_certificates.active.available # only migrate active and available gift certs
        puts "Converting #{gcs.count} certificates"
        gcs.each do |gift_certificate|
          print "."

          advertiser = to_publisher.advertisers.find_by_name(gift_certificate.advertiser.name)
          unless advertiser
            advertiser = gift_certificate.advertiser.clone
            advertiser.publisher = to_publisher
            begin
              advertiser.logo = gift_certificate.advertiser.logo
            rescue
              advertiser.logo = nil
            end
            advertiser.save!
          end

          description = gift_certificate.description.to_ascii(true)
          if description.blank?
            description = gift_certificate.message
          end

          start_at = gift_certificate.show_on || Time.zone.now
          hide_at = gift_certificate.expires_on ? gift_certificate.expires_on : 10.years.from_now
          if hide_at <= start_at
            hide_at = start_at + 1.week
          end

          daily_deal = to_publisher.daily_deals.create(
            :advertiser_id => advertiser.id,
            :value_proposition => "#{number_to_currency_with_smart_precision(gift_certificate.value)} Deal for Only #{number_to_currency_with_smart_precision(gift_certificate.price)}",
            :description => description,
            :terms => gift_certificate.terms.blank? ? "TBD" : gift_certificate.terms,
            :value => gift_certificate.value,
            :price => gift_certificate.price,
            :expires_on => will_be_set_manually_by_AMs,
            :start_at => start_at,
            :hide_at => hide_at,
            :deleted_at => gift_certificate.deleted ? Time.zone.now : nil,
            :quantity => gift_certificate.number_allocated > 0 ? gift_certificate.number_allocated : nil,
            :photo => gift_certificate.logo(:original),
            :side_start_at => start_at,
            :side_end_at => hide_at,
            :analytics_category => category_to_be_set_by_AMS,
            :publishers_category => category,
            :requires_shipping_address => gift_certificate.physical_gift_certificate
          )

          puts "Gift Certificate #{gift_certificate.id} migrated to Daily Deal #{daily_deal.id}"

          unless daily_deal.valid?
            raise "DailyDeal from GiftCertificate was not valid\n#{daily_deal.errors.full_messages.join(', ')}\n#{gift_certificate.inspect}\n#{daily_deal.inspect}"
          end
        end

        puts "\ndone"
      end
    end
  end

  desc "Export all of PUBLISHER_LABEL's current and future deals, as Google Offers Feed XML"
  task :export_google_offers_feed_xml => :environment do
    raise "Must set PUBLISHER_LABEL" unless label = ENV['PUBLISHER_LABEL']
    publisher = Publisher.find_by_label!(label)
    google_feed_xml = ""
    publisher.export_google_offers_feed_xml!(google_feed_xml)
    File.open(publisher.google_offers_feed_xml_filename, "w") do |f|
      f.write(google_feed_xml)
      puts "Exported #{publisher.label}'s Google Offers feed XML to #{f.path}"
    end
  end

  def number_to_currency_with_smart_precision(dollar_amount)
    include ActionView::Helpers::NumberHelper
    if dollar_amount.to_s =~ /\./
      number_to_currency(dollar_amount, :precision => 0)
    else
      number_to_currency(dollar_amount)
    end
  end

end
