require File.dirname(__FILE__) + "/../../../../test_helper"
require 'export/entertainment/deal_summary_email_task'

# hydra class Export::Entertainment::ItemGrouperTest
module Export
  module Entertainment
    class ItemGrouperTest < Test::Unit::TestCase
      context "input names" do
        should "group items from the collection into hash keys" do
            groups = ItemGrouper.group_items ["first", "first"]

            assert_equal ["first"], groups.keys.sort
        end

        should "have items counts for each key" do
            groups = ItemGrouper.group_items ["first", "first", "second"]

            assert_equal 2, groups["first"]
            assert_equal 1, groups["second"]
        end

        should "convert keys into strings" do
          groups = ItemGrouper.group_items [1, 2, 3]

          assert_equal ["1", "2", "3"], groups.keys.sort
        end
      end

      context "allow an item mapper" do
        should "use the item mapper to generate key" do
          groups = ItemGrouper.group_items ["first", "second"] do |item|
            "#{item}!"
          end

          assert_equal ["first!", "second!"], groups.keys.sort
        end
      end
    end
  end
end