require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchase::SetupWithTest < ActiveSupport::TestCase

	context "DailyDealPurchase#setup_with" do 

		setup do
			@daily_deal 		= Factory(:daily_deal)
			@publisher			= @daily_deal.publisher
			@discount			= Factory(:discount, :publisher => @publisher)
			@consumer			= Factory(:consumer, :publisher => @publisher)
			@mailing_address 	= Factory(:address)
		end
		
		should "raise ArgumentError with no daily deal" do
			assert_raise ArgumentError do
				DailyDealPurchase.setup_with({:consumer => @consumer})
			end
		end		

		should "raise ArgumentError with no consumer" do
			assert_raise ArgumentError do
				DailyDealPurchase.setup_with({:daily_deal => @daily_deal})
			end
		end

		should "build purchase with just daily deal and consumer setting" do
			purchase = DailyDealPurchase.setup_with({:daily_deal => @daily_deal, :consumer => @consumer})
			assert purchase.new_record?, "should be a new record"
			assert_equal @daily_deal, purchase.daily_deal
			assert_equal @consumer, purchase.consumer
			assert_equal @daily_deal.min_quantity, purchase.quantity
			assert_nil purchase.discount
			assert_nil purchase.mailing_address
			assert_nil purchase.daily_deal_variation
		end

		should "build purchase with daily deal, consumer, and discount" do
			purchase = DailyDealPurchase.setup_with({:daily_deal => @daily_deal, :consumer => @consumer, :discount => @discount})
			assert purchase.new_record?, "should be a new record"
			assert_equal @daily_deal, purchase.daily_deal
			assert_equal @consumer, purchase.consumer
			assert_equal @daily_deal.min_quantity, purchase.quantity
			assert_equal @discount, purchase.discount
			assert_nil purchase.mailing_address		
			assert_nil purchase.daily_deal_variation	
		end

		should "build purchase with daily_deal, consumer and mailing address" do
			purchase = DailyDealPurchase.setup_with({:daily_deal => @daily_deal, :consumer => @consumer, :mailing_address => @mailing_address})
			assert purchase.new_record?, "should be a new record"
			assert_equal @daily_deal, purchase.daily_deal
			assert_equal @consumer, purchase.consumer
			assert_equal @daily_deal.min_quantity, purchase.quantity
			assert_nil purchase.discount
			assert_equal @mailing_address, purchase.mailing_address
			assert_nil purchase.daily_deal_variation
		end

		context "with daily deal variation" do
			setup do
				@publisher.update_attribute(:enable_daily_deal_variations, true)
				@variation = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :min_quantity => 2)
			end

			should "build purchase with daily_deal, consumer and variation" do
				purchase = DailyDealPurchase.setup_with({:daily_deal => @daily_deal, :consumer => @consumer, :daily_deal_variation => @variation})
				assert purchase.new_record?, "should be a new record"
				assert_equal @daily_deal, purchase.daily_deal
				assert_equal @consumer, purchase.consumer
				assert_equal @variation.min_quantity, purchase.quantity
				assert_nil purchase.discount
				assert_nil purchase.mailing_address
				assert_equal @variation, purchase.daily_deal_variation				
			end

		end
		
	end

end
