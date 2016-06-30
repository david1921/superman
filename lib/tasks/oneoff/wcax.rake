namespace :oneoff do
  namespace :wcax do

  desc "report for overcharging voucher shipping option"
  task :display_overcharged_for_shipping_options => :environment do
    pg        = PublishingGroup.find_by_label("wcax")
    file_path = ENV["FILE"]
    raise Exception, "unable to find wcax publishing group" unless pg
    raise Exception, "please supply a FILE" unless file_path
    header = ['publisher','purchase uuid','email','name','difference']
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      csv << header
      pg.publishers.each do |publisher|
        publisher.daily_deal_purchases.find_in_batches(:batch_size => 100) do |batch|
          batch.each do |purchase|
            if purchase.voucher_shipping_amount && purchase.voucher_shipping_amount > 0
              total_on_certificates = purchase.daily_deal_certificates.sum(:actual_purchase_price)
              if total_on_certificates > purchase.actual_purchase_price && purchase.consumer.present?
                csv << [publisher.label, purchase.uuid, purchase.consumer.email, purchase.consumer.name, total_on_certificates - purchase.actual_purchase_price]
              end
            end
          end
        end
      end
    end
  end

  desc "import consumers for wcax publishers" 
  task :import_existing_consumers => :environment do

    canada_provinces = ["QC", "ON", "YT"]
    us = Country.find_by_code("US")
    ca = Country.find_by_code("CA")

    ["wcax-adirondacks", "wcax-vermont"].each do |label|
      puts "----- importing consumers for: #{label}"
      filename = "#{Rails.root}/lib/tasks/oneoff/data/#{label}.csv"
      publisher = Publisher.find_by_label(label)
      unless publisher.countries.include?(us) and publisher.countries.include?(ca)
        publisher.countries << us unless publisher.countries.include?(us)
        publisher.countries << ca unless publisher.countries.include?(ca)
        publisher.save
      end
      Time.zone = publisher.time_zone

      total = 0
      dups  = 0
      start_time = Time.now
      if File.exists?(filename)
        FasterCSV.foreach(filename) do |row|
          unless row[0] =~ /UserID/
            total += 1
            login           = row[0]
            first_name      = row[1]
            middle_initial  = row[2]
            last_name       = row[3]
            email_address   = row[4]
            age             = row[5]
            gender          = row[6]
            phone           = row[7]
            address_1       = row[8]
            address_2       = row[9]
            city            = row[10]
            state           = row[11]
            region          = row[12]
            postal_code     = row[13]
            birth_month     = row[14]
            birth_day       = row[15]
            birth_year      = row[16]
            register_at     = row[25]
            
            if publisher.publishing_group.consumers.find_by_email(email_address).present?
              dups += 1
              next
            end

            attributes = { :email => email_address,
                           :first_name => first_name,
                           :last_name => last_name,
                           :force_password_reset => true,
                           :password => "wcaximport",
                           :password_confirmation => "wcaximport",
                           :agree_to_terms => true,
                           :birth_year => birth_year }

            attributes.merge!(:country_code => "CA") if canada_provinces.include?(state)

            if gender == 'MALE'
              gender = 'M' 
            elsif gender == 'FEMALE'
              gender = 'F' 
            else
              gender = ''
            end
            attributes.merge!(:gender => gender)

            if address_1 && city && state && postal_code
              postal_code = postal_code.length == 4 ? "0#{postal_code}" : postal_code
              attributes.merge!( :address_line_1 => address_1,
                                 :address_line_2 => address_2,
                                 :billing_city => city,
                                 :state => state,
                                 :zip_code => postal_code )
            end
            consumer = Consumer.new(attributes)
            consumer.publisher_id = publisher.id
            register_at = Time.zone.parse(register_at)
            consumer.created_at = register_at
            consumer.activated_at = register_at
            unless consumer.save
              puts "invalid consumer: #{consumer.email} - #{consumer.errors.full_messages}"
            end
          end
        end
        puts "    total: #{total}"
        puts "    duplicates: #{dups}"
        puts "    finished in: #{Time.now - start_time} ms"
      else
        puts "unable to find file: #{filename}" 
      end
    end

    exit if ENV["SKIP_CREDITS"]

    publishing_group = PublishingGroup.find_by_label("wcax")
    total = 0
    applied = 0
    already_has_credit = 0
    credit_file = "#{Rails.root}/lib/tasks/oneoff/data/wcax-credits.csv"
    puts "----- applying credits"
    FasterCSV.foreach(credit_file) do |row|
      unless row[0] =~ /FirstName/
        total += 1
        email_address = row[2]
        credit        = row[3]
        credit.gsub!("$", "")
        consumer = publishing_group.consumers.find_by_email(email_address)
        if consumer && consumer.credits.empty?
          unless consumer.credits.create(:amount => credit)
            puts "    UNABLE TO CREDIT FOR: #{email_address}"
          else
            applied += 1
          end
        else
          if consumer && consumer.credits.empty?
            already_has_credit += 1
          else
            puts "       NOT FOUND: #{email_address}"
          end
        end
      end
    end
    puts "    total: #{total}"
    puts "    applied: #{applied}"
    puts "    skipped: #{already_has_credit}"

  end
  
  desc "fix wcax download_url due to a redirect they added"
  task :fix_download_url => :environment do
     purchase_ids = OffPlatformDailyDealCertificate.connection.select_values("SELECT purchases.id
       FROM off_platform_daily_deal_certificates purchases
        INNER JOIN users consumer ON consumer.id = purchases.consumer_id
        INNER JOIN publishers ON consumer.publisher_id = publishers.id
       WHERE publishers.label = 'wcax-sevendays'")
      puts OffPlatformDailyDealCertificate.connection.update_sql("UPDATE off_platform_daily_deal_certificates
       SET off_platform_daily_deal_certificates.download_url = REPLACE(off_platform_daily_deal_certificates.download_url, 'wcax.upickem.net', 'affiliates.upickem.net') WHERE off_platform_daily_deal_certificates.id IN (#{purchase_ids.join(',')})").to_s + " records changed."
     
     
  end

  end
end
