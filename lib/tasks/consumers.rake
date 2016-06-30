namespace :consumers do
  desc "Consolidate consumer account to EMAIL using ALT_EMAILS  (filter by ENV[publisher_label] | ENV[publishing_group_label])"
  task :consolidate_consumer => :environment do
    raise "Requires ENV[EMAIL] && ENV[ALT_EMAILS]" if !ENV['EMAIL'].present? || !ENV['ALT_EMAILS'].present?
    
    base_consumer = Consumer.find_all_by_email(ENV['EMAIL'])
    raise "Multiple records found, must filter by publisher/publishing_group" if base_consumer.count > 1
    base_consumer = base_consumer.first
    puts "Found consumer #{base_consumer.id} w/#{base_consumer.credits.count} credits and #{base_consumer.daily_deal_purchases.count} purchases"

    other_consumer_accounts = []
    alt_emails = ENV['ALT_EMAILS'].split(",")
    alt_emails.each do |email|
      other_consumer_accounts << Consumer.find_by_email(email)
      puts "Found consumer #{other_consumer_accounts.last.id} w/#{other_consumer_accounts.last.credits.count} credits and #{other_consumer_accounts.last.daily_deal_purchases.count} purchases"
    end
    errors = []
    failed = false
    Consumer.transaction do
      begin
        other_consumer_accounts.each do |account|
          base_consumer.assimilate!(account)
        end
        puts "Consumer #{base_consumer.id} now has w/#{base_consumer.credits.count} credits and #{base_consumer.daily_deal_purchases.count} purchases"
      rescue ActiveRecord::RecordInvalid => e
        errors.concat(e.record.errors.full_messages)
        failed = true
      rescue => e
        raise e
        failed = true
      end
      if failed || errors.present? || ENV['DRY_RUN']
        puts "Rolling Back:"
        puts errors.join("|  ")
        puts "DRY RUN Complete." if ENV['DRY_RUN']
        raise ActiveRecord::Rollback
      end
      
    end
  end
  
  desc "Import Race Fan Savings consumers from CSV_FILE"
  task :import_for_racefansavings => :environment do
    csv_filename = ENV['CSV_FILE']
    raise "Missing required CSV_FILE" unless csv_filename.present?
    raise "Can't find file #{csv_filename}" unless File.exists?(csv_filename)

    racefansavings = Publisher.find_by_label("racefansavings")
    raise "Can't find publisher with label 'racefansavings'" unless racefansavings.present?

    FasterCSV.foreach(csv_filename) do |row|
      email, password = row
      consumer = Consumer.new :email => email,
                              :password => password,
                              :password_confirmation => password,
                              :activated_at => Time.now,
                              :publisher_id => racefansavings.id,
                              :agree_to_terms => "1"
      consumer.first_name_required = consumer.last_name_required = false
      begin
        consumer.save!
      rescue ActiveRecord::RecordInvalid
        puts "Error importing #{email}: #{consumer.errors.full_messages.join(', ')}"
      end
    end
  end

  desc "Create unactivated consumers for PUBLISHER_LABEL with signup DISCOUNT_CODE from import file at CSV_PATH"
  task :import_with_discount => :environment do
    raise "Must set PUBLISHER_LABEL" unless label = ENV['PUBLISHER_LABEL']
    raise "No pubisher with label '#{label}'" unless (publisher = Publisher.find_by_label(label))

    raise "Must set DISCOUNT_CODE" unless (code = ENV['DISCOUNT_CODE']).present?
    raise "No discount '#{code}' for publisher '#{publisher.label}'" unless (discount = publisher.discounts.usable.find_by_code(code))

    raise "Must set CSV_PATH" unless (csv_path = ENV['CSV_PATH']).present?
    raise "No readable file at '#{csv_path}'" unless File.readable?(csv_path)

    count = 0
    Consumer.transaction do
      FasterCSV.foreach(csv_path) do |row|
        unless (email = row[0]) =~ /\Aemail\z/i
          consumer = Consumer.build_unactivated(publisher, :email => email)
          consumer.signup_discount = discount
          consumer.save!
          count += 1
        end
      end
    end
    puts "Imported #{count} consumers"
  end

  desc "Send daily consumer counts email for PUBLISHING_GROUP_LABEL"
  task :send_daily_counts => :environment do
    raise "Must set PUBLISHING_GROUP_LABEL" unless label = ENV['PUBLISHING_GROUP_LABEL']
    raise "No publishing group with label" unless publishing_group = PublishingGroup.find_by_label(label)

    dates = 1.day.ago .. 0.days.ago
    PublishingGroupsMailer.deliver_consumer_counts(publishing_group, :date_range => dates)
  end

  desc "Finds invalid consumers and outputs consumer ids to a file"
  task :find_invalid_consumers => :environment do
    total_processed = 0
    file_path = File.expand_path("tmp/invalid_consumers_#{Time.zone.now.strftime("%Y%m%d")}", RAILS_ROOT)
    File.open(file_path, "w") do |file|
      Consumer.find_each do |consumer|
        if !consumer.valid?
          file << "#{consumer.publisher.label}, #{consumer.id}"
        end
        total_processed += 1
      end
    end
    puts "Total processed: #{total_processed}"
  end


  module CopySubscribersAndConsumers

    class << self
      def publisher_from_env!(env_key)
        raise "Must set #{env_key}" unless label = ENV[env_key]
        raise "Can't find publisher with label '#{label}'" unless publisher = Publisher.find_by_label(label)
        publisher
      end

      def new_subscriber_with_relevant_bits(src)
        dest = src.clone
        dest.created_at = nil
        dest.updated_at = nil
        dest.publisher = nil
        dest.daily_deal_categories.clear
        dest.subscription_locations.clear
        dest
      end

      def new_consumer_with_relevant_bits(src)
        dest = src.clone
        dest.created_at = nil
        dest.updated_at = nil
        dest.publisher = nil
        dest.signup_discount = nil
        dest.advertiser_signup = nil
        dest.company_id = nil
        dest.company_type = nil
        dest.referrer_code = nil
        dest.daily_deal_purchases.clear
        dest.credits.clear
        dest.click_counts.clear
        dest.discounts.clear
        dest.daily_deal_categories.clear
        dest
      end
    end

  end

  desc "Copies subscribers and consumers from one publisher to another, creating new subscribers and consumers."
  task :copy_consumers_and_subscribers => :environment do
    STDOUT.sync = true
    src_publisher = CopySubscribersAndConsumers.publisher_from_env!('SRC_PUBLISHER_LABEL')
    dest_publisher = CopySubscribersAndConsumers.publisher_from_env!('DEST_PUBLISHER_LABEL')
    subscriber_count = 0
    Subscriber.find_each(:conditions => ["publisher_id = ? and email is not NULL", src_publisher.id]) do |src_subscriber|
      dest_subscriber = CopySubscribersAndConsumers.new_subscriber_with_relevant_bits(src_subscriber)
      dest_subscriber.publisher = dest_publisher
      dest_subscriber.save!
      subscriber_count += 1
      print "." if subscriber_count % 25 == 0
    end
    puts "\nSubscribers done."
    consumer_count = 0
    Consumer.find_each(:conditions => ["publisher_id = ? and email is not NULL and activated_at is not NULL", src_publisher.id]) do |src_consumer|
      unless User.exists?(["publisher_id = ? and email = ?", dest_publisher.id, src_consumer.email])
        dest_customer = CopySubscribersAndConsumers.new_consumer_with_relevant_bits(src_consumer)
        dest_customer.publisher = dest_publisher
        dest_customer.save!
        consumer_count += 1
      end
      print "." if consumer_count % 25 == 0
    end
    puts "\nConsumers done."
    puts "Copied #{subscriber_count} subscribers and #{consumer_count} consumers."
  end

  desc "Pre-create consumers with a signup discount"
  task :create_with_discount => :environment do
    raise "Must set IN_FILE" unless in_file = ENV['IN_FILE']
    label = in_file.split(File::SEPARATOR).last.split('.').first
    publisher = Publisher.find_by_label(label) or raise "No publisher with label #{label.inspect}"
    signup_discount = publisher.signup_discount or raise "Publisher has no usable signup discount"

    create_consumer = lambda do |publisher, name, email, signup_discount|
      passwd = '16KSn0T2kcw7SkFT'
      consumer = publisher.consumers.find_by_email(email)
      consumer ||= publisher.consumers.build(
          :name => name,
          :email => email,
          :password => passwd,
          :password_confirmation => passwd,
          :need_setup => true,
          :agree_to_terms => true
      )
      consumer.signup_discount = signup_discount
      if consumer.save
        puts "Created or updated consumer #{name}, #{email}"
        consumer
      else
        puts "Consumer #{email}: #{consumer.errors.full_messages.join(', ')}"
        nil
      end
    end

    ouftile = "tmp/#{label}.created.csv"

    begin
      Consumer.transaction do
        FasterCSV.open(ouftile, "w", :row_sep => "\r\n") do |row_w|
          row_w << ["id", "full_name", "email", "url"]
          FasterCSV.foreach(in_file) do |row_r|
            if (consumer = create_consumer.call(publisher, 'Your Name', row_r[0], signup_discount))
              url = "http://#{publisher.daily_deal_host}/su/#{publisher.id}/#{consumer.perishable_token}"
              row_w << [consumer.id, consumer.name, consumer.email, url]
            end
          end
        end
      end
    rescue
      File.delete ouftile
      raise $!
    end
  end
end
