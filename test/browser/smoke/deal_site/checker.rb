require File.dirname(__FILE__) + "/deal_site"

module Smoke
  module DealSite
    class Checker
      include Smoke::Logger
      include Smoke::DealSite::Logout
      include Smoke::DealSite::Login
      include Smoke::Capybara

      attr_reader :messages

      def initialize(options, messages, email = nil, password = nil)
        @options = options
        @messages = messages
        @email = email
        @password = password
      end

      def check_site(publisher_id, publisher_label)
        begin
          if deal?
            check_deal_of_the_day(publisher_label)
            check_deal_of_the_day_email(publisher_label)
          end
          if signup?
            @email, @password = check_signup(publisher_id, publisher_label, email, password)
            check_logout(publisher_id, publisher_label) if login?
          end
          check_login(publisher_id, publisher_label, email, password) if login?
          buy_now(publisher_label) if purchase?
          my_deals(publisher_label) if my_deals?
          check_extras(publisher_id, publisher_label) if extras?
        rescue Smoke::UnrecoverableWarning => e
          puts "caught uncoverable warning"
          warning(publisher_label, current_path, e)
        rescue Smoke::UnrecoverableError => e
          puts "caught uncrecoverable error"
          error(publisher_label, current_path, e)
        rescue ::Capybara::CapybaraError => e
          error(publisher_label, current_path, "CapybaraError: #{e}")
        end
      end

      def check_login(publisher_id, publisher_label, email, password)
        log "--login"
        visit login_path(publisher_id)
        validate_page(publisher_label, login_path(publisher_id))
        login(publisher_id, email, password)
      end

      def check_logout(publisher_id, publisher_label)
        logout(publisher_id)
        unless current_path == "/publishers/#{publisher_label}/deal-of-the-day" || on_landing? || on_presignup?
          warning(publisher_label, current_path, "Should be on deal-of-the-day page after logout")
        end
      end

      def on_landing?
        current_path =~ %r{publishing_groups/.*/landing_page}
      end

      def on_presignup?
        current_path =~ /presignup$/
      end

      def check_extras(publisher_id, publisher_label)
        log "--extras"
        validate_page(publisher_label, "/publishers/#{publisher_id}/daily_deals/faqs")
        validate_page(publisher_label, "/publishers/#{publisher_id}/daily_deals/privacy_policy")
        validate_page(publisher_label, "/publishers/#{publisher_id}/daily_deals/terms")
      end

      def check_deal_of_the_day(publisher_label)
        log "--deal_of_the_day"
        deal_of_the_day_path = "/publishers/#{publisher_label}/deal-of-the-day"
        visit deal_of_the_day_path
        if on_presignup?
          warning(publisher_label, current_path, "Pubisher not live yet")
        elsif on_landing?
          warning(publisher_label, current_path, "Publisher on landing page not deal page (probably bcbsa)")
        else
          validate_page(publisher_label, deal_of_the_day_path)
        end
      end
      
      def check_deal_of_the_day_email(publisher_label)
        validate_page(publisher_label, "/publishers/#{publisher_label}/deal-of-the-day-email")
      end

      def wall?
        @options.wall? || !do_something?
      end

      def do_something?
        @options.signup? || @options.login? || @options.purchase? || @options.deal_of_the_day? || @options.my_deals?
      end

      def email
        @email
      end

      def password
        @password
      end

      def signup?
        wall? || @options.signup? || (@options.purchase? && !email_and_password_provided?)
      end

      def email_and_password_provided?
        email.present? && password.present?
      end

      def login?
        wall? || @options.login? || (@options.purchase? && email_and_password_provided?)
      end

      def deal?
        wall? || @options.deal_of_the_day?
      end

      def extras?
        wall? || @options.extras?
      end

      def check_signup(publisher_id, publisher_label, email = nil, password = nil)
        log "--sign_up"
        signup = Signup.new(messages, publisher_id, publisher_label, email, password)
        signup_path = signup.signup_path
        visit signup_path
        validate_page(publisher_label, signup_path)
        signup.signup
        validate_page(publisher_label, current_path)
        # some pubs don't do activation (bx)
        if signup.on_activation_page?
          signup.activate_user(publisher_label)
        end
        [signup.email, signup.password]
      end

      def validate_page(label, path)
        unless @options.skip_page_validations?
          if path.empty?
            raise Smoke::UnrecoverableError(label, "Empty path!")
          end
          page_validator.validate_page(label, path)
        end
      end

      def page_validator
        @page_validator ||= Smoke::PageValidator.new(messages, false)
      end

      def purchase?
        return false if @options.skip_purchase?
        wall? || @options.purchase?
      end

      def buy_now(publisher_label)
        log "--purchase"
        if has_link?("buy_now_button")
          if has_link?("buy_now_button")
            if has_selector?("#dd_variations")
              buy_now_variant = page.find('.dd_variations_data a.variation_buy_button')
              if buy_now_variant
                visit buy_now_variant[:href]
              else
                raise Smoke::UnrecoverableWarning.new(publisher_label, current_path, "has variations but can't find link")
              end
            else
              click_link "buy_now_button"
              review(publisher_label)
              purchase(publisher_label)
            end
          else
            warning(publisher_label, current_path, "No buy now button. Skipped purchase")
          end
        elsif has_selector?("#buy_now")
          if deal_over?
            deal_over_warning(publisher_label)
          elsif sold_out?
            sold_out_warning(publisher_label)
          else
            buy_now_area = find("#buy_now")
            buy_now_link = buy_now_area.find("a")
            visit buy_now_link[:href]
            review(publisher_label)
            purchase(publisher_label)
          end
        else
          if on_presignup?
            warning(publisher_label, current_path, "Publisher not launched.  Skipping purchase")
          elsif on_landing?
            warning(publisher_label, current_path, "On landing page, not purchase page.  Skipping purchase")
          elsif has_link?("redeem_now")
            # Blue cross, for example
            warning(publisher_label, current_path, "Has redeem button, not buy now. Skipping purchase.")
          elsif deal_over?
            deal_over_warning(publisher_label)
          elsif sold_out?
            sold_out_warning(publisher_label)
          else
            raise Smoke::UnrecoverableError.new(publisher_label, current_path, "No buy now button and deal does not appear to be sold out or over.")
          end
        end
      end

      def sold_out_warning(publisher_label)
        warning(publisher_label, current_path, "No buy now button, but deal appears to be sold out.  Skipping purchase.")
      end

      def deal_over_warning(publisher_label)
        warning(publisher_label, current_path, "No buy now button, but deal appears to be over. Skipping purchase.")
      end

      def sold_out?
        has_selector?("#sold_out") || has_selector?("img[alt*=out]") || has_selector?("img[alt*=Out]") || any_matching_span?('SOLD OUT')
      end

      def deal_over?
        has_selector?("#deal_over") || has_selector?("img[alt*=over]") || has_selector?("img[alt*=Over]") || any_matching_span?('DEAL OVER')
      end

      def review(publisher_label)
        validate_page(publisher_label, current_path)
        Smoke::DealSite::Review.new(messages).review
        validate_page(publisher_label, current_path)
      end

      def purchase(publisher_label)
        if capybara_headless?
          warning(publisher_label, current_path, "Skipping purchase because headless")
          return
        end
        Smoke::DealSite::Purchase.new(messages).purchase(publisher_label)
        validate_page(publisher_label, current_path)
        check_purchase_email(publisher_label)
      end

      def check_purchase_email(publisher_label)
        mail_body = Smoke::DealSite::PurchaseEmail.new(messages).email_body_for_last_purchase(publisher_label)
        page_validator.assert_no_errors(mail_body, publisher_label, "purchase email for #{publisher_label}")
      end

      def my_deals?
        wall? || (purchase? && @options.my_deals?)
      end

      def my_deals(publisher_label)
        log "--my_deals"
        safe_click_link "My Deals"
        validate_page(publisher_label, current_path)
      end

      def error_count
        messages.errors.size
      end

    end
  end
end

