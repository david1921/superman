require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require File.dirname(__FILE__) + "/deal_site"
require File.dirname(__FILE__) + "/../site_tool"
require "capybara/rails"

module Smoke
  module DealSite
    class Tool < ::Smoke::SiteTool

      def initialize(options)
        super(:launched_with_current_or_future_daily_deals, options)
      end

      def checker
        @checker ||= DealSite::Checker.new(@options, messages, email, password)
      end

      def reject?(publisher_label)
        # 'viewall' is some kind of pseudo publisher for showing the parent_themes
        %w( viewall bcbsa-national ).include?(publisher_label) || super
      end

    end
  end
end

opts = Smoke::DealSite::Options.new(ARGV)
tool = Smoke::DealSite::Tool.new(opts)
tool.run
