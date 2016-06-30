require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::EntercomSideDealOrderingTest

module DailyDeals
  
  class EntercomSideDealOrderingTest < ActiveSupport::TestCase
    
    context "DailyDeal#side_deals_in_custom_entercom_order" do
      
      setup do
        @publisher = Factory :publisher, :label => "entercom-sacramento", :enable_publisher_daily_deal_categories => true
        
        @cat_deal_1 = Factory :daily_deal_category, :name => "Deal 1", :publisher => @publisher
        @cat_deal_3 = Factory :daily_deal_category, :name => "Deal 3", :publisher => @publisher
        @cat_deal_10 = Factory :daily_deal_category, :name => "Deal 10", :publisher => @publisher
        @cat_syndicated = Factory :daily_deal_category, :name => "Syndicated", :publisher => @publisher
        @cat_other = Factory :daily_deal_category, :name => "Other", :publisher => @publisher
        
        @other_pubs_deal_1 = Factory :side_daily_deal, :available_for_syndication => true, :value_proposition => "opd1", :start_at => 100.minutes.ago, :hide_at => 1.week.from_now
        @other_pubs_deal_2 = Factory :side_daily_deal, :available_for_syndication => true, :value_proposition => "opd2", :start_at => 95.minutes.ago, :hide_at => 2.weeks.from_now
        @other_pubs_deal_3 = Factory :side_daily_deal, :available_for_syndication => true, :value_proposition => "opd3", :start_at => 93.minutes.ago, :hide_at => 1.week.from_now
        @featured_deal = Factory :featured_daily_deal, :value_proposition => "fd", :publisher => @publisher, :start_at => 90.minutes.ago, :hide_at => 1.day.from_now
        @inactive_deal_cat_deal_1 = Factory :side_daily_deal, :value_proposition => "inactive", :publisher => @publisher, :publishers_category => @cat_deal_1, :start_at => 85.minutes.ago, :hide_at => 10.minutes.ago
        @sd1_cat_deal_1 = Factory :side_daily_deal, :value_proposition => "sd1", :publisher => @publisher, :publishers_category => @cat_deal_1, :start_at => 85.minutes.ago, :hide_at => 1.hour.from_now
        @sd2_cat_deal_3 = Factory :side_daily_deal, :value_proposition => "sd2", :publisher => @publisher, :publishers_category => @cat_deal_3, :start_at => 90.minutes.ago, :hide_at => 1.month.from_now
        @sd3_cat_deal_3 = Factory :side_daily_deal, :value_proposition => "sd3", :publisher => @publisher, :publishers_category => @cat_deal_3, :start_at => 95.minutes.ago, :hide_at => 10.hours.from_now
        @sd4_cat_deal_10 = Factory :side_daily_deal, :value_proposition => "sd4", :publisher => @publisher, :publishers_category => @cat_deal_10, :start_at => 70.minutes.ago, :hide_at => 1.week.from_now
        @sd5_cat_deal_10 = syndicate(@other_pubs_deal_1, @publisher)
        @sd5_cat_deal_10.update_attribute :publishers_category_id, @cat_deal_10.id
        @sd6_cat_other = Factory :side_daily_deal, :value_proposition => "sd6", :publisher => @publisher, :publishers_category => @cat_other, :start_at => 65.minutes.ago, :hide_at => 1.week.from_now
        @sd7_no_cat_non_syndicated = Factory :side_daily_deal, :value_proposition => "sd7", :publisher => @publisher, :publishers_category => nil, :start_at => 60.minutes.ago, :hide_at => 1.week.from_now
        @sd8_no_cat_syndicated = syndicate(@other_pubs_deal_2, @publisher)
        @sd9_cat_syndicated_non_syndicated = Factory :side_daily_deal, :value_proposition => "sd9", :publisher => @publisher, :publishers_category => @cat_syndicated, :start_at => 55.minutes.ago, :hide_at => 1.week.from_now
        @sd10_cat_syndicated_and_syndicated_deal = syndicate(@other_pubs_deal_3, @publisher)
        @sd10_cat_syndicated_and_syndicated_deal.update_attribute :publishers_category_id, @cat_syndicated.id
        
        @side_deals = @featured_deal.side_deals_in_custom_entercom_order
        @side_deals_through_publisher = @publisher.side_deals_in_custom_entercom_order
      end
      
      should "return only active side deals that belong to the given publisher that are: " +
             "in categories Deal 1 through Deal 10, or non-syndicated deals with no publisher category, " +
             "or any active side deals in the 'Syndicated' category" do
        assert_equal 8, @side_deals.length
      end
      
      should "sort deals in categories Deal 1 through Deal 10 first, first by cat name, then by start date descending" do
        assert_equal ["sd1", "sd2", "sd3", "sd4", "opd1"], @side_deals[0..4].map(&:value_proposition)
      end
      
      should "sort non-syndicated deals with no publisher category next, by start date" do
        assert_equal "sd7", @side_deals[5].value_proposition
      end
      
      should "sort deals in the category 'Syndicated' last, by start date descending" do
        assert_equal ["sd9", "opd3"], @side_deals[6..7].map(&:value_proposition)
      end
      
      should "sort the deals in the same way through Publisher#side_deals_in_custom_entercom_order" do
        assert_equal ["sd1", "sd2", "sd3", "sd4", "opd1", "sd7", "sd9", "opd3"],
                     @side_deals_through_publisher.map(&:value_proposition)
      end
      
    end
    
  end
  
end