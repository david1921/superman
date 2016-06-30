require File.dirname(__FILE__) + "/deal_site"

module Smoke
  module DealSite
    module Logout
      include ::Capybara::DSL
      include Smoke::Logger

      def logout(publisher_id)
        log "Logging out for publisher with id #{publisher_id}"
        visit logout_path(publisher_id)
      end

      def logout_path(publisher_id)
        "/publishers/#{publisher_id}/daily_deal/logout"
      end

    end
  end
end



