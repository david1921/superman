require File.dirname(__FILE__) + "/../test_helper"

class PaypalConfigurationTest < ActiveSupport::TestCase

	context "self.sandbox" do 
		
		should "return the configuration for the sandbox" do
			configuration = PaypalConfiguration.sandbox
			assert_equal "https://www.sandbox.paypal.com/cgi-bin/webscr", configuration.ipn_url
			assert_equal "demo_merchant@analoganalytics.com", configuration.business

			# not necessary for sandbox
			assert_nil configuration.cert_id
			assert_nil configuration.certificate
			assert_nil configuration.key
		end

	end

	context "self.for_currency_code" do

		context "use_sandbox? is true" do

			setup do
				PaypalConfiguration.expects(:use_sandbox?).at_least_once.returns(true)
			end

			should "return the configuration for the sandbox for USD currency" do
				assert_equal PaypalConfiguration.sandbox, PaypalConfiguration.for_currency_code("USD")
			end

			should "return the configuration for the sandbox for EUR currency" do
				assert_equal PaypalConfiguration.sandbox, PaypalConfiguration.for_currency_code("EUR")
			end

			should "return the configuration for the sandbox with a nil currency as well" do
				assert_equal PaypalConfiguration.sandbox, PaypalConfiguration.for_currency_code(nil)
			end

		end

		context "use_sandbox? is false" do

			setup do
				PaypalConfiguration.expects(:use_sandbox?).at_least_once.returns(false)
			end

			should "raise ArgumentError for nil currency code" do
				assert_raise ArgumentError do
					PaypalConfiguration.for_currency_code(nil)
				end
			end

			should "raise ArgumentError for invalid currency code" do
				assert_raise ArgumentError do
					PaypalConfiguration.for_currency_code("BLAH")
				end
			end			

			should "return the appropriate configuration for USD" do
				configuration = PaypalConfiguration.for_currency_code("USD")
				assert_equal "https://www.paypal.com/cgi-bin/websrc", configuration.ipn_url	
				assert_equal "kathleen.winer@analoganalytics.com", configuration.business

				assert_equal "LLQUFYP28FEPS", configuration.cert_id

				# pretend that all files exist
				File.stubs(:exists?).returns(true)

				File.expects(:read).with("#{Rails.root}/config/paypal/analog_analytics_paypal_crt.pem").returns("contents for crt pem")
				assert_equal "contents for crt pem", configuration.certificate

				File.expects(:read).with("#{Rails.root}/config/paypal/analog_analytics_paypal_key.pem").returns("contents for key pem")
				assert_equal "contents for key pem", configuration.key

				File.expects(:read).with("#{Rails.root}/config/paypal/paypal_crt.pem").returns("contents for paypal crt pem")
				assert_equal "contents for paypal crt pem", configuration.paypal_certificate

			end

			should "return the appropriate configuration for EUR" do
				configuration = PaypalConfiguration.for_currency_code("EUR")
				assert_equal "https://www.paypal.com/cgi-bin/websrc", configuration.ipn_url
				assert_equal "accounting@analoganalytics.com", configuration.business

				assert_equal "ZMY27VE5BHB7A", configuration.cert_id

				# pretend that all files exist
				File.stubs(:exists?).returns(true)

				File.expects(:read).with("#{Rails.root}/config/paypal/analog_analytics_paypal_crt.pem").returns("contents for crt pem")
				assert_equal "contents for crt pem", configuration.certificate

				File.expects(:read).with("#{Rails.root}/config/paypal/analog_analytics_paypal_key.pem").returns("contents for key pem")
				assert_equal "contents for key pem", configuration.key			

				File.expects(:read).with("#{Rails.root}/config/paypal/paypal_crt.pem").returns("contents for paypal crt pem")
				assert_equal "contents for paypal crt pem", configuration.paypal_certificate
			end			

		end

		
	end

end