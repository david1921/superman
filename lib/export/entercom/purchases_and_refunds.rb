module Export
  
  module Entercom
    
    class PurchasesAndRefunds < ::Export::Entercom::Base
      
      include Export::PurchasesAndRefunds
      
      job_key "entercom:generate_purchases_and_refunds_csv"
      
      column "Type" => :tx_type
      column "Order ID" => :order_uuid
      column "Order Date" => lambda { |p|
        case p["tx_type"]
        when "P"
          p["executed_at"].present? ? format_datetime_as_yyyy_mm_dd(p["executed_at"]) : nil
        when "R"
          p["refunded_at"].present? ? format_datetime_as_yyyy_mm_dd(p["refunded_at"]) : nil
        else
          raise "expected tx_type for purchase ID (#{p['id']}) to be 'P' or 'R'. got: #{p['tx_type']}"
        end
      }
      column "Consumer ID" => :consumer_id 
      column "Member ID" => :remote_record_id
      column "Email" => :consumer_email 
      column "Market" => :publisher_label 
      column "Deal ID" => :daily_deal_id 
      column "Advertiser ID" => :advertiser_id 
      column "Advertiser" => :advertiser_name 
      column "Value Prop" => :value_proposition 
      column "Category" => :category_code 
      column "Price" => lambda { |p| "%.2f" % p["deal_price"] } 
      column "Deals Purchased" => lambda { |p|
        case p["tx_type"]
        when "P"
          p["quantity"]
        when "R"
          "N/A"
        else
          raise "expected tx_type for purchase ID (#{p['id']}) to be 'P' or 'R'. got: #{p['tx_type']}"
        end          
      }
      column "Order Value" => lambda { |p|
        case p["tx_type"]
        when "P"
          "%.2f" % p["actual_purchase_price"]
        when "R"
          "-%.2f" % p["refund_amount"]
        when nil
          nil
        else
          raise "expected tx_type for purchase ID (#{p['id']}) to be 'P' or 'R'. got: #{p['tx_type']}"
        end
      }
      column "Advertiser Rev Share" => lambda { |p| p["advertiser_revenue_share_percentage"].present? ? "%.2f" %  p["advertiser_revenue_share_percentage"] : nil } 
      column "Promo Code Name" => :promo_code 
      column "Promo Code Amount" => :promo_code_amount 
      column "Promo Code Expiry Date" => lambda { |p| p["promo_code_expiry"].present? ? format_datetime_as_yyyy_mm_dd(p["promo_code_expiry"]) : nil }
      column "Merchant Name" => nil 
      column "Merchant Zip" => :advertiser_zip

      class << self
        
        def omit_row_from_results?(row)
          row["tx_type"] != "P" || row["remote_record_id"].blank?
        end
        
      end

    end
    
  end
  
end