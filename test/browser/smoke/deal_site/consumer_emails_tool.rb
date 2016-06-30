require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require File.dirname(__FILE__) + "/deal_site"

#
# Only useful if you have a database full of consumers.
# Runs through each publisher, takes the last consumer for that publisher, and creates and tests the main consumer emails
#
module Smoke
  module DealSite
    class ConsumerEmailsTool < Smoke::DealSite::PublisherTool

      def consumer_email_generator
        @consumer_email_generator ||= Smoke::DealSite::ConsumerEmails.new
      end

      def run_one_publisher(path, publisher, validator)
        if publisher.consumers.size > 0
          consumer = publisher.consumers.last
          welcome_body = consumer_email_generator.welcome_body(consumer)
          validator.assert_no_errors(welcome_body, consumer.publisher.label, "consumer welcome email")
          reset_body = consumer_email_generator.password_reset_body(consumer)
          validator.assert_no_errors(reset_body, consumer.publisher.label, "consumer reset email")
          activation_body = consumer_email_generator.activation_body(consumer)
          validator.assert_no_errors(activation_body, consumer.publisher.label, "consumer activation email")
          log "Success for #{publisher.label}".upcase.green
        else
          warning(publisher.label, path, "no consumers for #{publisher.label}. Skipping.")
        end
      end

      def messages
        @messages ||= Smoke::Messages.new
      end

    end
  end
end

Smoke::DealSite::ConsumerEmailsTool.new.run("Will validate emails for last purchases made for each publisher...")