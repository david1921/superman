require File.dirname(__FILE__) + "/../../../../test_helper"
# Need to require production module directly. Autoload will just find this tests' Import::DailyDealImport and stop
require File.expand_path(File.dirname(__FILE__) + "/../../../../../../lib/tasks/import/daily_deal_import")

# hydra class Import::DailyDealImport::HTTPTest
module Import
  module DailyDealImport
    class HTTPTest < Test::Unit::TestCase
      context "#post_file" do
        setup do
          NilClass.any_instance.stubs(:present?).returns(false)
          String.any_instance.stubs(:starts_with?)
          File.stubs(:read)
          @uri_with_query = "http://www.host.com/path?query=true"
          Net::HTTP.stubs(:new).returns(mock(:request => nil))
          @request = mock(:body= => nil)
        end

        should "pass query string to post" do
          Net::HTTP::Post.expects(:new).with("/path?query=true").returns(@request)
          Import::DailyDealImport::HTTP.post_file(@uri_with_query, "fake_filename.xml")
        end
      end

      context "#download_to_file" do
        should "return response" do
          full_url = "http://some.host"
          to_here = '/path/to/some/file'
          http = mock('HTTP', :read_timeout= => nil)
          Net::HTTP.stubs(:new).returns(http)
          response = mock('Response')
          http.stubs(:request).returns(response)
          File.stubs(:open)
          assert_equal response, Import::DailyDealImport::HTTP.download_to_file(full_url, to_here)
        end
      end
    end
  end
end
