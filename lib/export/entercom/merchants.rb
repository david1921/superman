module Export
  
  module Entercom
    
    class Merchants < Export::Entercom::Base
    
      job_key "entercom:generate_merchants_csv"
      
      column "Deal Start Date" => lambda { |row| format_datetime_as_yyyy_mm_dd(row["start_at"]) }
      column "Deal ID" => :deal_id
      column "Market" => :market
      column "Advertiser ID" => :advertiser_id
      column "Advertiser" => :advertiser_name
      column "Value Prop" => :value_proposition
      column "Advertiser Rev Share" => lambda { |row|
        row["advertiser_revenue_share_percentage"].present? ? "%.2f" %  row["advertiser_revenue_share_percentage"] : nil
      }
      column "Merchant Contact" => :merchant_contact_name
      column "Merchant Email Address" => :email_address
      column "Phone #" => :phone_number
      column "Address 1" => :address_line_1
      column "Address 2" => :address_line_2
      column "City" => :city
      column "State" => :state
      column "Zip" => :zip
      column "AE" => :account_executive
      
      class << self

        def get_export_filename
          Rails.root.join("tmp", "entercom-merchants-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}.csv").to_s
        end

        def get_csv_rows_in_batches(increment_start_at = nil, increment_end_at = nil, batch_size = 10_000, &batch_handler)
          raise ArgumentError, "must be called with a block" unless block_given?
          
          offset = 0
          loop do
            DailyDealPurchase.benchmark("Export::Entercom::Merchants.get_csv_rows") do
              result = ActiveRecord::Base.connection.execute(%Q{
                SELECT dd.start_at, dd.id AS deal_id, p.label AS market, dd.advertiser_id,
                       at.name AS advertiser_name, ddt.value_proposition, dd.advertiser_revenue_share_percentage,
                       a.merchant_contact_name, a.email_address, s.phone_number, s.address_line_1,
                       s.address_line_2, s.city, s.state, s.zip,  dd.account_executive
                FROM daily_deals dd
                  INNER JOIN publishers p ON dd.publisher_id = p.id
                  INNER JOIN publishing_groups pg ON p.publishing_group_id = pg.id
                  INNER JOIN daily_deal_translations ddt ON ddt.daily_deal_id = dd.id
                  INNER JOIN advertisers a ON dd.advertiser_id = a.id
                  INNER JOIN advertiser_translations at ON at.advertiser_id = a.id
                  LEFT JOIN stores s ON a.id = s.advertiser_id
                WHERE dd.source_id IS NULL
                  AND pg.label = 'entercomnew'
                ORDER BY dd.start_at ASC, s.id ASC LIMIT %d OFFSET %d
              } % [sql_quote(batch_size), sql_quote(offset)])
              
              current_batch_size = result.num_rows
              batch_handler.call(result) if current_batch_size > 0
              
              raise StopIteration if current_batch_size == 0 || current_batch_size < batch_size
              
              offset += batch_size
            end
          end
        end

      end
      
    end
    
  end
  
end