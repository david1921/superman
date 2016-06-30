require File.dirname(__FILE__) + "/deal_site"

module Smoke
  module DealSite
    module Login
      include ::Capybara::DSL
      include Smoke::Logger

      def login(publisher_id, email, password)
        log "Logging in for #{email} and publisher with id #{publisher_id}"
        if current_path != login_path(publisher_id)
          visit login_path(publisher_id)
        end
        fill_in "session_email", :with => email
        fill_in "session_password", :with => password
        if has_button? "sign_in_button"
          click_button "sign_in_button"
        elsif has_button? "Sign In"
          click_button "Sign In"
        end
      end

      def login_path(publisher_id)
        "/publishers/#{publisher_id}/daily_deal/login"
      end

    end
  end
end
