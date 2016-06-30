require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::SearchResponseTest

class DailyDeals::SearchResponseTest < ActiveSupport::TestCase
  
  context "#new" do
    
    context "with nil daily deals" do
      
      should "return an empty array for daily deals" do
        assert DailyDeals::SearchResponse.new.daily_deals.empty?
      end
      
    end
    
    context "with daily deals" do
      
      should "return the array of daily deals used to initialize the search response" do
        daily_deals = %w( deal_1 deal_2 deal_3 )
        assert_equal daily_deals, DailyDeals::SearchResponse.new(daily_deals).daily_deals
      end
      
    end
    
  end
end