require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require File.dirname(__FILE__) + "/deal_site"

#
# Only useful if you have a database full of purchases.
# Runs through each publisher and makes sure the purchase email is good.
# Normally this is done as part of the regular smoke run
#
module Smoke
  module DealSite
    class PurchaseEmailTool < Smoke::DealSite::PublisherTool
      include ::Smoke::Logger

      def run_one_publisher(path, publisher, validator)
        if publisher.consumers.size > 0
          if publisher.consumers.last.daily_deal_purchases.size > 0
            smoke_deal_site_purchase_email_new = Smoke::DealSite::PurchaseEmail.new(messages)
            email_body = smoke_deal_site_purchase_email_new.email_body_for_last_purchase(publisher.label)
            log "validating purchase email for #{publisher.label}"
            validator.assert_no_errors(email_body, publisher.label, path)
            log "Success for #{publisher.label}".upcase.green
          else
            warning(publisher.label, path, "no purchases for #{publisher.label}. Skipping.")
          end
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

Smoke::DealSite::PurchaseEmailTool.new.run("Will validate emails for last purchases made for each publisher...")