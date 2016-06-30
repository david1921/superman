module Doubletake
  
  def self.generate_recipients_and_serials_csv!
    csv_filename = Rails.root.join("tmp", "dt-recipients-and-serials-#{Time.now.to_s(:timestamp)}.xls")
    csv_options = { :force_quotes => true, :col_sep => "\t" }
    
    vouchers = DailyDealCertificate.find_by_sql <<-FIND_DT_VOUCHERS

    SELECT u.name AS purchaser_name, ddc.redeemer_name, ddc.serial_number
    FROM daily_deal_certificates ddc
      INNER JOIN daily_deal_purchases ddp ON ddc.daily_deal_purchase_id = ddp.id
      INNER JOIN users u ON ddp.consumer_id = u.id
      INNER JOIN daily_deals dd ON ddp.daily_deal_id = dd.id
      INNER JOIN advertisers a ON dd.advertiser_id = a.id
      INNER JOIN publishers p ON a.publisher_id = p.id
    WHERE p.label = 'doubletakedeals'

FIND_DT_VOUCHERS

    FasterCSV.open(csv_filename, "w", csv_options) do |csv_file|
      csv_file << ["Purchaser Name", "Recipient Name", "Serial Number"]
      vouchers.each do |v|
        csv_file << [v.purchaser_name, v.redeemer_name, v.serial_number]
      end
    end
    
    csv_filename
  end
  
  def self.generate_purchases_and_refunds_csv!
    csv_filename = Rails.root.join("tmp", "dt-purchases-#{Time.now.to_s(:timestamp)}.xls")
    csv_options = { :force_quotes => true, :col_sep => "\t" }

    purchases = DailyDealPurchase.find_by_sql <<-DT_PURCHASES

    SELECT dd.listing AS deal_listing, ddp.uuid, u.name AS purchaser_name,
           ddc.redeemer_name AS redeemer_name, ddc.status AS voucher_status,
           s.listing AS store_listing, ddc.serial_number AS serial_number
    FROM daily_deals dd
      INNER JOIN daily_deal_purchases ddp on ddp.daily_deal_id = dd.id
      INNER JOIN users u ON ddp.consumer_id = u.id
      INNER JOIN daily_deal_certificates ddc ON ddc.daily_deal_purchase_id = ddp.id
      LEFT JOIN stores s ON ddp.store_id = s.id
    WHERE dd.source_id IN (SELECT dd.id
                           FROM daily_deals dd
                             INNER JOIN advertisers a ON dd.advertiser_id = a.id
                             INNER JOIN publishers p ON a.publisher_id = p.id
                           WHERE p.label = 'doubletakedeals')
    ORDER BY dd.listing, ddp.uuid

    DT_PURCHASES

    FasterCSV.open(csv_filename, "w", csv_options) do |csv_file|
      csv_file << [
        "Deal Listing", "Deal UUID", "Purchaser Name", "Redeemer Name", "Voucher Status",
        "Store Listing", "Serial Number"]
      purchases.each do |p|
        csv_file << [
          p.deal_listing, p.uuid, p.purchaser_name, p.redeemer_name,
          p.voucher_status, p.store_listing, p.serial_number]
      end
    end

    csv_filename
    
  end
  
end