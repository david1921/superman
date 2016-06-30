require File.dirname(__FILE__) + "/../../models_helper"

# hydra class Publishers::DailyDealsTest
module Publishers
  class DailyDealsTest < Test::Unit::TestCase

    context "available_daily_deals" do

      setup do
        @scope_stub = stub
        @scope_stub.expects(:active).at_most_once.returns(@scope_stub)
        @scope_stub.expects(:in_order).never

        @publisher = stub
        @publisher.extend(Publishers::DailyDeals::InstanceMethods)
        @publisher.expects(:daily_deals).at_most_once.returns(@scope_stub)
        @publisher.stubs(:default_daily_deal_zip_radius).returns(0)
      end

      context "given no arguments" do
        should "return only active deals for publisher" do
          assert_equal @scope_stub, @publisher.available_daily_deals
        end
      end

      context "given a list of categories" do
        should "return only deals within those categories" do
          @scope_stub.expects(:in_publishers_categories).returns(@scope_stub)
          assert_equal @scope_stub, @publisher.available_daily_deals(:categories => [stub])
        end
      end

      context "given the publisher has default_daily_deal_zip_radius > 0" do
        should "return only deals within zip code radius" do
          @publisher.stubs(:default_daily_deal_zip_radius).returns(10)
          @scope_stub.expects(:national_or_within_zip_radius).returns(@scope_stub)
          assert_equal @scope_stub, @publisher.available_daily_deals(:zip_code => "98685")
        end
      end

    end

  end
end
