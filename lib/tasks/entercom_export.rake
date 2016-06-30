namespace :entercom_export do
  desc "requirements task"
  task :require => [:environment] do
    require 'rake'
    include ActionView::Helpers::NumberHelper
    require 'export/formatting_helper'
    include Export::FormattingHelper
  end
  # COMMON OPTIONS FOR THE TASKS IN THIS NAMESPACE
  # ENV[PUBLISHER_LABEL] = 'ocregister'
  # ENV[PUBLISHING_GROUP_LABEL] = 'freedom'
  # ENV[PUBLISHER_LABEL_QUERY] = ocreg (i.e. publisher.label LIKE '%ocreg%')  [some pubs are split off into markets so a single publisher label won't capture all the markets]
  # ENV[INCREMENT] = 0 (ALL DATA) || 1 (1 Day)
  
  desc "Generate batch-style consumers export dump to csv"
  task :generate_batch_consumer_export, [:publisher_label, :publishing_group_label, :increment, :publisher_label_query]  => [:environment, :require] do |task, args|
    args.with_defaults(
      :publisher_label => ENV['PUBLISHER_LABEL'],
      :publishing_group_label => ENV['PUBLISHING_GROUP_LABEL'],
      :publisher_label_query => ENV['PUBLISHER_LABEL_QUERY'], # i.e. 'oc%'
      :dry_run => (ENV['DRY_RUN'].present?) ? true : false,
      :increment => (ENV['INCREMENT'].present?) ? ENV['INCREMENT'].to_i : 1 ,   # use 0 for all-to-date
      :limit => (ENV['LIMIT'].present?) ? ENV['LIMIT'].to_i : 0 ,
      :start_date => ENV['START_DATE'],
      :end_date => ENV['END_DATE']
    )
    pg = (args.publishing_group_label.present?) ? PublishingGroup.find_by_label(args.publishing_group_label.to_s) : nil 
    
    conditions = Array.new
    conditions << "publishers.label = '#{args.publisher_label}'" if args.publisher_label.present?
    conditions << "publishers.label LIKE '%#{args.publisher_label_query}%'" if args.publisher_label_query.present?
    conditions << "publishing_groups.label = '#{args.publishing_group_label}'" if args.publishing_group_label.present?
    conditions << "(users.created_at > '#{args.increment.days.ago}' OR users.updated_at > '#{args.increment.days.ago}')" if args.increment.to_i > 0
    conditions << "(users.created_at > '#{args.start_date}' OR users.updated_at > '#{args.start_date}')" if args.start_date.present?
    conditions << "(users.created_at < '#{args.end_date}' OR users.updated_at > '#{args.end_date}')" if args.end_date.present?

    file_path = unique_file_path "CONSUMER-EXPORT-#{(pg.try(:label) || args.publisher_label).dup}" # have to dupe these otherwise we get frozen string issues
    # puts "Outputing batch to #{file_path}"
    header = ["Market", "Consumer ID", "Email", "First Name", "Last Name", "Agree to Terms", "Zip Code", "Facebook ID", "Timezone", "State", "Country Code", "Gender", "Credit Available"]
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      csv << header
      count = 0 
      
      sql = "SELECT users.id, COALESCE(NULLIF(publishers.market_name, ''), publishers.city) as market, users.first_name, users.last_name, users.email, 
      users.agree_to_terms, users.facebook_id, users.timezone, users.credit_available, users.gender, users.country_code, users.state, users.zip_code, users.updated_at
      FROM users
      LEFT JOIN publishers ON publishers.id = users.publisher_id
      LEFT JOIN publishing_groups ON publishers.publishing_group_id = publishing_groups.id
      WHERE 1=1"
      sql << " AND " << conditions.join(' AND ') if conditions.count
      sql << " ORDER BY users.created_at DESC"
      sql << " LIMIT #{args.limit}" if args.limit > 0
      
      # puts "USING SQL STATEMENT:\n"
      # puts sql
      ActiveRecord::Base.connection.select_all(sql).each do |con|
        csv << [con["market"],
                con["id"],
                con["email"],
                con["first_name"],
                con["last_name"],
                con["agree_to_terms"],
                con["zip_code"], 
                con["facebook_id"],
                con["timezone"],
                con["state"], 
                con["country_code"], 
                con["gender"],
                con["credit_available"]
                ]
                
        count += 1
        if count % 1000 == 0
          print count.to_s << "\t"
        end
      end
      if count == 0 
        puts "********* NO RECORDS FOUND *********"
      end 
    end
    upload_file_to_publisher(file_path, args.publisher_label || args.publishing_group_label) unless args.dry_run
  end
  
  desc "Generate batch style purchases export"
  task :generate_batch_purchase_export, [:publisher_label, :publishing_group_label, :increment] => [:environment, :require] do |task, args|
    args.with_defaults(
      :publisher_label => ENV['PUBLISHER_LABEL'],
      :publishing_group_label => ENV['PUBLISHING_GROUP_LABEL'],
      :publisher_label_query => ENV['PUBLISHER_LABEL_QUERY'], # i.e. 'oc%'
      :dry_run => (ENV['DRY_RUN'].present?) ? true : false,
      :increment => (ENV['INCREMENT'].present?) ? ENV['INCREMENT'].to_i : 1,   # use 0 for all-to-date
      :limit => (ENV['LIMIT'].present?) ? ENV['LIMIT'].to_i : 0 ,
      :start_date => ENV['START_DATE'],
      :end_date => ENV['END_DATE']
    )
    
    pg = (args.publishing_group_label.present?) ? PublishingGroup.find_by_label(args.publishing_group_label.to_s) : nil 

    conditions = Array.new
    conditions << "publishers.label = '#{args.publisher_label}'" if args.publisher_label.present?
    conditions << "publishers.label LIKE '%#{args.publisher_label_query}%'" if args.publisher_label_query.present?
    conditions << "publishing_groups.label = '#{args.publishing_group_label}'" if args.publishing_group_label.present?
    conditions << "ddp.created_at > '#{args.increment.days.ago}'" if args.increment.to_i > 0
    conditions << "ddp.created_at > '#{args.start_date}'" if args.start_date.present?
    conditions << "ddp.created_at < '#{args.end_date}'" if args.end_date.present?    

    file_path = unique_file_path "PURCHASES-EXPORT-#{(pg.try(:label) || args.publisher_label).dup}" # have to dupe these otherwise we get frozen string issues

    # puts "Outputing batch to #{file_path}"
    header = ["Market", "Purchase ID", "Daily Deal ID", "Listing ID", "Gross Price", "Consumer ID", "Purchase Email", "First Name", "Last Name", "Purchase Date", "Quantity", "Vouchers Per Quantity", "Refunded Date", "Status", "Discount Code", "Discount Amount","Credit Used","Redeemer Name/s", "Expires On"]
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      csv << header
      count = 0
      sql = "SELECT ddp.id, dd.id as 'daily_deal_id', con.email, dd.listing, adv.name, adv.id as advertiser_id, 
      COALESCE(NULLIF(publishers.market_name, ''), publishers.city) as market, ddp.payment_status, adv.name, ddp.created_at, dd.expires_on,
      ddp.refund_amount, ddp.quantity, ddp.gross_price, ddp.credit_used, ddp.executed_at, ddp.refunded_at, ddp.recipient_names,
      ddp.actual_purchase_price, ddp.gift, con.address_line_1, con.zip_code, ddp.consumer_id, con.email, con.first_name, con.last_name, dd.certificates_to_generate_per_unit_quantity,
      discounts.code as discount_code, discounts.amount as discount_value, ddp.credit_used
       FROM daily_deal_purchases ddp 
       LEFT JOIN daily_deals as dd ON ddp.daily_deal_id = dd.id
       LEFT OUTER JOIN daily_deal_translations dd_tr ON dd_tr.daily_deal_id = dd.id AND dd_tr.locale = 'en'
       LEFT OUTER JOIN discounts ON ddp.discount_id=discounts.id
       LEFT JOIN publishers ON dd.publisher_id = publishers.id
       LEFT JOIN publishing_groups ON publishers.publishing_group_id = publishing_groups.id 
       LEFT JOIN users con ON ddp.consumer_id = con.id
       LEFT JOIN advertisers ON dd.advertiser_id = advertisers.id
       LEFT OUTER JOIN advertiser_translations adv ON adv.advertiser_id = advertisers.id AND adv.locale = 'en'
       WHERE ddp.payment_status != 'pending'"
       sql << " AND " << conditions.join(' AND ') if conditions.count
       sql << " ORDER BY ddp.created_at DESC"
       sql << " LIMIT #{args.limit}" if args.limit > 0
       
      ActiveRecord::Base.connection.select_all(sql).each do |purchase|
        redeemers = deserialize(purchase['recipient_names']).compact.join(", ") if purchase['recipient_names']
        csv << [purchase['market'],
                purchase['id'],
                purchase['daily_deal_id'],
                purchase['listing'],
                purchase['gross_price'],
                purchase['consumer_id'],
                purchase['email'],
                purchase['first_name'],
                purchase['last_name'],
                formatted_date(purchase['executed_at']),
                purchase['quantity'],
                purchase['certificates_to_generate_per_unit_quantity'],
                formatted_date(purchase['refunded_at']),
                purchase['payment_status'],
                purchase['discount_code'],
                purchase['discount_value'],
                purchase['credit_used'],
                redeemers ||= "",
                formatted_date(purchase['expires_on'])]
          count += 1
          if count % 1000 == 0
            print count.to_s << "\t"
          end
      end
      if count == 0 
        puts "********* NO RECORDS FOUND *********"
      end      
    end
    upload_file_to_publisher(file_path, args.publisher_label || args.publishing_group_label) unless args.dry_run
  end 

  desc "Generate batch style purchases export"
  task :generate_batch_purchase_voucher_export, [:publisher_label, :publishing_group_label, :increment] => [:environment, :require] do |task, args|
    args.with_defaults(
      :publisher_label => ENV['PUBLISHER_LABEL'],
      :publishing_group_label => ENV['PUBLISHING_GROUP_LABEL'],
      :publisher_label_query => ENV['PUBLISHER_LABEL_QUERY'], # i.e. 'oc%'
      :dry_run => (ENV['DRY_RUN'].present?) ? true : false,
      :increment => (ENV['INCREMENT'].present?) ? ENV['INCREMENT'].to_i : 1,   # use 0 for all-to-date
      :limit => (ENV['LIMIT'].present?) ? ENV['LIMIT'].to_i : 0 ,
      :start_date => ENV['START_DATE'],
      :end_date => ENV['END_DATE']
    )
    
    pg = (args.publishing_group_label.present?) ? PublishingGroup.find_by_label(args.publishing_group_label.to_s) : nil 

    conditions = Array.new
    conditions << "publishers.label = '#{args.publisher_label}'" if args.publisher_label.present?
    conditions << "publishers.label LIKE '%#{args.publisher_label_query}%'" if args.publisher_label_query.present?
    conditions << "publishing_groups.label = '#{args.publishing_group_label}'" if args.publishing_group_label.present?
    conditions << "ddp.created_at > '#{args.increment.days.ago}'" if args.increment.to_i > 0
    conditions << "ddp.created_at > '#{args.start_date}'" if args.start_date.present?
    conditions << "ddp.created_at < '#{args.end_date}'" if args.end_date.present?    

    file_path = unique_file_path "PURCHASES-EXPORT-VOUCHERS-#{(pg.try(:label) || args.publisher_label).dup}" # have to dupe these otherwise we get frozen string issues

    # puts "Outputing batch to #{file_path}"
    header = ["Purchase ID", "Daily Deal ID","Consumer ID", "Serial Number", "Barcode", "Store ID"]
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      csv << header
      count = 0
      sql = "SELECT ddc.daily_deal_purchase_id, daily_deals.id as daily_deal_id, ddp.consumer_id, ddc.serial_number, ddc.bar_code, ddp.store_id
       FROM daily_deal_certificates ddc
       LEFT JOIN daily_deal_purchases ddp ON ddc.daily_deal_purchase_id=ddp.id
       LEFT JOIN daily_deals ON ddp.daily_deal_id=daily_deals.id
       LEFT JOIN publishers ON daily_deals.publisher_id=publishers.id
       LEFT JOIN publishing_groups ON publishing_groups.id=publishers.publishing_group_id 
       WHERE 1=1 "
       sql << " AND " << conditions.join(' AND ') if conditions.count
       sql << " ORDER BY ddp.created_at DESC"
       sql << " LIMIT #{args.limit}" if args.limit > 0
       
       puts "USING SQL STATEMENT:\n"
       puts sql
      
      ActiveRecord::Base.connection.select_all(sql).each do |voucher|
        csv << [voucher['daily_deal_purchase_id'], 
          voucher['daily_deal_id'], 
          voucher['consumer_id'],
          voucher['serial_number'],
          voucher['bar_code'],
          voucher['store_id']
          ]
          count += 1
          if count % 1000 == 0
            print count.to_s << "\t"
          end
      end
      if count == 0 
        puts "********* NO RECORDS FOUND *********"
      end      
    end
    upload_file_to_publisher(file_path, args.publisher_label || args.publishing_group_label) unless args.dry_run
  end 


  desc "Generate batch style merchant export dump to csv"
  task :generate_batch_merchant_export, [:publisher_label, :publishing_group_label, :increment] => [:environment, :require] do |task, args|
    args.with_defaults(
      :publisher_label => ENV['PUBLISHER_LABEL'],
      :publishing_group_label => ENV['PUBLISHING_GROUP_LABEL'],
      :publisher_label_query => ENV['PUBLISHER_LABEL_QUERY'], # i.e. 'oc%'
      :dry_run => (ENV['DRY_RUN'].present?) ? true : false,
      :increment => (ENV['INCREMENT'].present?) ? ENV['INCREMENT'].to_i : 1 , # use 0 for all-to-date, default is 1 Day
      :limit => (ENV['LIMIT'].present?) ? ENV['LIMIT'].to_i : 0 ,
      :start_date => ENV['START_DATE'],
      :end_date => ENV['END_DATE']
    )
    pg = (args.publishing_group_label.present?) ? PublishingGroup.find_by_label(args.publishing_group_label.to_s) : nil 

    conditions = Array.new
    conditions << "publishers.label = '#{args.publisher_label}'" if args.publisher_label.present?
    conditions << "publishers.label LIKE '%#{args.publisher_label_query}%'" if args.publisher_label_query.present?
    conditions << "publishing_groups.label = '#{args.publishing_group_label}'" if args.publishing_group_label.present?
    conditions << "advertisers.created_at > '#{args.increment.days.ago}'" if args.increment.to_i > 0
    conditions << "advertisers.created_at > '#{args.start_date}'" if args.start_date.present?
    conditions << "advertisers.created_at < '#{args.end_date}'" if args.end_date.present?

    file_path = unique_file_path "MERCHANT-EXPORT-#{(pg.try(:label)|| args.publisher_label).dup}" # have to dupe these otherwise we get frozen string issues
    # puts "Outputing batch to #{file_path}"
    header = ["Market", "Merchant ID", "Merchant Name", "Merchant Phone", "Merchant URL", "Merchant Email Address"]
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      csv << header
      count = 0
      sql = "SELECT advertisers.id as advertiser_id, advertiser_translations.name as advertiser_name, COALESCE(NULLIF(publishers.market_name, ''), publishers.city) AS market, advertisers.revenue_share_percentage, 
       advertisers.email_address, advertiser_translations.website_url, advertisers.call_phone_number
       FROM advertisers 
       LEFT JOIN user_companies uc ON uc.company_type = 'Advertiser' AND uc.company_id = advertisers.id
       LEFT JOIN advertiser_translations ON advertisers.id = advertiser_translations.advertiser_id AND advertiser_translations.locale = 'en'
       LEFT JOIN publishers ON advertisers.publisher_id = publishers.id
       LEFT JOIN publishing_groups ON publishers.publishing_group_id = publishing_groups.id
       WHERE "
       sql << conditions.join(' AND ') if conditions.count
       sql << " ORDER BY advertisers.created_at "
       sql << " LIMIT #{args.limit}" if args.limit > 0
       
       puts "USING SQL STATEMENT:\n"
           puts sql
     
       ActiveRecord::Base.connection.select_all(sql).each do |deal|
        csv << [deal['market'],
                deal['advertiser_id'],
                deal['advertiser_name'],
                format_phone(deal["call_phone_number"]),
                deal["website_url"],
                deal["email_address"]
                ]
        count += 1
        if count % 1000 == 0
          print count.to_s << "\t"
        end
      end
      if count == 0 
        puts "********* NO RECORDS FOUND *********"
      end 
    end  
    upload_file_to_publisher(file_path, args.publisher_label || args.publishing_group_label) unless args.dry_run
  end

  desc "Generate batch style deal export dump to csv"
  task :generate_batch_deal_export, [:publisher_label, :publishing_group_label, :increment] => [:environment, :require] do |task, args|
    args.with_defaults(
      :publisher_label => ENV['PUBLISHER_LABEL'],
      :publishing_group_label => ENV['PUBLISHING_GROUP_LABEL'],
      :publisher_label_query => ENV['PUBLISHER_LABEL_QUERY'], # i.e. 'oc%'
      :dry_run => (ENV['DRY_RUN'].present?) ? true : false,
      :increment => (ENV['INCREMENT'].present?) ? ENV['INCREMENT'].to_i : 1 , # use 0 for all-to-date, default is 1 Day
      :limit => (ENV['LIMIT'].present?) ? ENV['LIMIT'].to_i : 0 ,
      :start_date => ENV['START_DATE'],
      :end_date => ENV['END_DATE']
    )
    pg = (args.publishing_group_label.present?) ? PublishingGroup.find_by_label(args.publishing_group_label.to_s) : nil 

    conditions = Array.new
    conditions << "publishers.label = '#{args.publisher_label}'" if args.publisher_label.present?
    conditions << "publishers.label LIKE '%#{args.publisher_label_query}%'" if args.publisher_label_query.present?
    conditions << "publishing_groups.label = '#{args.publishing_group_label}'" if args.publishing_group_label.present?
    conditions << "daily_deals.created_at > '#{args.increment.days.ago}'" if args.increment.to_i > 0
    conditions << "daily_deals.created_at > '#{args.start_date}'" if args.start_date.present?
    conditions << "daily_deals.created_at < '#{args.end_date}'" if args.end_date.present?

    file_path = unique_file_path "DEAL-EXPORT-#{(pg.try(:label) || args.publisher_label).dup}" # have to dupe these otherwise we get frozen string issues
    # puts "Outputing batch to #{file_path}"
    header = ["Market", "Daily Deal ID", "Advertiser ID", "Price", "Value", "Start Date", "End Date", "Expiration Date", "Advertiser Name", "Category", "Value Proposition", "Voucher Headline", "Terms", "Fine Print", "Voucher Steps", "Vouchers Per Quantity"]
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      csv << header
      count = 0
      sql = "SELECT advertisers.id as advertiser_id, advertiser_translations.name as advertiser_name, COALESCE(NULLIF(publishers.market_name, ''), publishers.city) AS market, 
       daily_deals.start_at AS run_date, daily_deals.id as deal_id, ddt.value_proposition AS value_prop, daily_deals.price, advertisers.revenue_share_percentage, 
       daily_deals.account_executive, advertisers.email_address, daily_deals.hide_at, daily_deals.value, ddt.voucher_steps, daily_deals.voucher_headline, 
       daily_deals.business_fine_print, ddt.terms as terms, certificates_to_generate_per_unit_quantity, daily_deals.expires_on, cat.name as category
       FROM daily_deals
       LEFT JOIN advertisers ON advertisers.id = daily_deals.advertiser_id
       LEFT JOIN daily_deal_translations ddt ON daily_deals.id = ddt.daily_deal_id AND locale = 'en'
       LEFT JOIN daily_deal_categories cat ON daily_deals.analytics_category_id=cat.id
       LEFT JOIN user_companies uc ON uc.company_type = 'Advertiser' AND uc.company_id = advertisers.id
       LEFT JOIN advertiser_translations ON advertisers.id = advertiser_translations.advertiser_id AND advertiser_translations.locale = 'en'
       LEFT JOIN publishers ON advertisers.publisher_id = publishers.id
       LEFT JOIN publisher_translations ON publishers.id = publisher_translations.publisher_id
       LEFT JOIN publishing_groups ON publishers.publishing_group_id = publishing_groups.id
       WHERE 1=1 "
       sql << " AND " << conditions.join(' AND ') if conditions.count
       sql << " ORDER BY daily_deals.created_at  DESC"
       sql << " LIMIT #{args.limit}" if args.limit > 0
       
       # puts "USING SQL STATEMENT:\n"
       # puts sql
     
       ActiveRecord::Base.connection.select_all(sql).each do |deal|
        csv << [deal['market'], 
                deal['deal_id'],
                deal['advertiser_id'],
                deal['price'],
                deal['value'],
                formatted_date(deal['run_date']),
                formatted_date(deal['hide_at']),
                formatted_date(deal['expires_on']),
                deal['advertiser_name'],
                deal['category'],
                deal['value_prop'],
                deal['voucher_headline'],
                deal['terms'],
                deal['business_fine_print'] || "Distributor Gross Revenue Commission Percent",
                deal['voucher_steps'] || "1. Print your voucher | 2. Go to #{deal['advertiser_name']} | 3. Present voucher and valid ID upon arrival",
                deal['certificates_to_generate_per_unit_quantity']
                ]
        count += 1
        if count % 1000 == 0
          print count.to_s << "\t"
        end
      end
      if count == 0 
        puts "********* NO RECORDS FOUND *********"
      end 
    end  
    upload_file_to_publisher(file_path, args.publisher_label || args.publishing_group_label) unless args.dry_run
  end
  
  desc "Generate batch-style merchant location export dump to csv"
  task :generate_batch_merchant_store_export, [:publisher_label, :publishing_group_label, :increment] => [:environment, :require] do |task, args|
    args.with_defaults(
      :publisher_label => ENV['PUBLISHER_LABEL'],
      :publishing_group_label => ENV['PUBLISHING_GROUP_LABEL'],
      :publisher_label_query => ENV['PUBLISHER_LABEL_QUERY'], # i.e. 'oc%'
      :dry_run => (ENV['DRY_RUN'].present?) ? true : false,
      :increment => (ENV['INCREMENT'].present?) ? ENV['INCREMENT'].to_i : 1 , # use 0 for all-to-date, default is 1 Day
      :limit => (ENV['LIMIT'].present?) ? ENV['LIMIT'].to_i : 0 ,
      :start_date => ENV['START_DATE'],
      :end_date => ENV['END_DATE']
    )
    pg = (args.publishing_group_label.present?) ? PublishingGroup.find_by_label(args.publishing_group_label.to_s) : nil 

    conditions = Array.new
    conditions << "publishers.label = '#{args.publisher_label}'" if args.publisher_label.present?
    conditions << "publishers.label LIKE '%#{args.publisher_label_query}%'" if args.publisher_label_query.present?
    conditions << "publishing_groups.label = '#{args.publishing_group_label}'" if args.publishing_group_label.present?
    conditions << "advertisers.created_at > '#{args.increment.days.ago}'" if args.increment.to_i > 0
    conditions << "advertisers.created_at > '#{args.start_date}'" if args.start_date.present?
    conditions << "advertisers.created_at < '#{args.end_date}'" if args.end_date.present?

    file_path = unique_file_path "MERCHANT-STORES-EXPORT-#{(pg.try(:label) || args.publisher_label).dup}" # have to dupe these otherwise we get frozen string issues
    # puts "Outputing batch to #{file_path}"
    header = ["Merchant ID","Merchant Name", "Store ID", "Address Line 1", "Address Line 2", "City", "State", "Zip", "Phone Number"]
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      csv << header
      count = 0
      sql = "SELECT advertisers.id as advertiser_id, advertiser_translations.name as advertiser_name, stores.id as store_id, stores.address_line_1, stores.address_line_2, stores.city, stores.zip, stores.state, stores.phone_number
       FROM stores
       LEFT JOIN advertisers ON stores.advertiser_id = advertisers.id 
       LEFT JOIN user_companies uc ON uc.company_type = 'Advertiser' AND uc.company_id = advertisers.id
       LEFT JOIN advertiser_translations ON advertisers.id = advertiser_translations.advertiser_id AND advertiser_translations.locale = 'en'
       LEFT JOIN publishers ON advertisers.publisher_id = publishers.id
       LEFT JOIN publishing_groups ON publishers.publishing_group_id = publishing_groups.id
       WHERE 1=1 "
       sql << " AND " << conditions.join(' AND ') if conditions.count
       sql << " ORDER BY advertisers.created_at  DESC"
       sql << " LIMIT #{args.limit}" if args.limit > 0
       
       puts "USING SQL STATEMENT:\n"
       puts sql
     
       ActiveRecord::Base.connection.select_all(sql).each do |store|
        csv << [store['advertiser_id'],
                store['advertiser_name'],
                store['store_id'],
                store['address_line_1'],
                store['address_line_2'],
                store['city'],
                store['state'],
                store['zip'],
                format_phone(store['phone_number'])
                ]
        count += 1
        if count % 1000 == 0
          print count.to_s << "\t"
        end
      end
      if count == 0 
        puts "********* NO RECORDS FOUND *********"
      end 
    end  
    upload_file_to_publisher(file_path, args.publisher_label || args.publishing_group_label) unless args.dry_run
  end
end
def formatted_date(value)
  return "" if value.nil?
  date = DateTime.parse(value)
  date = date.to_date
  date.to_formatted_s("%m/%d/%Y") 
end
