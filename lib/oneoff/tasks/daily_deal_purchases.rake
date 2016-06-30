namespace :oneoff do

  namespace :daily_deal_purchases do

    desc "Update refund amounts on daily deal purchase refunds (queries Braintree)"
    task :update_refund_amount => :environment do
      DailyDealPurchases::Refunds.update_refund_amounts!
    end

    desc %{Update the braintree_transaction_amount on refunded transactions, to be \
           the original purchase amount (queries Braintree)}
    task :restore_braintree_transaction_amounts_on_refunds => :environment do
      DailyDealPurchases::Refunds.restore_braintree_transaction_amounts!
    end

    desc "Fix the gross and actual prices whose amounts were off due to a bug in how " +
             "gross and actual prices were updated"
    task :fix_prices => :environment do
      dry_run = ENV['DRY_RUN'].present?

      daily_deal_purchases = DailyDealPurchase.find_by_sql %Q{
        SELECT ddp.*
        FROM daily_deal_purchases ddp INNER JOIN daily_deal_payments ddpa
        ON ddp.id = ddpa.daily_deal_purchase_id
        WHERE ddp.actual_purchase_price != ddpa.amount
      }

      puts "found #{daily_deal_purchases.size} purchases where actual_purchase_price != payment amount"

      daily_deal_purchases.each do |ddp|
        old_actual = ddp.actual_purchase_price
        old_gross = ddp.gross_price

        ddp.send :set_gross_price!
        ddp.send :set_actual_purchase_price!

        new_actual = ddp.actual_purchase_price
        new_gross = ddp.gross_price

        puts "Updating DailyDealPurchase (#{ddp.id}): gross: #{old_gross} => #{new_gross}. actual: #{old_actual} => #{new_actual}"
        if dry_run
          puts "*** dry run, not updating ***"
        else
          ddp.save!
          puts "updated"
        end
      end
    end
    
    desc "Send unsent certificate email for COUNT [5] purchases executed within last HOURS [24] hours"
    task :send_unsent_certificates => :environment do
      count = ENV['COUNT'] || "5"
      raise "COUNT must be a positive integer" unless (count = count.to_i rescue nil) && count > 0
      hours = ENV['HOURS'] || "24"
      raise "HOURS must be a positive numeric" unless (hours = hours.to_f rescue nil) && hours > 0
      
      sent = DailyDealPurchase.send_unsent_certificate_email(count, Time.zone.now - hours.hours) do |ddp|
        puts "DDP #{ddp.id}, executed at #{ddp.executed_at}, certificate email sent at #{ddp.certificate_email_sent_at}"
        sleep 1
      end
      puts "Sent #{sent} emails"
    end

    desc "Export Hearst-Seattle PI magazine purchases with recipient shipping address info \
      (basically, the daily deal purchases report with shipping address info added, grouped by advertiser)"
    task :seattlepi_magazine_purchases do
      include Analog::DateHelper
      include ActionView::Helpers::NumberHelper

      dates = date_range '2011-06-15', '2011-06-20'

      columns = [
          "Purchaser Name",
          "Recipient Name",
          "Redeemed On",
          "Redeemed At",
          "Serial Number",
          "Deal",
          "Value",
          "Price",
          "Purchase Price",
          "Purchase Date",
          'Address line 1',
          'Address line 2',
          'City',
          'State',
          'Zip code'
      ]

      {
          'Esquire' => 26412,
          'Popular Mechanics' => 26413,
          'Car and Driver' => 26414,
          'Road & Track' => 26415,
          'Cycle World' => 26416
      }.each do |name, id|
        advertiser = Advertiser.find(id)

        FasterCSV.open("tmp/#{name.gsub(/\s/, '').underscore}.csv", "w") do |csv|
          csv << columns

          daily_deal_certificates = advertiser.purchased_daily_deal_certificates_for_period(dates, advertiser)
          daily_deal_certificates.each do |daily_deal_certificate|
            daily_deal_purchase = daily_deal_certificate.daily_deal_purchase
            recipient = daily_deal_purchase.recipients.select{|r| r.name == daily_deal_certificate.redeemer_name}.first ||
                daily_deal_purchase.recipients.first

            csv << [
                daily_deal_certificate.consumer_name,
                daily_deal_certificate.redeemer_name,
                daily_deal_certificate.redeemed_at.present? ? daily_deal_certificate.redeemed_at.to_date : "",
                daily_deal_certificate.store_name,
                daily_deal_certificate.serial_number,
                daily_deal_certificate.value_proposition,
                number_to_currency(daily_deal_certificate.value, :unit => daily_deal_certificate.currency_symbol),
                number_to_currency(daily_deal_certificate.price, :unit => daily_deal_certificate.currency_symbol),
                number_to_currency(daily_deal_certificate.actual_purchase_price, :unit => daily_deal_certificate.currency_symbol),
                daily_deal_certificate.executed_at.to_date,
                recipient && recipient.name,
                recipient && recipient.address_line_1,
                recipient && recipient.address_line_2,
                recipient && recipient.city,
                recipient && recipient.state,
                recipient && recipient.zip
            ]
          end
        end
      end
    end
  end
end
