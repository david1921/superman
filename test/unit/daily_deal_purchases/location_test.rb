# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchase::LocationTest < ActiveSupport::TestCase
  include DailyDealPurchasesTestHelper
  
  context "location required" do
    
    setup do
      @daily_deal       = Factory(:daily_deal)      
      @advertiser       = @daily_deal.advertiser
      @advertiser.stores.destroy_all
            
      @store_1 = Factory(:store, :advertiser => @advertiser)
      @store_2 = Factory(:store, :advertiser => @advertiser)
      @store_3 = Factory(:store, :advertiser => @advertiser)
      
      @daily_deal.update_attribute(:location_required, true)
      
      @valid_attributes = { :daily_deal => @daily_deal, :consumer => Factory(:consumer, :publisher => @daily_deal.publisher), :quantity => 1 } 
      
      @another_advertiser       = Factory(:advertiser)
      @another_advertiser_store = Factory(:store, :advertiser => @another_advertiser)
    end
    
    context "with a missing store id" do
      
      setup do
        @daily_deal_purchase = build_with_attributes(@valid_attributes)
      end
      
      should "not be a valid daily deal purchase" do
        assert !@daily_deal_purchase.valid?
        assert_match /choose a redemption location/i,  @daily_deal_purchase.errors.on(:base)
      end
      
    end
    
    context "with an invalid store id" do
      
      setup do 
        @daily_deal_purchase = build_with_attributes(@valid_attributes.merge(:store_id => @another_advertiser_store.id))
      end
      
      should "not be a valid daily deal purchase" do
        assert !@daily_deal_purchase.valid?
        assert_match /choose a redemption location/i,  @daily_deal_purchase.errors.on(:base)
      end
      
    end
    
    context "with a valid store id" do
      
      setup do
        @daily_deal_purchase = build_with_attributes(@valid_attributes.merge(:store_id => @store_1.id))
      end
      
      should "be valid daily deal purchase" do
        assert @daily_deal_purchase.valid?
      end
      
    end
    
    
  end
  
end
