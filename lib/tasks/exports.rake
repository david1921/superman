namespace :exports do
  task :require do
    require 'rake'
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

    file_path = unique_file_path "CONSUMER-EXPORT-#{(pg.label || args.publisher_label).dup}" # have to dupe these otherwise we get frozen string issues
    # puts "Outputing batch to #{file_path}"
    header = ["Customer ID", "Market", "First Name", "Last Name", "Email", "Address", "Address 2", "Zip Code", "Last Updated At"]
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      csv << header
      count = 0 
      
      sql = "SELECT users.id, COALESCE(NULLIF(publishers.market_name, ''), publishers.city) as market, users.first_name, users.last_name, users.email, users.address_line_1, users.address_line_2, users.zip_code, users.updated_at
      FROM users
      LEFT JOIN publishers ON publishers.id = users.publisher_id
      LEFT JOIN publishing_groups ON publishers.publishing_group_id = publishing_groups.id
      WHERE 1=1 "
      sql << " AND " << conditions.join(' AND ') if conditions.count
      sql << " ORDER BY users.created_at"
      
      # puts "USING SQL STATEMENT:\n"
      # puts sql
      ActiveRecord::Base.connection.select_all(sql).each do |con|
        csv << [con["id"],
                con["market"],
                con["first_name"],
                con["last_name"],
                con["email"],
                con["address_line_1"],
                con["address_line_2"],
                con["zip_code"],
                formatted_date(con["updated_at"]) ]
                
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

    file_path = unique_file_path "MERCHANT-EXPORT-#{(pg.label || args.publisher_label).dup}" # have to dupe these otherwise we get frozen string issues
    # puts "Outputing batch to #{file_path}"
    header = ["Deal Start Date", "Deal ID", "Market", "Advertiser ID", "Advertiser", "Value Prop", "Deal Price", "Advertiser Rev Share", 
      "Merchant Email Address", "Phone #", "Address", "City", "State", "Zip", "AE"]
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      csv << header
      count = 0
      sql = "SELECT advertisers.id as advertiser_id, advertiser_translations.name as advertiser_name, COALESCE(NULLIF(publishers.market_name, ''), publishers.city) AS market, 
       daily_deals.start_at AS run_date, daily_deals.id as deal_id, ddt.value_proposition AS value_prop, daily_deals.price, advertisers.revenue_share_percentage, 
       daily_deals.account_executive, advertisers.email_address
       FROM daily_deals
       LEFT JOIN advertisers ON advertisers.id = daily_deals.advertiser_id
       LEFT JOIN daily_deal_translations ddt ON daily_deals.id = ddt.daily_deal_id AND locale = 'en'
       LEFT JOIN user_companies uc ON uc.company_type = 'Advertiser' AND uc.company_id = advertisers.id
       LEFT JOIN advertiser_translations ON advertisers.id = advertiser_translations.advertiser_id AND advertiser_translations.locale = 'en'
       LEFT JOIN publishers ON advertisers.publisher_id = publishers.id
       LEFT JOIN publishing_groups ON publishers.publishing_group_id = publishing_groups.id
       WHERE 1=1 "
       sql << " AND " << conditions.join(' AND ') if conditions.count
       sql << " ORDER BY daily_deals.created_at"
       puts "USING SQL STATEMENT:\n"
       puts sql
       
       ActiveRecord::Base.connection.select_all(sql).each do |deal|
        store = Store.find(:first, :conditions => "stores.advertiser_id = #{deal['advertiser_id']}") 
        csv << [formatted_date(deal['run_date']),
                deal['deal_id'],
                deal['market'],
                deal['advertiser_id'],
                deal['advertiser_name'],
                deal['value_prop'],
                deal['price'],
                deal['revenue_share_percentage'],
                deal['email_address'],
                
                store.try(:phone_number),
                store.try(:address_line_1),
                store.try(:city),
                store.try(:state),
                store.try(:zip),

                deal['account_executive']  ]
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

    file_path = unique_file_path "PURCHASES-EXPORT-#{(pg.label || args.publisher_label).dup}" # have to dupe these otherwise we get frozen string issues

    # puts "Outputing batch to #{file_path}"
    header = ["Purchase ID", "Consumer", "Email","Deal ID", "Listing", "Merchant", "Merchant ID", "Market", "Payment Status", 
      "Created At", "Refund Amount", "Quantity", "Gross Price", "Credit Used", "Executed At", "Refunded At", "Recipient Names",
      "Actual Purchase Price", "Gift","Redeemed At", "Serial Number", "Billing Address", "Billing Zip Code"]
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      csv << header
      count = 0
      sql = "SELECT ddp.id as purchase_id, ddp.consumer_id as id, con.email, dd.id as deal_id, advertisers.listing, adv.name, adv.id as advertiser_id, 
      COALESCE(NULLIF(publishers.market_name, ''), publishers.city) as market, ddp.payment_status, adv.name, ddp.created_at,
      ddp.refund_amount, ddp.quantity, ddp.gross_price, ddp.credit_used, ddp.executed_at, ddp.refunded_at, ddp.recipient_names,
      ddp.actual_purchase_price, ddp.gift, con.address_line_1, con.zip_code 
       FROM daily_deal_purchases ddp 
       LEFT JOIN daily_deals as dd ON ddp.daily_deal_id = dd.id
       LEFT OUTER JOIN daily_deal_translations dd_tr ON dd_tr.daily_deal_id = dd.id AND dd_tr.locale = 'en'
       LEFT JOIN publishers ON dd.publisher_id = publishers.id
       LEFT JOIN publishing_groups ON publishers.publishing_group_id = publishing_groups.id 
       LEFT JOIN users con ON ddp.consumer_id = con.id
       LEFT JOIN advertisers ON dd.advertiser_id = advertisers.id
       LEFT OUTER JOIN advertiser_translations adv ON adv.advertiser_id = advertisers.id AND adv.locale = 'en'
       WHERE ddp.payment_status != 'pending' "
       sql << " AND " << conditions.join(' AND ') if conditions.count
       sql << " ORDER BY ddp.created_at"
       puts "USING SQL STATEMENT:\n"
       puts sql
      
      ActiveRecord::Base.connection.select_all(sql).each do |purchase|
        serials = ActiveRecord::Base.connection.select_values("SELECT serial_number FROM daily_deal_certificates WHERE daily_deal_purchase_id = #{purchase['id']}")
        redeemed_at = ActiveRecord::Base.connection.select_values("SELECT redeemed_at FROM daily_deal_certificates WHERE daily_deal_purchase_id = #{purchase['id']}")
        csv << [purchase['purchase_id'], 
                purchase['id'],
                purchase['email'],
                purchase['deal_id'],
                purchase['listing'],
                purchase['name'],
                purchase['advertiser_id'],
                purchase['market'],
                purchase['payment_status'],
                formatted_date(purchase['created_at']),
                purchase['refund_amount'],
                purchase['quantity'],
                purchase['gross_price'],
                purchase['credit_used'],
                formatted_date(purchase['executed_at']),
                formatted_date(purchase['refunded_at']),
                purchase['recipient_names'],
                purchase['actual_purchase_price'], 
                purchase['gift'], 
                redeemed_at.map { |s| formatted_date(s) }.join(', '),
                serials.join(', '),
                purchase['address_line_1'],
                purchase['zip_code'] ]
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

def unique_file_path(name = 'EXPORT', ext = ".csv")
  datestamp = (ENV['END_DATE'].present) ? ENV['END_DATE'] : Time.now.localtime.strftime("%Y%m%d-%H%M%S")  
  file_name = name << '-' << datestamp << ext
  File.expand_path(file_name, File.expand_path("tmp", Rails.root))
end

def upload_file_to_publisher(file_path, label)
  publishers_config = UploadConfig.new(:publishing_groups) 
  config = publishers_config.fetch!(label)
  if config.nil?
    publishers_config = UploadConfig.new(:publishers)
    config = publishers_config.fetch!(label)
  end
  Uploader.new(publishers_config).upload(label, file_path)  
end
