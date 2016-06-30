module Export  
  module SanctionScreening
    module Consumers
      JOB_KEY = "sanction_screening:export_and_uploaded_encrypted_consumer_file"

      class << self

        def export_encrypt_and_upload!(passphrase, recipient, sanction_date)
          Job.run!(JOB_KEY, :incremental => false) do
            filename = export_to_pipe_delimited_file!(sanction_date)
            Export::SanctionScreening::Upload.encrypt_upload_and_remove!(filename, passphrase, recipient)
          end
        end

        def export_to_pipe_delimited_file!(sanction_date)
          daily_deal_purchases = get_daily_deal_purchases(sanction_date)
          gift_certificates = get_gift_certificates(sanction_date)
                    
          filename = get_export_filename
          FasterCSV.open(filename, "w", :col_sep => "|") do |csv| 
            csv << [
              "analog_id", "first_name", "last_name", "billing_address_1", "billing_address_2",
              "billing_city", "billing_state", "billing_zip", "cardholder_name", "credit_card_bin",
              "credit_card_last_4", "purchase_date"
            ]

            purchases = daily_deal_purchases + gift_certificates
            purchases = purchases.sort_by do |purch|
              if purch.respond_to?(:executed_at)
                purch.executed_at
              else
                purch.paypal_payment_date
              end
            end
            
            purchases.each do |p|
              row = row_for(p)
              if row
                csv << row
              end
            end
          end
          
          filename
        end
      
        private

        def get_daily_deal_purchases(sanction_date)
          DailyDealPurchase.executed_after_or_on(sanction_date).
                              with_billed_payment_status.
                              with_positive_actual_purchase_price.
                              all(
                                :include => :daily_deal_payment,
                                :order => "executed_at ASC"
                              )
        end

        def get_gift_certificates(sanction_date)
          PurchasedGiftCertificate.all(
            :conditions => ["paypal_payment_date >= ? AND paypal_payment_gross > 0", sanction_date],
            :order => "paypal_payment_date ASC"
          )
        end
      
        def get_export_filename
          filename_timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
          Rails.root.join("tmp", "sanction_screening_consumers_#{filename_timestamp}.txt").to_s
        end
        
        def row_for(purchase)
          case purchase
          when DailyDealPurchase
            return nil if purchase.daily_deal_payment.nil? || purchase.consumer.nil?
            [ 
              purchase.consumer.id, 
              purchase.daily_deal_payment.billing_first_name, 
              purchase.daily_deal_payment.billing_last_name, 
              purchase.daily_deal_payment.billing_address_line_1, 
              purchase.daily_deal_payment.billing_address_line_2, 
              purchase.daily_deal_payment.billing_city,
              purchase.daily_deal_payment.billing_state,
              purchase.daily_deal_payment.payer_postal_code,
              purchase.daily_deal_payment.name_on_card,
              purchase.daily_deal_payment.credit_card_bin,
              purchase.daily_deal_payment.credit_card_last_4,
              purchase.daily_deal_payment.payment_at.to_date.to_s(:db)
            ]
          when PurchasedGiftCertificate
            [ 
              purchase.paypal_payer_email, 
              purchase.paypal_first_name, 
              purchase.paypal_last_name, 
              purchase.paypal_address_street, 
              nil, 
              purchase.paypal_address_city,
              purchase.paypal_address_state,
              purchase.paypal_address_zip,
              purchase.paypal_address_name,
              nil,
              nil,
              purchase.paypal_payment_date.to_date.to_s(:db)
            ]
          end
        end
      end
    end
  end
end
