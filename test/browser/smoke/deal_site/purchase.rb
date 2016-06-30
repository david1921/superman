require File.dirname(__FILE__) + "/deal_site"

module Smoke
  module DealSite
    class Purchase
      include ::Capybara::DSL
      include Smoke::Logger
      include Smoke::Capybara

      class Smoke::DealSite::UnknownPurchaseTypeError < Smoke::UnrecoverableError
        def initialize(publisher_label, path)
          super(publisher_label, path, "Unknown purchase type (based on the page contents)")
        end
      end

      attr_reader :messages

      def initialize(messages)
        @messages = messages
      end

      def purchase(publisher_label, purchase_uuid=nil)
        if purchase_uuid
          purchase_path = "/daily_deal_purchases/#{purchase_uuid}/confirm"
          unless current_path == purchase_path
            visit purchase_path
          end
        end

        check_confirmation_path(publisher_label)

        if braintree?
          braintree_purchase
        elsif cybersource?
          cybersource_purchase
        elsif has_button? "Complete Purchase"
          # I this this may happen for "free" purchases sometimes
          click_button "Complete Purchase"
        elsif paypal?
          paypal_purchase
        else
          raise Smoke::DealSite::UnknownPurchaseTypeError.new(publisher_label, current_path)
        end
      end

      def check_confirmation_path(publisher_label)
        unless current_path =~ %r{/daily_deal_purchases/(.*)/confirm}
          raise Smoke::UnrecoverableError.new(publisher_label, current_path, "#{current_path} does not look like a purchase page.  Validations may have failed on the purchase/new page?")
        end
      end

      def cybersource_purchase
        safe_fill_in "cyber_source_order_billing_first_name", :with => Faker::Name.first_name
        safe_fill_in "cyber_source_order_billing_last_name", :with => Faker::Name.first_name
        safe_fill_in "cyber_source_order_billing_address_line_1", :with => Faker::Address.street_address
        safe_fill_in "cyber_source_order_billing_city", :with => Faker::Address.city
        safe_select "cyber_source_order_billing_state", "OR"
        safe_fill_in "cyber_source_order_billing_postal_code", :with =>Faker::Address.zip
        safe_select "cyber_source_order_billing_country", "United States"
        safe_select "cyber_source_order_card_type", "Visa"
        safe_fill_in "cyber_source_order_card_number", :with => "4111111111111111"
        safe_select "cyber_source_order_card_expiration_month", "12"
        safe_select "cyber_source_order_card_expiration_year", "2027"
        safe_fill_in "cyber_source_order_card_cvv", :with => "249"
        safe_click_button "Buy Now"
      end

      def braintree?
        has_field?("transaction_credit_card_cardholder_name")
      end

      def cybersource?
        has_field?("cyber_source_order_billing_first_name")
      end

      def braintree_purchase
        safe_fill_in "transaction_credit_card_cardholder_name", :with => Faker::Name.name
        safe_fill_in "transaction_credit_card_number", :with => "4111111111111111"
        safe_fill_in "transaction_credit_card_cvv", :with => "123"
        safe_select "transaction_credit_card_expiration_month", "12"
        safe_select "transaction_credit_card_expiration_year", "2027"
        safe_fill_in "transaction_billing_street_address", :with => Faker::Address.street_address
        safe_fill_in "transaction_billing_locality", :with => Faker::Address.city
        safe_select "transaction_billing_region", "OR"
        safe_fill_in "transaction_billing_postal_code", :with => Faker::Address.zip
        safe_select "transaction_billing_country_code_alpha2", "United States"
        safe_click_button "credit_card_buy_now"
      end

      def paypal?
        !all("#payment_method_paypal").empty?
      end

      def paypal_purchase
        paypal_area = find("#payment_method_paypal")
        paypal_area.find("input[type=image]").click
      end

    end
  end
end