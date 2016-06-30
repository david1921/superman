require File.dirname(__FILE__) + "/../../../../test_helper"
require 'export/entertainment/deal_summary_email_task'

# hydra class Export::Entertainment::MarketPurchasePairTest
module Export
  module Entertainment
    class MarketPurchasePairTest < Test::Unit::TestCase
      context "result values" do
        should "convert label to string" do
          pair = MarketPurchasePair.new(1, 0, 0, 5)

          assert_equal "1", pair.label
        end

        should "have a count value equal to the ending count" do
          pair = MarketPurchasePair.new(1, 0, 13773, 5)

          assert_equal 13773, pair.count
          assert_equal pair.end_value, pair.count
        end

        should "have a variance value equal to the ending count minus start count" do
          pair = MarketPurchasePair.new(1, 3773, 13773, 5)

          assert_equal 10000, pair.variance
        end

        should "have a exceeds variance value with default variance" do
          first = MarketPurchasePair.new("first", 100, 106, 5)
          second = MarketPurchasePair.new("second", 100, 105, 5)
          third = MarketPurchasePair.new("third", 100, 94, 5)

          assert first.exceeds
          assert !second.exceeds
          assert third.exceeds
        end

        should "have a exceeds value of true for items not in both collections" do
          first = MarketPurchasePair.new("first", 1, 0, 5)
          second = MarketPurchasePair.new("second", 0, 1, 5)

          assert first.exceeds
          assert second.exceeds
        end
      end
    end
  end
end
