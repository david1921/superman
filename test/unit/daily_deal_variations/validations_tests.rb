# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealVariation::ValidationsTest < ActiveSupport::TestCase
  setup :setup_valid_attributes
  
  context "#travelsavers_product_code" do
    
    context 'uniqueness' do
      should "be enforced across source deals and variations" do
        ts_deal = Factory :travelsavers_daily_deal, :available_for_syndication => true, :travelsavers_product_code => "XXX-42"     
        ts_deal_with_variation = Factory :travelsavers_daily_deal, :travelsavers_product_code => "needed_for_validation"
        daily_deal_variation = Factory.build(:daily_deal_variation, :daily_deal => ts_deal_with_variation, :travelsavers_product_code => 'XXX-42')      
        assert daily_deal_variation.invalid?
        assert_equal "Travelsavers product code must be unique across source deals", daily_deal_variation.errors.on(:travelsavers_product_code)
        
        daily_deal_variation.update_attributes! :travelsavers_product_code => 'XXX-NEW'
        ts_deal.travelsavers_product_code = 'XXX-NEW'
        assert ts_deal.invalid?
        assert_equal "Travelsavers product code must be unique across source deals", ts_deal.errors.on(:travelsavers_product_code)        
      end  
      
      should "be enforced across variations" do
        ts_deal_variation = Factory :travelsavers_daily_deal_variation, :travelsavers_product_code => "XXX-42"     
        ts_deal_variation2 = Factory.build :travelsavers_daily_deal_variation, :travelsavers_product_code => "XXX-42"             
        assert ts_deal_variation2.invalid?
        assert_equal "Travelsavers product code must be unique across source deals", ts_deal_variation2.errors.on(:travelsavers_product_code)
      end           
    end
    
    should "be required on a source Travelsavers deal" do
      daily_deal = Factory :travelsavers_daily_deal
      daily_deal_variation = Factory.build(:daily_deal_variation, :daily_deal => daily_deal, :travelsavers_product_code => nil)     
      assert daily_deal_variation.invalid?
      assert_equal "Travelsavers product code can't be blank", daily_deal_variation.errors.on(:travelsavers_product_code)
    end
    
    should "not be allowed on a source Travelsavers deal" do
      daily_deal = Factory :daily_deal
      daily_deal.publisher.update_attributes!(:enable_daily_deal_variations => true)      
      daily_deal_variation = Factory(:daily_deal_variation, :daily_deal => daily_deal, :travelsavers_product_code => nil)
      assert !daily_deal.publisher.pay_using?(:travelsavers)
      daily_deal_variation.travelsavers_product_code = "CXP-BLAH"
      assert daily_deal_variation.invalid?      
      assert_equal "Travelsavers product code must be blank; this publisher does not use travelsavers", daily_deal_variation.errors.on(:travelsavers_product_code)
    end
    
    
    should "not be changeable after a purchase has been made on the deal" do
      %w(pending captured).each_with_index do |payment_status, i|
        ts_deal = Factory :travelsavers_daily_deal         
        daily_deal_variation = Factory(:daily_deal_variation, :daily_deal => ts_deal, :travelsavers_product_code => 'CXP-TEXT')    
        daily_deal_variation.update_attributes! :travelsavers_product_code => "ABC-10000-#{i}"
        
        Factory :"#{payment_status}_daily_deal_purchase", :daily_deal => ts_deal, :daily_deal_variation => daily_deal_variation
        daily_deal_variation.daily_deal_purchases.reload
        daily_deal_variation.travelsavers_product_code = "changed"
        assert daily_deal_variation.invalid?
        assert_equal "Travelsavers product code cannot be changed", daily_deal_variation.errors.on(:travelsavers_product_code)
      end
    end
    
  end

  private

  def setup_valid_attributes
    @valid_attributes = {
        :value_proposition => "$81 value for $39",
        :price => 39.00,
        :value => 81.00,
        :quantity => 100,
        :terms => "these are my terms",
        :description => "this is my description",
        :start_at => 10.days.ago,
        :hide_at => Time.zone.now.tomorrow,
        :short_description => "A wonderful deal"
    }
  end

end
