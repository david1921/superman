require File.expand_path(File.dirname(__FILE__) + "/../../../config/environment")
require "capybara/rails"
require File.dirname(__FILE__) + "/capybara"
require File.dirname(__FILE__) + "/page_validator"

module Smoke
  class PageValidatorTool
    include ::Capybara::DSL
    include Smoke::Capybara

    def initialize(options)
      @options = options
      setup_capybara(@options)
    end

    def run
      begin
        validator = Smoke::PageValidator.new
        validator.validate_page("tool", @options[:page])
      rescue => e
        save_and_open_page
        raise e
      end
    end

  end
end


opts = Slop.new(:help => true) do
  on :driver=, "Use the specified Capybara driver. rack_test, selenium, webkit, webkit_debug", :optional_argument => true
  on :page=, "The page to hit"
end

opts.parse ARGV

tool = Smoke::PageValidatorTool.new(opts)
tool.run


