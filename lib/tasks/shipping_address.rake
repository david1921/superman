require 'rake'
namespace :shipping_address do
  desc "Generate Shipping Address OUTFILE as XLS for PUBLISHER_LABEL/PUBLISHING_GROUP_LABEL"
  task :generate_shipping_address_xls, [:publisher_label, :publishing_group_label, :outfile]  => :environment do |task, args|
    args.with_defaults(
      :publisher_label => ENV['PUBLISHER_LABEL'],
      :publishing_group_label => ENV['PUBLISHING_GROUP_LABEL'],
      :increment => (ENV['INCREMENT'].present? && ENV['INCREMENT'].to_i > 0) ? ENV['INCREMENT'].to_i : 1 ,   # use 0 for all-to-date
      :start_date => ENV['START_DATE'],
      :end_date => ENV['END_DATE'],
      :outfile => ENV['OUTFILE']
    )
    pg = (args.publishing_group_label.present?) ? PublishingGroup.find_by_label(args.publishing_group_label.to_s) : nil 
    
    conditions = Array.new
    conditions << "publishers.label = '#{args.publisher_label}'" if args.publisher_label.present?
    conditions << "publishing_groups.label = '#{args.publishing_group_label}'" if args.publishing_group_label.present?
    conditions << "users.created_at > '#{args.increment.days.ago}'" if args.increment.to_i > 0
    conditions << "users.created_at > '#{args.start_date}'" if args.start_date.present?
    conditions << "users.created_at < '#{args.end_date}'" if args.end_date.present?
    
    file_path = unique_file_path "CONSUMER-EXPORT-#{(pg.label || args.publisher_label).dup}" # have to dupe these otherwise we get frozen string issues
    
    header = ['daily deal id','email','name','address line 1','address linen 2','city','state','zip','date']
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      csv << header
      count = 0 
      
      sql = "
      DROP TABLE IF EXISTS shipping_address;
      CREATE TABLE shipping_address AS
      SELECT daily_deal_purchases.daily_deal_id, users.email, users.name, addresses.address_line_1, addresses.address_line_2, addresses.city, addresses.state, addresses.zip,$
      daily_deal_purchases.executed_at
      FROM daily_deal_purchases INNER JOIN daily_deals ON daily_deal_purchases.daily_deal_id = daily_deals.id
                LEFT JOIN addresses ON addresses.id = daily_deal_purchases.mailing_address_id
              LEFT JOIN users ON users.id = daily_deal_purchases.consumer_id
              LEFT JOIN publishers ON publishers.id= daily_deals.publisher_id
              WHERE daily_deal_purchases.payment_status IN ('captured','refunded') AND daily_deal_purchases.fulfillment_method = 'ship'"
      sql << " AND " << conditions.join(' AND ') if conditions.count
      sql << " ORDER BY users.created_at"
      ActiveRecord::Base.connection.exec_query(sql)

      sql = "UPDATE shipping_address SET executed_at=CONVERT_TZ(executed_at,'GMT','US/Eastern') WHERE time_zone='Eastern Time (US & Canada)';
      UPDATE shipping_address SET executed_at=CONVERT_TZ(executed_at,'GMT','US/Central') WHERE time_zone='Central Time (US & Canada)';
      UPDATE shipping_address SET executed_at=CONVERT_TZ(executed_at,'GMT','US/Mountain') WHERE time_zone='Mountain Time (US & Canada)';
      UPDATE shipping_address SET executed_at=CONVERT_TZ(executed_at,'GMT','US/Pacific') WHERE time_zone='Pacific Time (US & Canada)';
      UPDATE shipping_address SET executed_at=CONVERT_TZ(executed_at,'GMT','US/Arizona') WHERE time_zone='Arizona';
      UPDATE shipping_address SET executed_at=CONVERT_TZ(executed_at,'GMT','US/Alaska') WHERE time_zone='Alaska';
      UPDATE shipping_address SET executed_at=CONVERT_TZ(executed_at,'GMT','US/Eastern') WHERE time_zone='Indiana (East)';
      UPDATE shipping_address SET executed_at=CONVERT_TZ(executed_at,'GMT','US/Hawaii') WHERE time_zone='Hawaii';
      UPDATE shipping_address SET executed_at=CONVERT_TZ(executed_at,'GMT','Europe/London') WHERE time_zone='London';
      # Edinburgh time zone will be the same as GMT time zone
      #UPDATE shipping_address SET execute_at=CONVERT_TZ(execute_at,'GMT','GMT') WHERE time_zone='Edinburgh';
      UPDATE shipping_address SET executed_at=CONVERT_TZ(executed_at,'+00:00','+13:00') WHERE time_zone='Nuku\'alofa';
      UPDATE shipping_address SET executed_at=CONVERT_TZ(executed_at,'+00:00','+2:00') WHERE time_zone='Athens'"
      ActiveRecord::Base.connection.exec_query(sql)

      sql = "SELECT daily_deal_id, email, name, address_line_1, address_line_2, city, state, zip, DATE(executed_at) AS date_exec
      FROM shipping_address"
      ActiveRecord::Base.connection.select_all(sql).each do |con|
        csv << [con["daily_deal_id"],
                con["email"],
                con["name"],
                con["address_line_1"],
                con["address_line_2"],
                con["city"],
                con["state"],
                con["zip"],
                con["date_exec"] ]
        count += 1
        if count % 1000 == 0
          print count.to_s << "\t"
        end
      end
      if count > 0 
        # puts count.to_s << " records total."
      else
        #  Keep this output as it is the only one that actually shoulds really happen daily too much
        puts "********* NO RECORDS FOUND *********"
      end 
    end
  
  end
end

def unique_file_path(name = 'EXPORT', ext = ".csv")  
  file_name = name << '-' << Time.now.localtime.strftime("%Y%m%d-%H%M%S") << ext
  File.expand_path(file_name, File.expand_path("tmp", Rails.root))
end