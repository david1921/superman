require File.dirname(__FILE__) + "/../../test_helper"

class PaypalPaymentTest < ActiveSupport::TestCase

	context "PaypalPayment#find_or_create_by_paypal_notification" do 
		
		should "raise error with nil paypal notification" do
			assert_raise RuntimeError do
				PaypalPayment.find_or_create_by_paypal_notification(nil)
			end
		end

		context "with pending payment" do

			setup do				
				@existing_payment = Factory(:pending_paypal_payment)	
				@params = {
					"invoice" => @existing_payment.analog_purchase_id
				}		
			end

			should "return the existing payment" do
				assert_equal @existing_payment, PaypalPayment.find_or_create_by_paypal_notification(@params)
			end

		end

		context "with no existing payment" do

			setup do
				@daily_deal_purchase = Factory(:pending_daily_deal_purchase)
				@params = {
					"tax"=>"0.00", 
					"payment_status"=>"Completed", 
					"receiver_email"=>"kathleen.winer@analoganalytics.com", 
					"invoice"=>@daily_deal_purchase.analog_purchase_id, 
					"business"=>"kathleen.winer@analoganalytics.com", 
					"quantity"=>"2", 
					"receiver_id"=>"6VN93T9HSVN58", 
					"transaction_subject"=>"DAILY_DEAL_PURCHASE", 
					"payment_gross"=>"", 
					"action"=>"create", 
					"notify_version"=>"3.4", 
					"payment_fee"=>"", 
					"mc_currency"=>"USD", 
					"verify_sign"=>"AzWBgkJyNs4bRAbA7zP6u4.qAeAZATEAcmh.rb.sxfZpSPbg2rJoChux", 
					"txn_id"=>"6Y043376TC0857932", 
					"item_name"=>@daily_deal_purchase.value_proposition,
					"shipping"=>"0.00", 
					"txn_type"=>"web_accept", 
					"mc_gross"=>@daily_deal_purchase.total_price.to_s, 
					"payer_id"=>"TBRUS3LAELPPS", 
					"charset"=>"windows-1252", 
					"mc_fee"=>"0.00", 
					"settle_currency"=>"USD", 
					"last_name"=>"KOKKINIAS", 
					"controller"=>"paypal_notifications", 
					"exchange_rate"=>"1.0", 
					"custom"=>"DAILY_DEAL_PURCHASE", 
					"payer_status"=>"verified", 
					"protection_eligibility"=>"Ineligible", 
					"payment_date"=>@daily_deal_purchase.created_at.to_s, 
					"payer_email"=>"customer@gmail.com", 
					"residence_country"=>"US", 
					"handling_amount"=>"0.00", 
					"ipn_track_id"=>"8fce1b19bba4", 
					"settle_amount"=>@daily_deal_purchase.total_price.to_s, 
					"first_name"=>"THEODOROS", 
					"payment_type"=>"instant", 
					"item_number"=>@daily_deal_purchase.daily_deal.item_code					
				}
			end

			context "with total payment matching daily deal purchase" do

				setup do
					@payment = PaypalPayment.find_or_create_by_paypal_notification(@params)
				end

				should "return a pending payment based on the notification settings" do
					assert_not_nil @payment.daily_deal_purchase, "should assign daily deal purchase"
					assert @payment.daily_deal_purchase.pending?
					assert_equal @params["payer_email"], @payment.payer_email
					assert_equal @params["txn_id"], @payment.payment_gateway_id
				end

			end

		end

	end

end