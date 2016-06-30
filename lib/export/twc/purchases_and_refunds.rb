module Export
  
  module Twc
    
    class PurchasesAndRefunds < Export::Twc::Base
      
      include Export::PurchasesAndRefunds
      
      job_key "twc:generate_purchases_and_refunds_csv"
      
      column "first_name" => :first_name
      column "last_name" => :last_name
      column "e_mail" => :consumer_email
      column "zip_code" => :consumer_zip_code
      column "value_proposition" => :value_proposition
      column "price" => :deal_price
      column "advertiser_name" => :advertiser_name
      column "date_and_time_of_purchase" => lambda { |r| format_datetime_as_iso8601(r["executed_at"]) }
      column "number_of_deals_purchased" => :quantity
      column "for_friend" => :gift
      column "for_self" => lambda { |r| r["gift"] == "1" ? "0" : "1" }
    
      class << self
        
        def omit_row_from_results?(row)
          row["tx_type"] != "P"
        end
        
      end
      
    end
    
  end
  
end