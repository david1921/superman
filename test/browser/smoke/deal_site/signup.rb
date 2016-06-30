require File.dirname(__FILE__) + "/deal_site"
require 'uuidtools'

module Smoke
  module DealSite
    class Signup
      include ::Capybara::DSL
      include Smoke::Logger
      include Smoke::Capybara

      attr_reader :publisher_id, :publisher_label, :messages

      def initialize(messages, publisher_id, publisher_label, email_to_use = nil, password_to_use = nil)
        @publisher_id = publisher_id
        @publisher_label = publisher_label
        @messages = messages
        @fake_consumer = Smoke::FakeConsumer.new(email_to_use, password_to_use)
      end

      def signup
        if current_path != signup_path
          visit signup_path
        end

        fill_in_fields
        click_signup_button
        if current_path == signup_path
          raise Smoke::UnrecoverableError.new(publisher_label, current_path, "Still on signup page.  Sign up failed.  Validations?")
        end
      end

      def fill_in_fields
        safe_fill_in "consumer_first_name", :with => first_name
        safe_fill_in "consumer_last_name", :with => last_name
        safe_fill_in "consumer_name", :with => full_name
        safe_fill_in "consumer_email", :with => email
        safe_fill_in "consumer_address_line_1", :with => Faker::Address.street_address
        safe_fill_in "consumer_city", :with => Faker::Address.city
        safe_fill_in "consumer_billing_city", :with => Faker::Address.city
        safe_fill_in "consumer_zip", :with => Faker::Address.zip
        safe_fill_in "consumer_zip_code", :with => Faker::Address.zip
        safe_select_male "consumer_gender"
        safe_select "consumer_birth_year", "1972"
        fill_in "consumer_password", :with => password
        fill_in "consumer_password_confirmation", :with => password
        safe_check "consumer_agree_to_terms"
        if blue_cross?
          if capybara_driver_supports_javascript?
            fill_in_publisher_membership_code(publisher_id)
            prototype_js_check "consumer_agree_to_terms"
            prototype_js_check "consumer_member_authorization"
          else
            raise Smoke::UnrecoverableWarning.new(publisher_label, current_path, "Capybara driver does not support javascript, skipping the rest of publisher")
          end
        end
      end

      def click_signup_button
        consumer_signup_form = find_consumer_signup_form
        consumer_signup_form.find("input[type=submit]").click
      end

      def find_consumer_signup_form
        result = page.all("form").detect { |f| f.has_field?("consumer_password") }
        unless result
          raise Smoke::UnrecoverableError(publisher_label, "Can't find the consumer signup form")
        end
        result
      end

      def blue_cross?
        has_field?("consumer_publisher_membership_code_as_text")
      end

      def fill_in_publisher_membership_code(publisher_id)
        if has_field?("consumer_publisher_membership_code_as_text")
          if okay_to_use_db?
            publisher = Publisher.find(publisher_id)
            code = publisher.publisher_membership_codes.first.try(:code)
            if code
              log "Using publisher membership code #{code}"
              fill_in "consumer_publisher_membership_code_as_text", :with => code
            else
              raise Smoke::UnrecoverableWarning.new(publisher_label, current_path, "Could not find publisher membership code")
            end
          else
            raise Smoke::UnrecoverableWarning.new(publisher_label, current_path, "Did not fill in publisher membership code because not okay to use db")
          end
        end
      end

      def activate_user(publisher_label)
        if okay_to_use_db?
          fill_in "activation_code", :with => activation_code(publisher_label)
          click_button "Activate"
        else
          add_activation_warning(publisher_label)
        end
      end

      def add_activation_warning(publisher_label)
        warning(publisher_label, current_path, "Did not activate user because not okay to use db.")
        nil
      end

      def activate_user_via_db(publisher_label)
        if okay_to_use_db?
          consumer.activate!
        else
          add_activation_warning(publisher_label)
        end
      end

      def activation_code(publisher_label)
        if okay_to_use_db?
          query = "select activation_code from users where publisher_id=#{publisher_id} and email='#{email}'"
          result = ActiveRecord::Base.connection.select_rows(query)
          if result
            result.first.first
          end
        else
          add_activation_warning(publisher_label)
        end
      end

      def signup_path
        "/publishers/#{publisher_id}/consumers/new"
      end

      def activation_path
        "/publishers/#{publisher_id}/consumers"
      end

      def on_activation_page?
        current_path == activation_path
      end

      def consumer(publisher_label)
        if okay_to_use_db?
          @consumer ||= ::Consumer.first(:conditions => ["publisher_id=? and email=?", publisher_id, email])
        else
          add_activation_warning(publisher_label)
        end
      end

      def okay_to_use_db?
        true
      end

      def password
        @fake_consumer.password
      end

      def full_name
        @fake_consumer.full_name
      end

      def first_name
        @fake_consumer.first_name
      end

      def last_name
        @fake_consumer.last_name
      end

      def email
        @fake_consumer.email
      end

    end
  end
end