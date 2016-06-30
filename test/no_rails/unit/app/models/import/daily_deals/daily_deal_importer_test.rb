require File.dirname(__FILE__) + "/../../../models_helper"

# hydra class Import::DailyDeals::DailyDealImporterTest
module Import
  module DailyDeals
    class DailyDealImporterTest < Test::Unit::TestCase

      context "#time" do
        should "convert zoneless time to publisher timezone" do
          tz_name = 'Central Time (US & Canada)'
          publisher = stub('Publisher', :time_zone => tz_name)
          importer = DailyDealImporter.new(nil, publisher, {})
          input = '2011-09-22 00:00:05'
          assert_equal ActiveSupport::TimeZone.new(tz_name).parse(input), importer.time(input)
        end

        should "delegate converting zoned time to superclass" do
          assert_equal Time.iso8601('2011-09-22T00:00:05Z'), DailyDealImporter.new(nil, nil, {}).time('2011-09-22T00:00:05Z')
        end

        should "convert time when it is properly formatted" do
          assert_equal Time.parse('2011-12-13T22:01:44-0600'), DailyDealImporter.new(nil, nil, {}).time('2011-12-13T22:01:44-0600')
        end
      end
    end
  end
end
