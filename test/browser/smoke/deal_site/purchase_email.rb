require File.dirname(__FILE__) + "/deal_site"

module Smoke
  module DealSite
    class PurchaseEmail

      attr_reader :messages, :page_validator

      def initialize(messages)
        @messages = messages
      end

      def email_body_for_last_purchase(publisher_label)
        publisher = Publisher.find_by_label!(publisher_label)
        consumer = publisher.consumers.last
        purchase = consumer.daily_deal_purchases.last
        mail = if purchase.travelsavers?
          DailyDealPurchaseMailer.create_confirmation(purchase)
        else
          DailyDealMailer.create_purchase_confirmation_with_certificates(purchase)
        end
        mail.body
      end

    end
  end
end