# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::ValidationsTest < ActiveSupport::TestCase
  setup :setup_valid_attributes

  test "should be invalid with missing value proposition" do
    daily_deal = advertisers(:burger_king).daily_deals.build(@valid_attributes.except(:value_proposition))
    assert !daily_deal.valid?
    assert_not_nil daily_deal.errors.on(:value_proposition)
  end

  test "should be invalid with missing description" do
    daily_deal = advertisers(:burger_king).daily_deals.build(@valid_attributes.except(:description))
    assert !daily_deal.valid?
    assert_not_nil daily_deal.errors.on(:description)
  end

  test "should be invalid with missing price" do
    daily_deal = advertisers(:burger_king).daily_deals.build(@valid_attributes.except(:price))
    assert !daily_deal.valid?
    assert_not_nil daily_deal.errors.on(:price)
  end

  test "should be invalid with missing value" do
    daily_deal = advertisers(:burger_king).daily_deals.build(@valid_attributes.except(:value))
    assert !daily_deal.valid?
    assert_not_nil daily_deal.errors.on(:value)
  end

  test "should be invalid with missing terms" do
    daily_deal = advertisers(:burger_king).daily_deals.build(@valid_attributes.except(:terms))
    assert !daily_deal.valid?
    assert_not_nil daily_deal.errors.on(:terms)
  end

  test "should be valid with missing quantity" do
    daily_deal = advertisers(:burger_king).daily_deals.build(@valid_attributes.except(:quantity))
    assert daily_deal.valid?, daily_deal.errors.full_messages.join(", ")
    assert_nil daily_deal.errors.on(:quantity)
  end

  test "validation of max_quantity" do
    assert Factory.build(:daily_deal, :max_quantity => -12).invalid?, "Should not be valid with negative max_quantity"
    assert Factory.build(:daily_deal, :max_quantity => 25).valid?, "Should be valid with a max_quantity of 25"
    assert Factory.build(:daily_deal, :max_quantity => 26).invalid?, "Should not be valid with a max_quantity over 25"

    assert Factory.build(:daily_deal, :max_quantity => 0).valid?, "Should use default"
    assert_equal ::DailyDeal::MAX_QUANTITY_DEFAULT, Factory.build(:daily_deal, :max_quantity => 0).max_quantity

    assert Factory.build(:daily_deal, :max_quantity => 1.2).valid?, "Should round decimals"
    assert_equal 1, Factory.build(:daily_deal, :max_quantity => 1.2).max_quantity, "Should round decimals"
  end

  context "certificates_to_generate_per_unit_quantity validations" do
    
    setup do
      @deal = Factory :daily_deal, :certificates_to_generate_per_unit_quantity => 2
    end
    
    should "be invalid when changed after a purchase (in any state) has been made" do
      assert @deal.valid?
      Factory :daily_deal_purchase, :daily_deal => @deal
      @deal.reload
      @deal.certificates_to_generate_per_unit_quantity = 5
      assert @deal.invalid?
      assert_equal "Certificates to generate per unit quantity cannot be changed after a purchase has been made", @deal.errors.on(:certificates_to_generate_per_unit_quantity)
    end
    
    should "be valid when changed before a purchase (in any state) has been made" do
      assert @deal.valid?
      @deal.certificates_to_generate_per_unit_quantity = 5
      assert @deal.valid?
    end
    
    should "be invalid when nil" do
      assert @deal.valid?
      @deal.certificates_to_generate_per_unit_quantity = nil
      assert @deal.invalid?
      assert_match /is not a number/, @deal.errors.on(:certificates_to_generate_per_unit_quantity)
    end
    
    should "be invalid when < 1" do
      assert @deal.valid?
      @deal.certificates_to_generate_per_unit_quantity = 0
      assert @deal.invalid?
      assert_match /must be greater than or equal to 1/, @deal.errors.on(:certificates_to_generate_per_unit_quantity)
    end
    
  end
  
  context "advertiser_revenue_share_percentage validations" do
    
    context "a non-syndicated deal" do

      setup do
        @deal = Factory :daily_deal
      end
    
      should "not be required when Publisher#uses_paychex? is false" do
        assert !@deal.publisher.uses_paychex?
        assert @deal.advertiser_revenue_share_percentage.blank?
        assert @deal.valid?
        @deal.advertiser_revenue_share_percentage = 50
        assert @deal.valid?
      end
    
      should "be required when Publisher#uses_paychex? is true" do
        assert !@deal.publisher.uses_paychex?
        assert @deal.advertiser_revenue_share_percentage.blank?
        assert @deal.valid?
        @deal.publisher.publishing_group.update_attributes!(
          :uses_paychex => true,
          :paychex_initial_payment_percentage => 80.0,
          :paychex_num_days_after_which_full_payment_released => 44
        )
        assert @deal.invalid?
        assert_match /can't be blank/, @deal.errors.on(:advertiser_revenue_share_percentage)
        @deal.advertiser_revenue_share_percentage = 25
        assert @deal.valid?
      end
      
    end
    
    context "a syndicated deal" do
      
      setup do
        @syndicated_deal = Factory :distributed_daily_deal
      end
      
      should "not be required if the deal's Publisher#uses_paychex? is true but the source " +
             "Publisher#uses_paychex? is false" do
        @syndicated_deal.publisher.publishing_group.update_attributes!(
          :uses_paychex => true,
          :paychex_initial_payment_percentage => 80.0,
          :paychex_num_days_after_which_full_payment_released => 44
        )
        @syndicated_deal.source.publisher.publishing_group.update_attributes! :uses_paychex => false
        assert @syndicated_deal.advertiser_revenue_share_percentage.blank?
        assert @syndicated_deal.valid?
      end
      
      should "be required if the source Publisher#uses_paychex? is true and the deal's " +
             " Publisher#uses_paychex? is false" do
        @syndicated_deal.publisher.publishing_group.update_attributes! :uses_paychex => false
        @syndicated_deal.source.publisher.publishing_group.update_attributes!(
          :uses_paychex => true,
          :paychex_initial_payment_percentage => 80.0,
          :paychex_num_days_after_which_full_payment_released => 44
        )
        assert @syndicated_deal.advertiser_revenue_share_percentage.blank?
        assert @syndicated_deal.invalid?
        assert_match /can't be blank/, @syndicated_deal.errors.on(:advertiser_revenue_share_percentage)
        @syndicated_deal.source.update_attributes! :advertiser_revenue_share_percentage => 42
        @syndicated_deal.reload
        assert @syndicated_deal.valid?
      end
      
    end
    
  end
  
  context "#travelsavers_product_code" do
    
    should "be unique across source deals" do
      ts_deal = Factory :travelsavers_daily_deal, :available_for_syndication => true, :travelsavers_product_code => "XXX-42"
      ts_deal_2 = Factory :travelsavers_daily_deal, :travelsavers_product_code => "XXX-43"
      assert ts_deal.valid?
      assert ts_deal_2.valid?
      ts_deal_2.travelsavers_product_code = "XXX-42"
      assert ts_deal_2.invalid?
      assert_equal "Travelsavers product code must be unique across source deals", ts_deal_2.errors.on(:travelsavers_product_code)

      syndicated_ts_deal = syndicate(ts_deal, Factory(:publisher))
      assert_equal syndicated_ts_deal.travelsavers_product_code, ts_deal.travelsavers_product_code
      assert syndicated_ts_deal.valid?
    end
    
    should "be required on a source deal belonging to a publisher whose payment method is 'travelsavers'" do
      daily_deal = Factory :daily_deal
      assert !daily_deal.publisher.pay_using?(:travelsavers)
      assert daily_deal.travelsavers_product_code.blank?
      assert daily_deal.valid?
      daily_deal.publisher.update_attributes! :payment_method => "travelsavers"
      assert daily_deal.invalid?
      assert_equal "Travelsavers product code can't be blank", daily_deal.errors.on(:travelsavers_product_code)
      daily_deal.travelsavers_product_code = "CXP-BLAH"
      assert daily_deal.valid?
    end
    
    should "NOT be settable on a source deal belonging to a publisher whose payment method is not 'travelsavers'" do
      daily_deal = Factory :daily_deal
      assert daily_deal.publisher.pay_using?(:credit)
      assert daily_deal.travelsavers_product_code.blank?
      assert daily_deal.valid?
      daily_deal.travelsavers_product_code = "CXP-BLAH"
      assert daily_deal.invalid?      
      assert_equal "Travelsavers product code must be blank; this publisher does not use travelsavers", daily_deal.errors.on(:travelsavers_product_code)
    end
    
    should "not be settable on a syndicated deal, even when the publisher's payment method is 'travelsavers'" do
      syndicated_deal = Factory :distributed_daily_deal
      syndicated_deal.source.publisher.update_attributes! :payment_method => "travelsavers"
      syndicated_deal.source.update_attributes! :travelsavers_product_code => "CXP-TEST"
      syndicated_deal.reload
      assert syndicated_deal.valid?
      assert_equal "CXP-TEST", syndicated_deal.travelsavers_product_code
      syndicated_deal.travelsavers_product_code = "CXP-HACKED"
      assert syndicated_deal.invalid?
      assert_equal "Travelsavers product code must be changed in the source deal", syndicated_deal.errors.on(:travelsavers_product_code)
    end
    
    should "not be changeable after a purchase has been made on the deal" do
      %w(pending captured).each_with_index do |purchase_status, i|
        ts_deal = Factory :travelsavers_daily_deal
        assert ts_deal.travelsavers_product_code.present?
        assert ts_deal.valid?
        ts_deal.update_attributes! :travelsavers_product_code => "ABC-10000-#{i}"
        assert ts_deal.valid?
        
        Factory :"#{purchase_status}_daily_deal_purchase", :daily_deal => ts_deal
        ts_deal.daily_deal_purchases.reload
        assert ts_deal.valid?
        ts_deal.travelsavers_product_code = "ABC-10001-#{i}"
        assert ts_deal.invalid?
        assert_equal "Travelsavers product code cannot be changed", ts_deal.errors.on(:travelsavers_product_code)
        ts_deal.travelsavers_product_code = "ABC-10000-#{i}"
        assert ts_deal.valid?
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
