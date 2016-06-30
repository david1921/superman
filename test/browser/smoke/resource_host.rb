require File.dirname(__FILE__) + "/../resources/publisher"
require File.dirname(__FILE__) + "/../resources/publishing_group"
require File.dirname(__FILE__) + "/../resources/publisher_membership_code"
require File.dirname(__FILE__) + "/../resources/publishing_groups/market"

module Smoke
  module ResourceHost

    def setup_active_resource_host
      AppConfig.active_resource_host = @options[:resource_host] || "http://localhost:3000"
      Resources::Publisher.site = AppConfig.active_resource_host
      Resources::PublishingGroup.site = AppConfig.active_resource_host
      Resources::PublisherMembershipCode.site = AppConfig.active_resource_host
      Resources::PublishingGroups::Market.site = AppConfig.active_resource_host
    end

  end
end