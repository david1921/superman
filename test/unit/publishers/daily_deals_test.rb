require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Publishers::DailyDealsTest

module Publishers
  
  class DailyDealsTest < ActiveSupport::TestCase
    
    context "#available_and_recently_finished_deals" do
      
      setup do
        @publisher = Factory :publisher, :enable_publisher_daily_deal_categories => true
        @advertiser_1 = Factory :advertiser, :publisher => @publisher
        @advertiser_2 = Factory :advertiser, :publisher => @publisher
        @advertiser_1.store.update_attribute :zip, "12414"
        @advertiser_2.store.update_attribute :zip, "78782"
        @activities_category = @publisher.daily_deal_categories.create(:name => "Activies", :abbreviation => "A")
        @restaurants_category = @publisher.daily_deal_categories.create(:name => "Restaurants", :abbreviation => "R")
        @other_category = @publisher.daily_deal_categories.create(:name => "Other", :abbreviation => "O")
        @current_deal_1 = Factory :daily_deal, :advertiser => @advertiser_1, :publishers_category => @activities_category, :value_proposition => "cd1", :publisher => @publisher, :start_at => 2.days.ago, :hide_at => 3.days.from_now
        @current_deal_2 = Factory :side_daily_deal, :advertiser => @advertiser_2, :value_proposition => "cd2", :publisher => @publisher, :start_at => 1.minute.ago, :hide_at => 2.months.from_now
        @past_deal_1 = Factory :side_daily_deal, :publishers_category => @activities_category, :value_proposition => "pd1", :publisher => @publisher, :start_at => 2.weeks.ago, :hide_at => 1.week.ago
        @past_deal_2 = Factory :side_daily_deal, :publishers_category => @restaurants_category, :value_proposition => "pd2", :publisher => @publisher, :start_at => 1.month.ago, :hide_at => 12.days.ago
        @more_than_two_weeks_old_deal = Factory :side_daily_deal, :value_proposition => "olddeal", :publisher => @publisher, :start_at => 1.month.ago, :hide_at => 3.weeks.ago
      end
      
      should "return currently active deals, and deals that ended within the past two weeks, " +
             "ordered by hide_at ASC for the active deals, and hide_at DESC for the finished deals" do
        assert_equal %w(cd1 cd2 pd1 pd2), @publisher.available_and_recently_finished_deals.map { |dd| dd.value_proposition }
      end
      
      should "filter returned deals by specified category, when provided" do
        assert_equal %w(cd1 pd1), @publisher.available_and_recently_finished_deals(:categories => [@activities_category, @other_category]).map { |dd| dd.value_proposition }
      end
      
      should "filter the search to only within a limited radius, when Publisher#default_daily_deal_zip_radius is > 0" do
        @publisher.default_daily_deal_zip_radius = 25
        ZipCode.expects(:zips_near_zip_and_radius).once.with("12345", 25).returns(["78782"])
        assert_equal %w(cd2), @publisher.available_and_recently_finished_deals(:zip_code => "12345").map { |dd| dd.value_proposition }
      end
            
    end
    
  end
  
end