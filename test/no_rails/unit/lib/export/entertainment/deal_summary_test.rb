require File.dirname(__FILE__) + "/../../../../test_helper"
require 'export/entertainment/deal_summary_email_task'

# hydra class Export::Entertainment::DealSummaryTest
module Export
  module Entertainment
    class PublisherDailyDealPurchaseTotal; end
    class DealSummaryTest < Test::Unit::TestCase
      context "success path" do
        setup do
          @start_date = Date.new(2012, 12, 20)
          @end_date = Date.new(2012, 12, 21)
          @variance = 5
        end

        should "fetch data for the start and end dates" do
          stub_counts(@start_date, {}).once
          stub_counts(@end_date, {}).once

          DealSummary.summarize @start_date, @end_date, @variance
        end

        should "group items from the starting collection" do
          stub_counts(@start_date, { "first" => 1 })
          stub_counts(@end_date, {})

          results = DealSummary.summarize @start_date, @end_date, @variance

          assert_equal ["first"], labels_for(results)
        end

        should "group items from the ending collection" do
          stub_counts(@start_date, {})
          stub_counts(@end_date, { "first" => 1 })

          results = DealSummary.summarize @start_date, @end_date, @variance

          assert_equal ["first"], labels_for(results)
        end

        should "group items from both collections" do
          stub_counts(@start_date, { "first" => 1, "second" => 1})
          stub_counts(@end_date, { "second" => 1, "third" => 1})

          results = DealSummary.summarize @start_date, @end_date, @variance

          assert_equal ["first", "second", "third"].sort, labels_for(results)
        end
      end

      def stub_counts(for_date, returns)
          PublisherDailyDealPurchaseTotal.stubs(:fetch_totals).with(for_date).returns(returns)
      end

      def labels_for(groups)
          groups.map {|x| x.label}.sort
      end
    end
  end
end
