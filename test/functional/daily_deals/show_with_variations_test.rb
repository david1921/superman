require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::ShowWithVariationsTest < ActionController::TestCase
  tests DailyDealsController
  include DailyDealHelper

  context "publisher with variations" do
    setup do
      @publisher = Factory(:publisher, :enable_daily_deal_variations => true)
    end

    should "render the appropriate variation links for simple daily deal" do
      daily_deal = Factory(:daily_deal, :publisher => @publisher)
      variation_1 = Factory(:daily_deal_variation, :daily_deal => daily_deal, :value_proposition => "Variation 1")
      variation_2 = Factory(:daily_deal_variation, :daily_deal => daily_deal, :value_proposition => "Variation 2")
      get :show, :id => daily_deal.to_param
      assert_response :success
      assert_select ".dd_variations_menu" do
        assert_select "tr:nth-child(1)" do
          assert_select "td.value_prop", :text => variation_1.value_proposition
          assert_select "a[href='#{new_daily_deal_daily_deal_purchase_path(daily_deal, :daily_deal_variation_id => variation_1.to_param)}']"
        end
        assert_select "tr:nth-child(2)" do
          assert_select "td.value_prop", :text => variation_2.value_proposition
          assert_select "a[href='#{new_daily_deal_daily_deal_purchase_path(daily_deal, :daily_deal_variation_id => variation_2.to_param)}']"
        end
      end
    end
  end

  context "wcax publisher with variations" do

    setup do
      @wcax = Factory(:publishing_group, :label => "wcax")
    end

    should "render the appropriate variation links for simple daily deal" do
      daily_deal = Factory(:daily_deal)
      daily_deal.publisher.update_attributes(:enable_daily_deal_variations => true, :label => "wcax-vermont", :publishing_group => @wcax)
      variation_1 = Factory(:daily_deal_variation, :daily_deal => daily_deal, :value_proposition => "Variation 1" )
      variation_2 = Factory(:daily_deal_variation, :daily_deal => daily_deal, :value_proposition => "Variation 2" )
      get :show, :id => daily_deal.to_param
      assert_response :success
      assert_select ".dd_variations_menu" do
        assert_select "tr:nth-child(1)" do
          assert_select "td.value_prop", :text => variation_1.value_proposition
          assert_select "a[href='#{new_daily_deal_daily_deal_purchase_path(daily_deal, :daily_deal_variation_id => variation_1.to_param)}']"
        end
        assert_select "tr:nth-child(2)" do
          assert_select "td.value_prop", :text => variation_2.value_proposition
          assert_select "a[href='#{new_daily_deal_daily_deal_purchase_path(daily_deal, :daily_deal_variation_id => variation_2.to_param)}']"
        end
      end
    end

    should "render the appropriate variations link for a deal that has been syndicated to wcax publisher" do
      source_deal = Factory(:daily_deal_for_syndication)
      source_deal.publisher.update_attribute(:enable_daily_deal_variations, true)

      variation_1 = Factory(:daily_deal_variation, :daily_deal => source_deal, :value_proposition => "Variation 1" )
      variation_2 = Factory(:daily_deal_variation, :daily_deal => source_deal, :value_proposition => "Variation 2" )

      wcax_vermont = Factory(:publisher, :label => 'wcax-vermont', :publishing_group => @wcax, :enable_daily_deal_variations => true )
      distributed_deal = syndicate( source_deal, wcax_vermont )
      get :show, :id => distributed_deal.to_param
      assert_response :success
      assert_select ".dd_variations_menu" do
        assert_select "tr:nth-child(1)" do
          assert_select "td.value_prop", :text => variation_1.value_proposition
          assert_select "a[href='#{new_daily_deal_daily_deal_purchase_path(distributed_deal, :daily_deal_variation_id => variation_1.to_param)}']"
        end
        assert_select "tr:nth-child(2)" do
          assert_select "td.value_prop", :text => variation_2.value_proposition
          assert_select "a[href='#{new_daily_deal_daily_deal_purchase_path(distributed_deal, :daily_deal_variation_id => variation_2.to_param)}']"
        end
      end
    end

    should "not render variations that have been deleted" do
      source_deal = Factory(:daily_deal_for_syndication)
      source_deal.publisher.update_attribute(:enable_daily_deal_variations, true)

      variation_1 = Factory(:daily_deal_variation, :daily_deal => source_deal, :value_proposition => "Variation 1" )
      variation_2 = Factory(:daily_deal_variation, :daily_deal => source_deal, :value_proposition => "Variation 2", :deleted_at => 2.days.ago )

      wcax_vermont = Factory(:publisher, :label => 'wcax-vermont', :publishing_group => @wcax, :enable_daily_deal_variations => true )
      distributed_deal = syndicate( source_deal, wcax_vermont )
      get :show, :id => distributed_deal.to_param
      assert_response :success
      assert_select ".dd_variations_menu" do
        assert_select "tr:nth-child(1)" do
          assert_select "td.value_prop", :text => variation_1.value_proposition
          assert_select "a[href='#{new_daily_deal_daily_deal_purchase_path(distributed_deal, :daily_deal_variation_id => variation_1.to_param)}']"
        end
        assert_select "tr:nth-child(2)", false
      end
    end

  end
end