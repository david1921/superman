require File.dirname(__FILE__) + "/deal_site"

module Smoke
  module DealSite
    class Review
      include ::Capybara::DSL
      include Smoke::Logger
      include Smoke::Capybara

      attr_reader :messages

      def initialize(messages)
        @messages = messages
      end

      def review
        select_store
        if one_click?
          one_click_review
        else
          normal_review
        end
      end

      def one_click?
        has_selector?("#review_and_buy_form")
      end

      def normal_review
        select_store()
        click_button "review_button"
      end

      def select_store
        if has_select?("daily_deal_purchase_store_id")
          safe_select_option("daily_deal_purchase_store_id", 2)
        end
      end

      def one_click_review
        safe_fill_in "Name:", :with => Faker::Name.name
        safe_fill_in "Address line 1:", :with => Faker::Address.street_address
        safe_fill_in "City:", :with => Faker::Address.city
        safe_select "State:", "OR"
        safe_fill_in "Zip:", :with =>Faker::Address.zip
        safe_click_button "review_button"
      end

    end
  end
end