class GroucherImport
  def self.users(file_path, dry_run=false)

    raise "File #{file_path} with the users to import does not exist." unless File.exists?(file_path)

    puts "Importing users from #{file_path}."

    total = 0
    dups  = 0
    start_time = Time.now

    FasterCSV.foreach(file_path) do |row|
      unless row[0] =~ /ID/
        login       = row[0]
        first_name  = row[1]
        last_name   = row[2]
        email       = row[3]
        password    = row[4]
        register_at = row[5]
        city        = row[6]

        case city
        when 'Fox Cities'
          publisher = Publisher.find_by_label('grouchercom-foxcities')
        when 'Green Bay'
          publisher = Publisher.find_by_label('grouchercom-greenbay')
        else
          next
        end

        raise "Publisher for city #{city} does not exist." if publisher.nil?

        state = "WI"
        country = Country.find_by_code("US")

        if publisher.publishing_group.consumers.find_by_email(email).present?
          puts "Duplicate email: #{email}."
          dups += 1
          next
        end

        attributes = { :email      => email,
                       :first_name => first_name,
                       :last_name  => last_name,
                       :force_password_reset  => true,
                       :password              => "123456",
                       :password_confirmation => "123456",
                       :agree_to_terms        => true,
                       :state                 => state,
                       :country               => country
        }

        register_at =  Time.zone.parse(register_at)

        consumer = Consumer.new(attributes)
        consumer.publisher_id = publisher.id
        consumer.created_at   = register_at
        consumer.activated_at = register_at

        if dry_run
          if consumer.valid?
            total += 1
          else
            puts "DRY_RUN: Consumer #{consumer.email}. Errors on validation: #{consumer.error.full_messages}."
          end
        else
          if consumer.save
            total += 1
          else
            puts "Invalid consumer: #{consumer.email} - Errors on validation: #{consumer.errors.full_messages}"
          end
        end
      end
    end
    puts "   Total: #{total}"
    puts "   Duplicates: #{dups}"
    puts "   Finished in: #{Time.now - start_time} ms"
  end

  def self.vouchers(file_path, vouchers_path, dry_run=false)

    raise "File #{file_path} does not exist." unless File.exists?(file_path)

    s3_credentials = YAML::load(File.open("#{Rails.root}/config/paperclip_s3.yml"))

    total = 0
    start_time = Time.now

    FasterCSV.foreach(file_path, :headers => true) do |row|
      begin
        unless row[0] =~ /ID/
          city               = row[0]
          groucher_title     = row[1]
          expires_date       = row[7]
          puchase_id         = row[8]
          customer_name      = row[9]
          email              = row[10]
          phone              = row[11]
          coupon_unique_id   = row[12]
          dt_created         = row[13]
          dt_claimed         = row[14]
          qty                = row[15]
          transaction_status = row[16]

          case city
          when 'Fox Cities'
            publisher = Publisher.find_by_label('grouchercom-foxcities')
          when 'Green Bay'
            publisher = Publisher.find_by_label('grouchercom-greenbay')
          else
            puts 'It did not find the publisher for city #{city}.'
            next
          end

          voucher_filename   = "#{vouchers_path}/#{coupon_unique_id}.pdf"
          unless File.exists?(voucher_filename)
            puts "Error: Voucher #{voucher_filename} not found."
            next
          end

          consumer =  publisher.publishing_group.consumers.find_by_email(email)
          if consumer.nil?
            puts "Error: Consumer with email #{email} not found for the voucher #{coupon_unique_id}."
            next
          end

          redeemer_first_name = customer_name.split(',')[1].strip
          redeemer_last_name  = customer_name.split(',')[0].strip

          if dry_run
            puts "DRY_RUN: Consumer #{consumer.email} with voucher #{coupon_unique_id}"
            puts "DRY_RUN: File #{coupon_unique_id}.pdf does not exist in our server. We are not going to be able to upload it to S3." unless File.exists?(voucher_filename)
            puts "DRY_RUN: File #{coupon_unique_id}.pdf already exists in S3." if AWS::S3::S3Object.exists?("#{coupon_unique_id}.pdf", 'groucher.vouchers.analoganalytics.com')
          else

            if File.exists?(voucher_filename)
              voucher = consumer.off_platform_daily_deal_certificates.build(
                  :executed_at                => dt_created,
                  :expires_on                 => expires_date,
                  :line_item_name             => groucher_title,
                  :quantity_excluding_refunds => qty,
                  :redeemer_names             => "#{redeemer_first_name} #{redeemer_last_name}",
                  :redeemed_at                => dt_claimed,
                  :redeemed                   => dt_claimed.present?
              )
              voucher.voucher_pdf = File.open(voucher_filename)
              if voucher.save
                puts "It saved voucher #{voucher_filename}."
              else
                puts "Voucher for #{voucher_filename} was not able to be saved. Errors: #{voucher.errors.full_message}"
              end
            else
              puts "File #{coupon_unique_id}.pdf does not exist in our server. We are not able to upload it to S3 or create the voucher in our system."
            end

            total =+ 1

            puts "Imported voucher #{coupon_unique_id}."
          end #dry_run
        end #unless
      rescue Exception => e
        puts "Exception: #{e}: #{voucher_filename} #{total}"
        puts row
      end
    end # FasterCSV
    puts "Imported #{total} vouchers."
  end
end
