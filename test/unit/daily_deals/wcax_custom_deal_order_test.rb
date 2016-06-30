require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::WcaxCustomDealOrderTest

module DailyDeals

  class WcaxCustomDealOrderTest < ActiveSupport::TestCase

    context "named scope :in_custom_wcax_order" do

      setup do
        @wcax = Factory :publishing_group, :label => "wcax"
        @wcax_vermont = Factory :publisher, :publishing_group => @wcax, :label => "wcax-vermont",
                                :enable_publisher_daily_deal_categories => true
      end

      should "return nothing when there are no deals" do
        assert @wcax_vermont.daily_deals.in_custom_wcax_order.blank?
      end      

      should "sort the deals first by publisher category ID, then by syndicated deals, then by non-syndicated deals with no category" do
        other_publisher = Factory :publisher

        c1 = Factory :daily_deal_category, :publisher => @wcax_vermont, :name => "Cat 1"
        c2 = Factory :daily_deal_category, :publisher => @wcax_vermont, :name => "Cat 2"

        other_pub_deal_1 = Factory :side_daily_deal, :publisher => other_publisher, :available_for_syndication => true
        other_pub_deal_2 = Factory :side_daily_deal, :publisher => other_publisher, :available_for_syndication => true

        syndicated_deal_1 = syndicate(other_pub_deal_1, @wcax_vermont)
        syndicated_deal_2 = syndicate(other_pub_deal_1, @wcax_vermont)
        syndicated_deal_3 = syndicate(other_pub_deal_2, @wcax_vermont)
        syndicated_deal_3.publishers_category_id = c1.id
        syndicated_deal_3.save!

        deal_c1_1 = Factory :daily_deal, :publisher => @wcax_vermont, :publishers_category => c1
        deal_c2_1 = Factory :side_daily_deal, :publisher => @wcax_vermont, :publishers_category => c2
        deal_c1_2 = Factory :side_daily_deal, :publisher => @wcax_vermont, :publishers_category => c1

        deal_1_no_cat = Factory :side_daily_deal, :publisher => @wcax_vermont

        assert_equal [syndicated_deal_3, deal_c1_1, deal_c1_2, deal_c2_1, syndicated_deal_1, syndicated_deal_2, deal_1_no_cat],
                     @wcax_vermont.daily_deals.in_custom_wcax_order
      end

    end
   
  end

end
