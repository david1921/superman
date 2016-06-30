require 'rubygems'
require 'thread'
require 'test/unit'
require 'mocha'
require 'nokogiri'
require 'net/http'
require 'openssl'
require 'timecop'
require File.expand_path(File.dirname(__FILE__) + '/../lib/html_assertions')

require File.expand_path(File.dirname(__FILE__) + "/stubs/rails")

require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/time_with_zone'

# Autoload classes (constants) from Rails.root/lib just like Rails does. Otherwise, we need to add explicit requires
# in our production code to test it here. There may be a speed penaly—I can't detect one—so we may decide to fall back
# to explicit requires in the future.
#
# This "test_helper" file is required multiple times. Ensure that we don't tack the lib dir more than once.
unless ActiveSupport::Dependencies.autoload_paths.include?(File.expand_path(File.dirname(__FILE__) + "/stubs"))
  ActiveSupport::Dependencies.autoload_paths << File.expand_path(File.dirname(__FILE__) + "/stubs")
  ActiveSupport::Dependencies.autoload_paths << File.expand_path(File.dirname(__FILE__) + "/../../lib")
  ActiveSupport::Dependencies.autoload_paths << File.expand_path(File.dirname(__FILE__) + "/../../lib/tasks")
  $: << File.expand_path(File.dirname(__FILE__) + "/stubs")
  $: << File.expand_path(File.dirname(__FILE__) + "/../../lib")
  $: << File.expand_path(File.dirname(__FILE__) + "/../../lib/extensions")
end
require 'shoulda'

APP_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '../..')) unless Object.const_defined?(:APP_ROOT)

$:.insert(0, File.expand_path(File.dirname(__FILE__)))
require File.expand_path(File.dirname(__FILE__) + "/stubs/restful_authentication")

unless defined? AppConfig
  require 'ostruct'
  ::AppConfig = OpenStruct.new
end
Time.zone = 'Pacific Time (US & Canada)'

# Extend basic test case to have assert_difference/no_difference
require 'active_support/testing/assertions'
class Test::Unit::TestCase
  include ActiveSupport::Testing::Assertions
  include Testing::HTMLAssertions
end
