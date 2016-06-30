namespace :oneoff do
  namespace :discounts do

    desc "Create promo codes for the given publisher from a CSV file."
    task :create_promo_codes => :environment do
      raise "PUBLISHER_ID is required" unless publisher_id = ENV["PUBLISHER_ID"]
      publisher = Publisher.find(publisher_id)

      Publisher.transaction do
        discounts = 0
        if File.exists?("#{Rails.root}/tmp/#{publisher.label}.csv")
          puts "Reading: " + publisher.label
          File.readlines("#{Rails.root}/tmp/#{publisher.label}.csv").map(&:strip).each do |code|
            begin
              uuid = UUIDTools::UUID.random_create.to_s
              Discount.connection.insert("INSERT INTO `discounts`
              (`created_at`, `code`, `quantity`, `uuid`, `updated_at`, `deleted_at`,
              `amount`, `first_usable_at`, `usable_at_checkout`,`lock_version`, `type`,
              `last_usable_at`, `publisher_id`, `usable_only_once`)
              VALUES('2012-02-21 15:57:00', '#{code}', NULL, '#{uuid}',
              '2012-02-21 15:57:00', NULL, 10.0, '2012-02-21 00:00:00', 1, 0, NULL, NULL, #{publisher.id}, true)")
              discounts += 1
              if discounts % 10000 == 0
                puts discounts
              end
            rescue => e
              puts e
            end
          end

          puts "#{discounts} Discounts created"
        else
          puts publisher.label + ".csv does not exists in RAILS.root/tmp, skipping"
        end
      end
    end

    desc "Create randomly generated promo codes in batches with different due dates. Requires a PUBLISHER_ID and a CODE_COUNT. The rest is hard-coded."
    task :create_promo_codes_with_multiple_use_by_dates do
      raise "PUBLISHER_ID is required" unless publisher_id = ENV["PUBLISHER_ID"]
      raise "CODE_COUNT is required" unless code_count = ENV["CODE_COUNT"]

      publisher_id = publisher_id.to_i
      code_count = code_count.to_i
      code_prefix = "RA"
      dates_for_batches = [Date.parse('31-03-2012'), Date.parse('30-04-2012'), Date.parse('31-5-2012')]
      number_of_batches = dates_for_batches.size

      pub_used_codes = Set.new
      batch_size = code_count / number_of_batches
      puts "publisher_id #{publisher_id} #{code_count} #{batch_size} #{code_count % number_of_batches}"

      number_of_batches.times do |batch_index|
        use_by_date = dates_for_batches[batch_index]
        remainder = (batch_index == (number_of_batches - 1)) ? (code_count % number_of_batches) : 0

        (batch_size + remainder).times do |code_index|
          create_randomly_generated_code(code_prefix, pub_used_codes, publisher_id, use_by_date)
        end
      end
    end

    desc "Create randomly generated promo codes with the supplied use-by date Requires a PUBLISHER_ID, CODE_COUNT, and USE_BY_DATE. The rest is hard-coded."
    task :create_promo_codes_with_use_by_dates do
      raise "PUBLISHER_ID is required" unless publisher_id = ENV["PUBLISHER_ID"]
      raise "CODE_COUNT is required" unless code_count = ENV["CODE_COUNT"]
      raise "USE_BY_DATE is required" unless use_by_date = ENV["USE_BY_DATE"]
      
      publisher_id = publisher_id.to_i
      code_count = code_count.to_i
      code_prefix = ENV['PREFIX']
      code_amount = ENV['AMOUNT']
      pub_used_codes = Set.new

      code_count.times do
        create_randomly_generated_code(code_prefix, pub_used_codes, publisher_id, use_by_date, code_amount)
      end
    end
    
    desc "Do create promo code creation for entercom"
    task :crazy_and_complex_discount_codes do
      raise "PUBLISHING_GROUP_LABEL, COUNT, AMOUNT, USE_BY_DATE, PREFIX all required" if ENV['PUBLISHING_GROUP_LABEL'].blank? || ENV['USE_BY_DATE'].blank? || ENV['PREFIX'].blank?
        
      PublishingGroup.transaction do
        pg = PublishingGroup.find_by_label(ENV['PUBLISHING_GROUP_LABEL'])
        [{:count => 98, :amount => 10},{:count => 56, :amount => 25},{:count => 14, :amount => 50}, {:count => 14, :amount => 100}].each do |run|
          codes = []
          pg.publishers.each do |pub|
            if codes.empty?
              run[:count].times do
                codes << generate_unique_code(pub.id, Set.new, ENV['PREFIX'])
              end
            end
            codes.each do |code|
              uuid = UUIDTools::UUID.random_create.to_s
              insert_discount({:uuid => uuid, :use_by_date => ENV['USE_BY_DATE'],
                               :publisher_id => pub.id, :code => code, :amount => run[:amount]})
            end
          end
        end
        raise ActiveRecord::Rollback if ENV['DRY_RUN'].present?
      end
    end


    def create_randomly_generated_code(code_prefix, pub_used_codes, publisher_id, use_by_date, amount)
      uuid = UUIDTools::UUID.random_create.to_s
      code = generate_unique_code(publisher_id, pub_used_codes, code_prefix)
      insert_discount({:uuid => uuid, :use_by_date => use_by_date,
                       :publisher_id => publisher_id, :code => code, :amount => amount})

      puts "#{publisher_id}, #{code}, #{use_by_date}"
      code
    end

    def insert_discount(options)
      insert_params = {:amount => 10.0}.merge(options)
      raise "Missing insert parameters from #{insert_params}" if (insert_params[:code].blank? || insert_params[:uuid].blank? ||
          insert_params[:use_by_date].blank? || insert_params[:publisher_id].blank?)

      Discount.connection.insert("INSERT INTO `discounts`
                            (`created_at`, `code`, `quantity`, `uuid`, `updated_at`, `deleted_at`,
                            `amount`, `first_usable_at`, `usable_at_checkout`,`lock_version`, `type`,
                            `last_usable_at`, `publisher_id`, `usable_only_once`)
                            VALUES('2012-02-20 00:00:33', '#{insert_params[:code]}', NULL, '#{insert_params[:uuid]}',
                            '2012-02-20 00:00:33', NULL, #{insert_params[:amount]}, '2012-03-01 00:00:00', 1, 0, NULL,
                            '#{insert_params[:use_by_date]}', #{insert_params[:publisher_id]}, true)")
                            
       # puts "#{insert_params[:code]} added for #{insert_params[:publisher_id]} for #{insert_params[:amount]}"
    end

    def generate_unique_code(publisher_id, used_codes, code_prefix = "")
      begin
        code = code_prefix + (Array.new(6) { CHARSET.rand }.join)
        is_taken = (Discount.connection.execute("select id from discounts where code = '#{code}' and publisher_id = #{publisher_id};").num_rows == 0) ? false :true
      end while (used_codes.member?(code) && is_taken)

      used_codes << code
      code
    end

  end
end
