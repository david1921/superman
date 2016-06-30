require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::VariationsPricingTest

module DailyDeals
  class VariationsPricingTest < ActiveSupport::TestCase
    context "#price_to_display" do
      context "on a deal variations disabled" do
        should "return the deal price" do
          publisher = Factory(:publisher, :enable_daily_deal_variations => false)
          daily_deal = Factory(:daily_deal, :publisher => publisher, :price => 10.0)
          assert_equal 10.0, daily_deal.price_to_display
        end
      end

      context "on a deal with variations enabled" do
        setup do
          @publisher = Factory(:publisher, :enable_daily_deal_variations => true)
        end

        context "without any available variations" do
          should "return the deal price" do
            daily_deal = Factory(:daily_deal, :publisher => @publisher, :price => 10.0)
            assert daily_deal.daily_deal_variations.blank?
            assert_equal 10.0, daily_deal.price_to_display
          end
        end

        context "with available variations" do
          should "return the lowest priced variation" do
            daily_deal = Factory(:daily_deal, :publisher => @publisher, :price => 10.0)
            Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 2.0)
            Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 5.0)
            Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 1.0, :deleted_at => Time.now)
            assert_equal 2.0, daily_deal.price_to_display
          end
        end
      end
    end

    context "#value_to_display" do
      context "on a deal variations disabled" do
        should "return the deal value" do
          publisher = Factory(:publisher, :enable_daily_deal_variations => false)
          daily_deal = Factory(:daily_deal, :publisher => publisher, :value => 20.0)
          assert_equal 20.0, daily_deal.value_to_display
        end
      end

      context "on a deal with variations enabled" do
        setup do
          @publisher = Factory(:publisher, :enable_daily_deal_variations => true)
        end

        context "without any available variations" do
          should "return the deal value" do
            daily_deal = Factory(:daily_deal, :publisher => @publisher, :value => 20.0)
            assert daily_deal.daily_deal_variations.blank?
            assert_equal 20.0, daily_deal.value_to_display
          end
        end

        context "with available variations" do
          should "return the value of the lowest priced variation" do
            daily_deal = Factory(:daily_deal, :publisher => @publisher, :value => 20.0)
            Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 2.0, :value => 5.0)
            Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 5.0, :value => 10.0)
            Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 1.0, :value => 20.0, :deleted_at => Time.now)
            assert_equal 5.0, daily_deal.value_to_display
          end
        end
      end
    end

    context "#savings_to_display" do
      context "on a deal variations disabled" do
        should "return the deal savings" do
          publisher = Factory(:publisher, :enable_daily_deal_variations => false)
          daily_deal = Factory(:daily_deal, :publisher => publisher, :price => 10.0, :value => 20.0)
          assert_equal 10.0, daily_deal.savings_to_display
        end
      end

      context "on a deal with variations enabled" do
        setup do
          @publisher = Factory(:publisher, :enable_daily_deal_variations => true)
        end

        context "without any available variations" do
          should "return the deal savings" do
            daily_deal = Factory(:daily_deal, :publisher => @publisher, :price => 10.0, :value => 20.0)
            assert_equal 10.0, daily_deal.savings_to_display
          end
        end

        context "with available variations" do
          should "return the savings of the lowest priced variation" do
            daily_deal = Factory(:daily_deal, :publisher => @publisher, :price => 10.0)
            Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 2.0, :value => 5.0)
            Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 5.0, :value => 10.0)
            Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 1.0, :value => 20.0, :deleted_at => Time.now)
            assert_equal 3.0, daily_deal.savings_to_display
          end
        end
      end
    end

    context "#savings_to_display_as_percentage" do
      context "on a deal variations disabled" do
        setup do
          @publisher = Factory(:publisher, :enable_daily_deal_variations => false)
        end

        should "return the deal savings as a percentage" do
          daily_deal = Factory(:daily_deal, :publisher => @publisher, :price => 10.0, :value => 20.0)
          assert_equal 50.0, daily_deal.savings_to_display_as_percentage
        end

        should "return zero if there is a value of 0" do
          daily_deal = Factory(:daily_deal, :publisher => @publisher, :price => 10.0, :value => 0.0)
          assert_equal 0, daily_deal.savings_to_display_as_percentage
        end
      end

      context "on a deal with variations enabled" do
        setup do
          @publisher = Factory(:publisher, :enable_daily_deal_variations => true)
        end

        context "without any available variations as a percentage" do
          should "return the deal savings" do
            daily_deal = Factory(:daily_deal, :publisher => @publisher, :price => 15.0, :value => 20.0)
            assert_equal 25.0, daily_deal.savings_to_display_as_percentage
          end
        end

        context "with available variations" do
          should "return the savings of the lowest priced variation as a percentage" do
            daily_deal = Factory(:daily_deal, :publisher => @publisher, :price => 10.0, :value => 20.0)
            Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 2.0, :value => 4.0)
            Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 5.0, :value => 10.0)
            Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 1.0, :value => 20.0, :deleted_at => Time.now)
            assert_equal 50.0, daily_deal.savings_to_display_as_percentage
          end
        end

        should "return zero if there is a value of 0" do
          daily_deal = Factory(:daily_deal, :publisher => @publisher, :price => 10.0, :value => 5.0)
          Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 2.0, :value => 0)
          Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 5.0, :value => 10.0)
          Factory(:daily_deal_variation, :daily_deal => daily_deal, :price => 1.0, :value => 20.0, :deleted_at => Time.now)
          assert_equal 0, daily_deal.savings_to_display_as_percentage
        end
      end
    end
  end
end
