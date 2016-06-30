require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::SearchRequestTest

class DailyDeals::SearchRequestTest < ActiveSupport::TestCase

  context "#perform" do
    
    context "with a publisher with no daily deals" do
      
      setup do
        @publisher = Factory(:publisher)
        @response  = DailyDeals::SearchRequest.perform(:publisher => @publisher)
      end
      
      should "return a DailyDeals::SearchResponse" do
        assert @response.is_a?(DailyDeals::SearchResponse)
      end
      
      should "return a DailyDeals::SearchResponse with no daily_deals" do
        assert @response.daily_deals.empty?
      end
          
    end
    
    context "with a publisher with inactive deal" do
      
      setup do
        @publisher  = Factory(:publisher)
        @daily_deal = Factory(:daily_deal, :publisher => @publisher, :start_at => 1.year.ago, :hide_at => 6.months.ago)        
      end
      
      should "daily deal should be inactive" do
        assert !@daily_deal.active?
      end
      
      should "return a DailyDeals::SearchResponse with no daily deals" do
        assert DailyDeals::SearchRequest.perform(:publisher => @publisher).daily_deals.empty?
      end
      
    end
    
    context "with a publisher with active deals" do
      
      setup do
        @publisher    = Factory(:publisher)
        @daily_deal_1 = Factory(:featured_daily_deal, :publisher => @publisher)
        @daily_deal_2 = Factory(:side_daily_deal, :publisher => @publisher)
        @response     = DailyDeals::SearchRequest.perform(:publisher => @publisher)
      end
      
      should "return @daily_deal_1 in the daily deals for the search response" do
        assert @response.daily_deals.include?( @daily_deal_1 )
      end
      
      should "return @daily_deal_2 in the daily deals for the search response" do
        assert @response.daily_deals.include?( @daily_deal_2 )
      end
      
    end
    
    context "with a publisher with active deals, and other publishers with active deals" do
      
      setup do
        @publisher_1 = Factory(:publisher)
        @publisher_2 = Factory(:publisher)
        
        @publisher_1_daily_deal_1 = Factory(:featured_daily_deal, :publisher => @publisher_1)
        @publisher_1_daily_deal_2 = Factory(:side_daily_deal, :publisher => @publisher_1)
        @publisher_2_daily_deal_1 = Factory(:featured_daily_deal, :publisher => @publisher_2)
      end
      
      should "return only the publisher_2 daily_deals for the response for a search request on publisher_2" do
        response = DailyDeals::SearchRequest.perform(:publisher => @publisher_2)
        assert_equal 1, response.daily_deals.size
        assert response.daily_deals.include?( @publisher_2_daily_deal_1 )        
      end
      
    end
    
    context "with a publisher with active deals with categories, and we want to only bring back Entertainment and Restuarant deals by category name" do
      
      setup do
        @publisher = Factory(:publisher, :enable_publisher_daily_deal_categories => true)
        @entertainment      = Factory(:daily_deal_category, :name => "Entertainment", :publisher => @publisher)
        @restuarant         = Factory(:daily_deal_category, :name => "Restuarant", :publisher => @publisher)
        @automotive         = Factory(:daily_deal_category, :name => "Automotive", :publisher => @publisher)
        
        @entertainment_deal = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category => @entertainment)        
        @restuarant_deal    = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category => @restuarant)        
        @automative_deal    = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category => @automotive)
        
        @response = DailyDeals::SearchRequest.perform({
          :publisher => @publisher,
          :categories => ["Entertainment", "Restuarant"]
        })
      end
      
      should "return only 2 daily deals" do
        assert_equal 2, @response.daily_deals.size
      end
      
      should "have @entertainment_deal" do
        assert @response.daily_deals.include?( @entertainment_deal )
      end
      
      should "have @restuarant_deal" do
        assert @response.daily_deals.include?( @restuarant_deal )
      end
      
    end
    
    context "with a publisher with active deals with categories, and we want to only bring back Entertainment and Restuarant deals by category id" do
      
      setup do
        @publisher = Factory(:publisher, :enable_publisher_daily_deal_categories => true)
        @entertainment      = Factory(:daily_deal_category, :name => "Entertainment", :publisher => @publisher)
        @restuarant         = Factory(:daily_deal_category, :name => "Restuarant", :publisher => @publisher)
        @automotive         = Factory(:daily_deal_category, :name => "Automotive", :publisher => @publisher)
        
        @entertainment_deal = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category => @entertainment)        
        @restuarant_deal    = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category => @restuarant)        
        @automative_deal    = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category => @automotive)
        
        @response = DailyDeals::SearchRequest.perform({
          :publisher => @publisher,
          :categories => [@entertainment.id, @restuarant.id]
        })
      end
      
      should "return only 2 daily deals" do
        assert_equal 2, @response.daily_deals.size
      end
      
      should "have @entertainment_deal" do
        assert @response.daily_deals.include?( @entertainment_deal )
      end
      
      should "have @restuarant_deal" do
        assert @response.daily_deals.include?( @restuarant_deal )
      end      
      
    end    
    
    context "with a publisher with active deals, by location within 20 miles" do
      
      setup do
        stub_google_map_geocoding(37.821463,-122.478311)
        @publisher = Factory(:publisher)
        
        @daily_deal_near = Factory(:side_daily_deal, :publisher => @publisher)
        @advertiser_near = @daily_deal_near.advertiser
        @advertiser_near.stores.destroy_all
        @store_near      = Factory(:store, 
                            :advertiser => @advertiser_near, 
                            :address_line_1 => "100 Spear St", 
                            :city => "San Francisco", 
                            :state => "CA",
                            :longitude => -122.3952495, 
                            :latitude => 37.7909412)
    
        
        @daily_deal_far   = Factory(:side_daily_deal, :publisher => @publisher)
        @advertiser_far   = @daily_deal_far.advertiser
        @advertiser_far.stores.destroy_all
        @store_far        = Factory(:store, 
                            :advertiser => @advertiser_far, 
                            :address_line_1 => "1015 3rd Avenue", 
                            :city => "Seattle", 
                            :state => "WA",
                            :longitude => -122.3358812, 
                            :latitude => 47.6046576)
    
        
        @response = DailyDeals::SearchRequest.perform({
          :publisher => @publisher,
          :location => "San Francisco, CA",
          :distance => "20",
          :distance_unit => "miles"
        })
      end
      
      should "only return 1 daily deal" do
        assert_equal 1, @response.daily_deals.size
      end
            
    end
    
    context "with a publisher with active deals, by location within 32 kilometers" do
      
      setup do        
        stub_google_map_geocoding(37.821463,-122.478311)
        @publisher = Factory(:publisher)
        
        @daily_deal_near = Factory(:side_daily_deal, :publisher => @publisher)
        @advertiser_near = @daily_deal_near.advertiser
        @advertiser_near.stores.destroy_all
        @store_near      = Factory(:store, 
                            :advertiser => @advertiser_near, 
                            :address_line_1 => "100 Spear St", 
                            :city => "San Francisco", 
                            :state => "CA",
                            :longitude => -122.3952495, 
                            :latitude => 37.7909412)
        
        @daily_deal_far   = Factory(:side_daily_deal, :publisher => @publisher)
        @advertiser_far   = @daily_deal_far.advertiser
        @advertiser_far.stores.destroy_all
        @store_far        = Factory(:store, 
                            :advertiser => @advertiser_far, 
                            :address_line_1 => "1015 3rd Avenue", 
                            :city => "Seattle", 
                            :state => "WA",
                            :longitude => -122.3358812, 
                            :latitude => 47.6046576)
  
        @response = DailyDeals::SearchRequest.perform({
          :publisher => @publisher,
          :location => "San Francisco, CA",
          :distance => "20",
          :distance_unit => "km"
        })
      end
      
      should "only return 1 daily deal" do
        assert_equal 1, @response.daily_deals.size
      end
            
    end    
    
    context "search request with sorting on price" do
      
      setup do
        @publisher = Factory(:publisher)
        @daily_deal_1 = Factory(:side_daily_deal, :price => 100.00, :publisher => @publisher)
        @daily_deal_2 = Factory(:side_daily_deal, :price => 105.00, :publisher => @publisher)
        @daily_deal_3 = Factory(:side_daily_deal, :price => 99.00, :publisher => @publisher)
        
        @response = DailyDeals::SearchRequest.perform({
          :publisher      => @publisher,
          :sort_by        => "price",
          :sort_direction => "ascending"
        })
      end
      
      should "return 3 daily deals in order of lowest price to highest price" do
        assert_equal [@daily_deal_3, @daily_deal_1, @daily_deal_2], @response.daily_deals
      end
      
    end
    
    context "search request with sorting on newest (start_at date descending)" do
      
      setup do
        @publisher    = Factory(:publisher)
        @daily_deal_1 = Factory(:side_daily_deal, :publisher => @publisher, :start_at => 3.hours.ago)
        @daily_deal_2 = Factory(:side_daily_deal, :publisher => @publisher, :start_at => 1.hour.ago)
        @daily_deal_3 = Factory(:side_daily_deal, :publisher => @publisher, :start_at => 2.hours.ago)
        
        @response = DailyDeals::SearchRequest.perform({
          :publisher      => @publisher,
          :sort_by        => "start_at",
          :sort_direction => "descending"
        })
      end
      
      should "return 3 daily deals in order of start date newest to oldest" do
        assert_equal [@daily_deal_2, @daily_deal_3, @daily_deal_1], @response.daily_deals
      end
            
    end
    
    context "search request with sorting on title (value prop) ascending (A-Z)" do
      
      setup do
        @publisher    = Factory(:publisher)
        @daily_deal_1 = Factory(:side_daily_deal, :publisher => @publisher, :value_proposition => "ABC")
        @daily_deal_2 = Factory(:side_daily_deal, :publisher => @publisher, :value_proposition => "GHI")
        @daily_deal_3 = Factory(:side_daily_deal, :publisher => @publisher, :value_proposition => "DEF")
        
        @response = DailyDeals::SearchRequest.perform({
          :publisher => @publisher,
          :sort_by => "title",
          :sort_direction => "ascending"
        })
      end
      
      should "return 3 daily deals sorted by title in the direction of A-Z" do
        assert_equal [@daily_deal_1, @daily_deal_3, @daily_deal_2], @response.daily_deals
      end
      
    end
    
    context "search request with page and page_size" do
      
      setup do
        @publisher = Factory(:publisher)
        1.upto(10).each do 
          Factory(:side_daily_deal, :publisher => @publisher)
        end
      end
      
      should "return all for page 1 with page size 10" do
        assert_equal 10, DailyDeals::SearchRequest.perform({
          :publisher => @publisher,
          :page => 1,
          :page_size => 10
        }).daily_deals.size
      end
      
      should "return 5 for page 2 with page size 5" do
        assert_equal 5, DailyDeals::SearchRequest.perform({
          :publisher => @publisher,
          :page => 2,
          :page_size => 5
        }).daily_deals.size
      end
      
    end
    
  end

end