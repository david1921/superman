namespace :mobile do
  desc "Get a csv of the purchases made an iphone"
  task :purchases_as_csv => :environment do |task, args|
    args.with_defaults(
      :publisher_label => ENV['PUBLISHER_LABEL'],
      :publishing_group_label => ENV['PUBLISHING_GROUP_LABEL'],
      :publisher_label_query => ENV['PUBLISHER_LABEL_QUERY'], # i.e. 'oc%'
      :dry_run => (ENV['DRY_RUN'].present?) ? true : false,
      :increment => (ENV['INCREMENT'].present? && ENV['INCREMENT'].to_i > 0) ? ENV['INCREMENT'].to_i : 1 ,   # use 0 for all-to-date
      :start_date => ENV['START_DATE'],
      :end_date => ENV['END_DATE']
    )
    pg = (args.publishing_group_label.present?) ? PublishingGroup.find_by_label(args.publishing_group_label.to_s) : nil 
    
    conditions = Array.new
    conditions << "publishers.label = '#{args.publisher_label}'" if args.publisher_label.present?
    conditions << "publishers.label LIKE '%#{args.publisher_label_query}%'" if args.publisher_label_query.present?
    conditions << "publishing_groups.label = '#{args.publishing_group_label}'" if args.publishing_group_label.present?
    conditions << "(users.created_at > '#{args.increment.days.ago}' OR users.updated_at > '#{args.increment.days.ago}')" if args.increment.to_i > 0
    conditions << "(users.created_at > '#{args.start_date}' OR users.updated_at > '#{args.increment.days.ago}')" if args.start_date.present?
    conditions << "(users.created_at < '#{args.end_date}' OR users.updated_at > '#{args.increment.days.ago}')" if args.end_date.present?

    file_path = unique_file_path "MOBILE-PURCHASES-#{(pg.try(:label) || args.publisher_label).dup}"    
    
    header = ["Publisher Label", "Purchase Timestamp", "Actual Purchase Price","First Name", "Last Name", "Email", "Device"]
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      csv << header
      count = 0 
      
      sql = "SELECT publishers.label, daily_deal_purchases.executed_at, daily_deal_purchases.actual_purchase_price, users.first_name, users.last_name, users.email, daily_deal_purchases.device
      FROM daily_deal_purchases
      INNER JOIN users ON daily_deal_purchases.consumer_id = users.id
      INNER JOIN publishers ON users.publisher_id = publishers.id
      LEFT JOIN publishing_groups ON publishing_groups.id = publishers.publishing_group_id
      WHERE daily_deal_purchases.device IS NOT NULL AND  daily_deal_purchases.executed_at IS NOT NULL"
      sql << " AND " << conditions.join(' AND ') if conditions.count
      sql << " ORDER BY daily_deal_purchases.created_at"
      
      ActiveRecord::Base.connection.select_all(sql).each do |con|
        csv << [con["label"],
                con["executed_at"],
                con["actual_purchase_price"],
                con["first_name"],
                con["last_name"],
                con["email"],
                con["device"] ]
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

# Helpers
def unique_file_path(name = 'EXPORT', ext = ".csv")  
  file_name = name << '-' << Time.now.localtime.strftime("%Y%m%d-%H%M%S") << ext
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