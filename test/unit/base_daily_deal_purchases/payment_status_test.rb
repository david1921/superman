require File.dirname(__FILE__) + "/../../test_helper"

class BaseDailyDealPurchases::PaymentStatusTest < ActiveSupport::TestCase

  context "#after_capture" do
    should "not call #create_promotion_discount unless responds to method" do
      purchase = Factory(:off_platform_daily_deal_purchase)
      purchase.capture!
    end
  end

  context "#after_executed" do

  	context "with a basic daily deal, with a quantity of 2" do

  		setup do
  			@daily_deal = Factory(:daily_deal, :quantity => 2)
  		end

  		should "not be sold out with one captured purchase" do
  			purchase = Factory(:authorized_daily_deal_purchase, :daily_deal => @daily_deal)
  			purchase.set_payment_status!("captured")
  			@daily_deal.reload
  			assert !@daily_deal.sold_out?, "deal should not be sold out"
  		end

  		should "be sold out with two captured purchases" do
  			purchase_1 = Factory(:authorized_daily_deal_purchase, :daily_deal => @daily_deal)
  			purchase_1.set_payment_status!("captured")
  			purchase_2 = Factory(:authorized_daily_deal_purchase, :daily_deal => @daily_deal)
  			purchase_2.set_payment_status!("captured")
  			@daily_deal.reload
  			assert @daily_deal.sold_out?, "deal should be sold out"
  		end

  	end

  	context "with a daily deal with variations" do

  		setup do
  			@daily_deal = Factory(:daily_deal, :publisher => Factory(:publisher, :enable_daily_deal_variations => true))
  			@variation_1 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :quantity => 2)
  			@variation_2 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :quantity => 3)
  		end

  		should "not be sold out if no purchases are on the variations" do
  			assert !@daily_deal.sold_out?
  		end

  		should "not be sold out if only one variation is sold out" do
  			2.times do
  				p = Factory(:authorized_daily_deal_purchase, :daily_deal => @daily_deal, :daily_deal_variation => @variation_1)
  				p.set_payment_status!("captured")
  			end
  			assert @variation_1.sold_out?, "variation 1 should be sold out"
  			assert !@variation_2.sold_out?, "variation 2 should NOT be sold out"
  			assert !@daily_deal.sold_out?, "deal should NOT be sold out"
  		end

  		should "be sold out if all variations are sold out" do
  			2.times do
  				p = Factory(:authorized_daily_deal_purchase, :daily_deal => @daily_deal, :daily_deal_variation => @variation_1)
  				p.set_payment_status!("captured")
  			end
  			3.times do
  				p = Factory(:authorized_daily_deal_purchase, :daily_deal => @daily_deal, :daily_deal_variation => @variation_2)
  				p.set_payment_status!("captured")
  			end
  			assert @variation_1.sold_out?, "variation 1 should be sold out"
  			assert @variation_2.sold_out?, "variation 2 should be sold out"
  			assert @daily_deal.sold_out?, "deal should be sold out"  			
  		end



  	end

  end

end
