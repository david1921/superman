namespace :oneoff do
  namespace :daily_deal_certificate do

    desc "Updates each certificate's actual purchase price based on associated daily_deal_purchase fields"
    task :update_actual_purchase_price => :environment do
      update_certificates_purchase_price_for_one_certificate
      update_certificates_purchase_price_for_multiple_certs_no_discounts
      update_certificates_purchase_price_for_partial_refunds
    end

    desc "Update certificates to reflect voucher shipping amount in actual price"
    task :update_for_voucher_shipping => :environment do
      #
      # Finding all purchases that have incorrect voucher totals because of a voucher
      # shipping bug and update their vouchers to correctly sum to the
      # actual purchase price of the purchase by adding the shipping amount to
      # the first voucher.
      #
      # BUG: https://www.pivotaltracker.com/story/show/23764633
      #

      daily_deal_purchases = DailyDealPurchase.find_by_sql <<-DDPS
        select distinct(ddp.id), sum(ddc.actual_purchase_price) as ddc_price, ddp.actual_purchase_price, ddp.voucher_shipping_amount
          from daily_deal_certificates as ddc, daily_deal_purchases as ddp, daily_deals as dd, publishers as p 
            where ddc.daily_deal_purchase_id = ddp.id 
              and ddp.daily_deal_id = dd.id 
              and dd.publisher_id = p.id 
              and p.allow_voucher_shipping = 1 
              and ddp.fulfillment_method = 'ship' 
              and ddp.voucher_shipping_amount > 0
            group by ddp.id
            having ddc_price = (ddp.actual_purchase_price - ddp.voucher_shipping_amount);
      DDPS
      puts "Found #{daily_deal_purchases.size} purchases to update"
      daily_deal_purchases.each do |ddp|
        cert = DailyDealCertificate.first(:conditions => ["daily_deal_purchase_id = ?", ddp.id ])
        cert.update_attribute(:actual_purchase_price, cert.actual_purchase_price + ddp.voucher_shipping_amount)
        puts "Updated cert ##{cert.id}"
      end
      puts "Done"
    end

  end

  def update_certificates_purchase_price_for_one_certificate
    count = DailyDealCertificate.count_by_sql <<-COUNT
        select count(*) from daily_deal_certificates inner join daily_deal_purchases
          on daily_deal_purchase_id = daily_deal_purchases.id
          where daily_deal_purchases.quantity = 1;
    COUNT
    puts "Updating daily_deal_certificate#actual_purchase_price for #{count} daily_deal_certificates (daily_deal_purchase#quantity == 1)..."
    ActiveRecord::Base.connection.execute <<-UPDATE
      update daily_deal_certificates, daily_deal_purchases
        set daily_deal_certificates.actual_purchase_price = daily_deal_purchases.actual_purchase_price
        where daily_deal_purchase_id = daily_deal_purchases.id and daily_deal_purchases.quantity = 1;
    UPDATE
  end

  def update_certificates_purchase_price_for_multiple_certs_no_discounts
    count = DailyDealCertificate.count_by_sql <<-COUNT
      select count(*) from daily_deal_certificates inner join daily_deal_purchases
        on daily_deal_purchase_id = daily_deal_purchases.id
        where daily_deal_purchases.quantity > 1 and daily_deal_purchases.gross_price = daily_deal_purchases.actual_purchase_price;
    COUNT
    puts "Updating daily_deal_certificate#actual_purchase_price for #{count} daily_deal_certificates (daily_deal_purchase#quantity > 1)..."
    ActiveRecord::Base.connection.execute <<-UPDATE
      update daily_deal_certificates, daily_deal_purchases
        set daily_deal_certificates.actual_purchase_price = daily_deal_purchases.actual_purchase_price / daily_deal_purchases.quantity
        where daily_deal_purchase_id = daily_deal_purchases.id
                and daily_deal_purchases.quantity > 1
                and daily_deal_purchases.gross_price = daily_deal_purchases.actual_purchase_price;
    UPDATE
  end

  def update_certificates_purchase_price_for_partial_refunds
    count = DailyDealCertificate.count_by_sql <<-COUNT
      select count(*) from daily_deal_certificates inner join daily_deal_purchases
        on daily_deal_purchase_id = daily_deal_purchases.id
        where daily_deal_purchases.quantity > 1 and daily_deal_purchases.gross_price != daily_deal_purchases.actual_purchase_price;
    COUNT
    puts "Updating daily_deal_certificate#actual_purchase_price for #{count} daily_deal_certificates (partial refunds - slower)..."
    total_certs_updated = 0
    DailyDealPurchase.all(:conditions => ["quantity > 1 and gross_price != actual_purchase_price"]).each do |purchase|
      running_total = 0
      purchase.daily_deal_certificates.each do |cert|
        amount_left = [purchase.actual_purchase_price - running_total, 0].max
        cert_purchase_price = [purchase.daily_deal.price, amount_left].min
        cert.actual_purchase_price = cert_purchase_price
        cert.save!
        running_total += cert_purchase_price
        total_certs_updated += 1
        print "." if total_certs_updated % 100 == 0
      end
    end
    puts "\nCerts updated from partial refunds: #{total_certs_updated}"
  end


end
