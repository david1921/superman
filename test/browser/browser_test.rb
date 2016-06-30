ENV["RAILS_ENV"] = "acceptance"

require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
require File.dirname(__FILE__) + "/helpers/purchase_helper"
require "capybara/rails"
require 'shoulda'
require 'database_cleaner'
#require 'fakeweb'
#FakeWeb.register_uri(:get, "http://test.host/images/missing/publishers/logos/full_size.png", :status => ["404", "Not Found"])

# set SHOW_PAGE_ON_ERROR=true to see failures
class BrowserTest < ActiveSupport::TestCase
  include ::Capybara::DSL
  include ActionView::Helpers::UrlHelper
  # Selenium tests start the Rails server in a separate process. If test data is wrapped in a
  # transaction, the server won't see it.

  # Get rid of this
  Capybara.server_boot_timeout = 100

  DatabaseCleaner.strategy = :truncation
  setup :setup_driver, :clean_database
  teardown :show_page_on_error, :reset_capybara_driver

  def clean_database
    DatabaseCleaner.clean
  end

  def setup_driver
    if system("which chromedriver > /dev/null 2>&1")
      Capybara.register_driver :selenium do |app|
        Capybara::Selenium::Driver.new(app, :browser => :chrome)
      end
    else
      puts "to use chrome, brew install chromedriver OR
            download the chromedriver http://code.google.com/p/chromedriver/downloads/detail?name=chromedriver_mac_19.0.1068.0.zip&can=2&q=\nThen mv chromedriver to /usr/local/bin"
    end

    if ENV["CAPYBARA_DRIVER"].present?
      Capybara.current_driver = ENV["CAPYBARA_DRIVER"].to_sym
    else
      Capybara.use_default_driver
    end

    puts Capybara.current_driver

    Capybara.server_port = 8082
    Capybara.run_server = true
  end
  
  def reset_capybara_driver
    Capybara.use_default_driver
  end
  
  def show_page_on_error
    if ENV["SHOW_PAGE_ON_ERROR"] && !@passed
      save_and_open_page
    end
  end

  def say_if_verbose(text)
    if ENV["VERBOSE"].present?
      puts text
    end
  end
  
  def page_errors
    @page_errors ||= []
  end

  def current_path_with_params
    uri = URI.parse(current_url)
    "#{uri.path}?#{uri.query}"    
  end 

end
