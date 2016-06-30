require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::SoldOutTest

class DailyDeals::SoldOutTest < ActiveSupport::TestCase

	context "with a deal with quantity" do

		setup do
			@publisher  = Factory(:publisher, :payment_method => "credit")
			@daily_deal = Factory(:daily_deal, :publisher => @publisher, :quantity => 5, :hide_at => 1.day.from_now)
		end

		should "not be sold out with 0 units sold" do
			assert_equal 0, @daily_deal.number_sold
      @daily_deal.expects(:notify_third_party_purchases_api).never
			@daily_deal.sold_out!
			assert !@daily_deal.sold_out?, "deal should NOT be sold out"
			assert @daily_deal.available?, "deal should still be available"
			assert_nil @daily_deal.sold_out_at, "should not have sold_out_at set"
		end

		should "not be sold out with 4 units sold" do
			(1..4).each {|n| Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal)}
      @daily_deal.expects(:notify_third_party_purchases_api).never
			@daily_deal.sold_out!
			assert_equal 4, @daily_deal.daily_deal_purchases.size, "should have 4 purchases"
			assert !@daily_deal.sold_out?, "deal should NOT be sold out"
			assert @daily_deal.available?, "deal should still be available"
			assert_nil @daily_deal.sold_out_at, "should not have sold_out_at set"			
		end

		should "be sold out with 5 unites sold" do
			(1..5).each {|n| Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal)}
      @daily_deal.expects(:notify_third_party_purchases_api)
			@daily_deal.sold_out!
			assert_equal 5, @daily_deal.daily_deal_purchases.size, "should have 5 purchases"
			assert @daily_deal.sold_out?, "deal should be sold out"
			assert !@daily_deal.available?, "deal should NOT be available"
			assert_not_nil @daily_deal.sold_out_at, "should have sold_out_at set"
		end


	end

	context "with a deal with no quantity" do

		setup do
			@publisher  = Factory(:publisher, :payment_method => "credit")
			@daily_deal = Factory(:daily_deal, :publisher => @publisher, :quantity => "", :hide_at => 1.day.from_now)			
		end

		should "not be sold out with 0 units sold" do
			assert_equal 0, @daily_deal.number_sold
      @daily_deal.expects(:notify_third_party_purchases_api).never
			@daily_deal.sold_out!
			assert !@daily_deal.sold_out?, "deal should NOT be sold out"
			assert @daily_deal.available?, "deal should still be available"
			assert_nil @daily_deal.sold_out_at, "should not have sold_out_at set"
		end

    should "force sold out even with 0 units sold" do
      assert_equal 0, @daily_deal.number_sold
      @daily_deal.expects(:notify_third_party_purchases_api)
      @daily_deal.sold_out!(true)
      assert @daily_deal.sold_out?, "deal should be sold out"
      assert !@daily_deal.available?, "deal should NOT be available"
    end

		should "not be sold out with 10 units sold" do
			(1..10).each {|n| Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal)}
      @daily_deal.expects(:notify_third_party_purchases_api).never
			@daily_deal.sold_out!
			assert_equal 10, @daily_deal.daily_deal_purchases.size, "should have 10 purchases"
			assert !@daily_deal.sold_out?, "deal should NOT be sold out"
			assert @daily_deal.available?, "deal should still be available"
			assert_nil @daily_deal.sold_out_at, "should not have sold_out_at set"			
		end		

	end

  
	context "with a deal with variations" do

		setup do
			@publisher  = Factory(:publisher, :payment_method => "credit", :enable_daily_deal_variations => true)
			@daily_deal = Factory(:daily_deal, :publisher => @publisher, :hide_at => 1.day.from_now)	
			@variation_1 = Factory(:daily_deal_variation, :daily_deal => @daily_deal)
			@variation_2 = Factory(:daily_deal_variation, :daily_deal => @daily_deal)
		end

		should "not be sold out with no variations sold out" do
			assert !@daily_deal.sold_out?, "deal should not be sold out"
		end

		should "not be sold out with only one variatoin sold_out" do
			@variation_1.update_attribute(:sold_out_at, 30.seconds.ago)
			assert @variation_1.sold_out?, "variation 1 should be sold out"
			assert !@variation_2.sold_out?, "variation 2 should not be sold out"
			assert !@daily_deal.sold_out?, "deal should not be sold out"
		end

		should "be sold out with all variations sold out" do
			@variation_1.update_attribute(:sold_out_at, 30.seconds.ago)
			assert @variation_1.sold_out?, "variation 1 should be sold out"

			@variation_2.update_attribute(:sold_out_at, 30.seconds.ago)
			assert @variation_2.sold_out?, "variation 2 should be sold out"

			assert @daily_deal.sold_out?, "deal should be sold out"
		end

	end

end