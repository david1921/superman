require 'set'

ENTERCOM_PUBS = {
  "entercom-austin" => "A",
  "entercom-sanfrancisco" => "BA",
  "entercom-indianapolis" => "I",
  "entercom-kansascity" => "KC",
  "entercom-memphis" => "MEM",
  "entercom-piedmont" => "PT",
  "entercom-seattle" => "SE",
  "entercom-springfield" => "SP",
  "entercom-worcester" => "WO", 
  "entercom-denver" => "DVR", 
  "entercom-rochester" => "RCH"
}

namespace :oneoff do

  namespace :entercom do
    CHARSET = %w{ 2 3 4 6 7 9 A C D E F G H J K L M N P Q R T V W X Y Z}

    desc "Copy Heart of Florida consumer accounts to Ocala"
    task :copy_hof_users_to_ocala do
      Oneoff::Entercom.copy_hof_consumers_to_ocala!
    end

    desc "Create deal categories for entercomnew publisher group"
    task :setup_entercom_deal_categories do
      pg = PublishingGroup.find_by_label("entercomnew")
      (1..10).each do |i|
        pg.daily_deal_categories.find_or_create_by_name("Deal #{i}")
      end
      pg.daily_deal_categories.find_or_create_by_name("Syndicated")
    end
    
    desc "Generate 300K unique discount codes that start with NEPERK"
    task :generate_neperk_discount_codes do
      used = Set.new
      300_000.times do |num|
        begin
          code = Array.new(6) { CHARSET.rand }.join
        end while used.member?(code)
        puts "NEPERK#{code}"
        used << code
      end
    end

    desc "Generate 300K unique discount codes that start with SPERK"
    task :generate_sperk_discount_codes do
      used = Set.new
      300_000.times do |num|
        begin
          code = Array.new(6) { CHARSET.rand }.join
        end while used.member?(code)
        puts "SPERK#{code}"
        used << code
      end
    end

    desc "Generate unique COUNT discount codes for Entercom"
    task :generate_entercom_discount_codes do
      count = ENV["COUNT"].to_i
      index = 0
      Publisher.all(:conditions => ["label in (?)", ENTERCOM_PUBS.keys]).each do |publisher|
        puts publisher.label
        used = Set.new
        count.times do |num|
          begin
            code = Array.new(6) { CHARSET.rand }.join
          end while used.member?(code)
          used << code

          index = index + 1
          if index % 10000 == 0
            puts
            puts index.to_s
            STDOUT.flush
          elsif index % 100 == 0
            putc "."
            STDOUT.flush
          end
        end
        File.open("#{Rails.root}/tmp/#{publisher.label}.csv", "w") do |file|
          used.each do |code|
            file.puts "#{ENTERCOM_PUBS[publisher.label]}#{code}"
          end
        end
      end
      puts
    end

    desc "Import discount codes for Entercom"
    task :import_entercom_codes do
      Publisher.transaction do
        discounts = 0
        Publisher.all(:conditions => ["label in (?)", ENTERCOM_PUBS.keys]).each do |publisher|
          if File.exists?("#{Rails.root}/tmp/#{publisher.label}.csv")
          puts "Reading: " + publisher.label
          File.readlines("#{Rails.root}/tmp/#{publisher.label}.csv").map(&:strip).each do |code|
            begin
              uuid = UUIDTools::UUID.random_create.to_s
              Discount.connection.insert("INSERT INTO `discounts`
              (`created_at`, `code`, `quantity`, `uuid`, `updated_at`, `deleted_at`,
              `amount`, `first_usable_at`, `usable_at_checkout`,`lock_version`, `type`,
              `last_usable_at`, `publisher_id`, `usable_only_once`)
              VALUES('2011-09-20 15:13:33', '#{code}', NULL, '#{uuid}',
              '2011-09-20 15:13:33', NULL, 5.0, '2011-09-16 12:00:00', 1, 0, NULL, '10-23-2011 05:00:00', #{publisher.id}, true)")
              discounts += 1
              if discounts % 10000 == 0
                puts discounts
              end
            rescue => e
              puts e
            end
          end
          else
            puts publisher.label + ".csv does not exists in RAILS.root/tmp, skipping"
            end # fi file exists
        end
        puts "#{discounts} Discounts created"
      end
    end

    desc "Import discount codes for NE perks"
    task :import_neperk_discount_codes do
      file_name = ENV['IMPORT_FILE']
      raise "Must specify IMPORT_FILE" unless file_name
      publisher = Publisher.find_by_label('entercom-newengland')
      file      = File.join(File.dirname(__FILE__),"data",file_name)
      discounts = 0
      File.readlines(file).map(&:strip).each do |code|
        begin
          uuid = UUIDTools::UUID.random_create.to_s
          Discount.connection.insert("INSERT INTO `discounts`
          (`created_at`, `code`, `quantity`, `uuid`, `updated_at`, `deleted_at`,
          `amount`, `first_usable_at`, `usable_at_checkout`,`lock_version`, `type`,
          `last_usable_at`, `publisher_id`)
          VALUES('2011-04-19 16:13:33', '#{code}', NULL, '#{uuid}',
          '2011-04-19 16:13:33', NULL, 10.0, NULL, 1, 0, NULL, NULL, 250)")
          discounts += 1
          if discounts % 10000 == 0
            puts discounts
          end
        rescue => e
          puts e
        end
      end
      puts "#{discounts} Discounts created"
    end

    desc "Import discount codes for Seattle perks"
    task :import_sperk_discount_codes do
      file_name = ENV['IMPORT_FILE']
      raise "Must specify IMPORT_FILE" unless file_name
      publisher = Publisher.find_by_label('entercom-seattle')
      file      = File.join(File.dirname(__FILE__),"data",file_name)
      discounts = 0
      File.readlines(file).map(&:strip).each do |code|
        begin
          uuid = UUIDTools::UUID.random_create.to_s
          Discount.connection.insert("INSERT INTO `discounts`
          (`created_at`, `code`, `quantity`, `uuid`, `updated_at`, `deleted_at`,
          `amount`, `first_usable_at`, `usable_at_checkout`,`lock_version`, `type`,
          `last_usable_at`, `publisher_id`)
          VALUES('2011-04-19 16:13:33', '#{code}', NULL, '#{uuid}',
          '2011-04-19 16:13:33', NULL, 10.0, NULL, 1, 0, NULL, NULL, 283)")
          discounts += 1
          if discounts % 10000 == 0
            puts discounts
          end
        rescue => e
          puts e
        end
      end
      puts "#{discounts} Discounts created"
    end

    desc "Create Entercom holiday promotion"
    task :create_entercom_holiday_promotion do
      puts "Creating the Entercom Holiday Promotion"
      entercom_pg = PublishingGroup.find_by_label("entercomnew")
      raise "Could not find publishing group 'entercomnew'" if entercom_pg.nil?
      promotion = Promotion.find_or_initialize_by_publishing_group_id(entercom_pg.id)
      raise "This is meant to be a one-time-only task. A promotion was found for this publishing group." unless promotion.new_record?
      promotion.start_at = Time.zone.parse('2011-11-28 03:00:00')         # 11/28 at 6:00 am EST
      promotion.end_at = Time.zone.parse('2011-12-24 20:59:00')           # 12/24 at 11:59 pm EST
      promotion.codes_expire_at = Time.zone.parse('2011-12-25 23:59:99')  # 12/25 at 11:59 pm PST
      promotion.amount = '10.00'
      promotion.code_prefix = 'HD1211-'
      promotion.save!
      puts "Saved: #{promotion.inspect}"
      puts "Done"
    end

    desc "Generate discounts for consumers that missed discounts during the time a defect was in production. Output in a format usable by AMs to do a Silverpop mailing"
    task :create_and_notify_consumers_eligible_for_discounts do
      puts "Creating discounts and emailing consumers that missed out on their promotion discount"

      # Joins and conditions to grab all purchases in the window where we know discounts were not being generated
      joins = "inner join users on daily_deal_purchases.consumer_id = users.id"
      conditions = "daily_deal_purchases.executed_at between '2011-12-01 23:17:12' and '2011-12-05 20:48:44' and (daily_deal_purchases.payment_status = 'captured' or daily_deal_purchases.payment_status = 'refunded') and users.publisher_id in(select id from publishers where publishing_group_id = 24)"

      purchase_count = DailyDealPurchase.count(:joins => joins, :conditions => conditions)
      puts "Total purchase count in the window: #{purchase_count}"

      per_batch = 500
      total_batches = (purchase_count / per_batch) + 1
      batch_count = 1
      eligible_count = 0

      DailyDealPurchase.find_in_batches(:batch_size => per_batch, :joins => joins, :conditions => conditions) do |purchases|
        puts "Processing batch #{batch_count} of #{total_batches}"
        
        purchases.each do |purchase|
          if purchase.eligible_for_promotion_discount?
            discount = purchase.create_promotion_discount
            eligible_count += 1
            puts "#{purchase.consumer.email}, #{discount.code}"
          end
        end

        batch_count += 1
      end

      puts eligible_count
      puts "Done"
    end
  end

end
