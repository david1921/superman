require File.dirname(__FILE__) + "/deal_site"

module Smoke
  module DealSite
    class ConsumerEmails

      def consumer_email_bodies(consumer)
        [activation_body(consumer), welcome_body(consumer), password_reset_body(consumer)]
      end

      def welcome_body(consumer)
        ConsumerMailer.create_welcome_message(consumer).body
      end

      def password_reset_body(consumer)
        ConsumerMailer.create_password_reset_instructions(consumer).body
      end

      def activation_body(consumer)
        ConsumerMailer.create_activation_request(consumer).body
      end

    end
  end
end