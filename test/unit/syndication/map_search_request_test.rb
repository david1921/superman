require File.dirname(__FILE__) + "/../../test_helper"

class Syndication::MapSearchRequestTest < ActiveSupport::TestCase
  
  
  context "perform" do
    
    setup do
      @travel     = Factory(:daily_deal_category, :name => "Travel")
      @automotive = Factory(:daily_deal_category,:name => "Automotive")
      @education  = Factory(:daily_deal_category,:name => "Education")
      @food  = Factory(:daily_deal_category,:name => "food")

      @publisher = Factory(:publisher, :self_serve => true, :google_map_latitude => 45.67655, :google_map_longitude => -122.204933)

      @user = Factory(:user, :company => @publisher, :allow_syndication_access => true)
      @distributing_publisher = Factory(:publisher)
      @publisher_not_in_network = Factory(:publisher, :in_syndication_network => false, :self_serve => true)

      @publisher_excluded_by_publisher = Factory(:publisher)
      @publisher_excluded_by_publisher.publishers_excluded_from_distribution << @publisher
      @publisher_excluded_by_publisher.save!

      #These deals should never be included
      @deal_of_publisher_not_in_network = Factory(:daily_deal, 
                                                  :publisher => @publisher_not_in_network, 
                                                  :start_at => 5.days.from_now, 
                                                  :hide_at => 6.days.from_now,
                                                  :price => 5.0,
                                                  :national_deal => true)
      @deal_of_publisher_excluded_by_publisher = Factory(:daily_deal_for_syndication, 
                                                         :publisher => @publisher_excluded_by_publisher, 
                                                         :start_at => 5.days.from_now, 
                                                         :hide_at => 6.days.from_now,
                                                         :analytics_category => @travel)
      @deal_not_owned_by_publisher_and_not_available_for_syndication = Factory(:daily_deal,
                                                                               :start_at => 3.days.ago,
                                                                               :hide_at => 6.days.from_now,
                                                                               :price => 6.0)

      @deal_over = Factory(:daily_deal_for_syndication, :publisher => @publisher, :start_at => 9.days.ago, :hide_at => 8.days.ago)
      #These deals are returned by default and are filtered
      @deal_owned_by_publisher_and_not_available_for_syndication = Factory(:daily_deal,
                                                                           :publisher => @publisher,
                                                                           :start_at => 3.days.ago,
                                                                           :hide_at => 2.days.from_now,
                                                                           :price => 1.0)
      @deal_sourced_by_publisher = Factory(:daily_deal_for_syndication, 
                                           :publisher => @publisher, 
                                           :start_at => 3.days.from_now, 
                                           :hide_at => 4.days.from_now,
                                           :price => 3.0,
                                           :national_deal => true)
      @deal_sourced_by_publisher_and_distributed_by_network = Factory(:daily_deal_for_syndication, 
                                                                      :publisher => @publisher, 
                                                                      :start_at => 5.days.from_now, 
                                                                      :hide_at => 6.days.from_now,
                                                                      :price => 4.0,
                                                                      :value_proposition => '$50 worth of food for $20')
      @deal_sourced_by_network = Factory(:daily_deal_for_syndication, 
                                         :start_at => 3.days.from_now, 
                                         :hide_at => 4.days.from_now,
                                         :price => 7.0,
                                         :national_deal => true)
      @deal_sourced_by_network_and_distributed_by_network = Factory(:daily_deal_for_syndication, 
                                                                    :start_at => 7.days.from_now, 
                                                                    :hide_at => 8.days.from_now,
                                                                    :price => 8.0,
                                                                    :analytics_category => @travel)

      @distributed_deal_sourced_by_publisher_and_distributed_by_network = @deal_sourced_by_publisher_and_distributed_by_network.syndicated_deals.build(:publisher_id => @distributing_publisher.id)
      @deal_sourced_by_publisher_and_distributed_by_network.save!

      @distributed_deal_sourced_by_network_and_distributed_by_network = @deal_sourced_by_network_and_distributed_by_network.syndicated_deals.build(:publisher_id => @distributing_publisher.id)
      @deal_sourced_by_network_and_distributed_by_network.save!

      @distributed_deal_sourced_by_network_and_distributed_by_publisher = @deal_sourced_by_network_and_distributed_by_network.syndicated_deals.build(:publisher_id => @publisher.id)
      @deal_sourced_by_network_and_distributed_by_network.save!      
    end
    
    context "with page 1 and page size 4" do
      
      setup do
        @search_request = Syndication::MapSearchRequest.new
        @search_request.publisher = @publisher
        @search_request.paging.page_size = 4
        @deals = @search_request.perform.deals
      end
      
      should "return all applicable deals" do
        assert !@deals.include?(@deal_of_publisher_not_in_network)
        assert !@deals.include?(@deal_of_publisher_excluded_by_publisher)
        assert !@deals.include?(@deal_not_owned_by_publisher_and_not_available_for_syndication)
        assert @deals.include?(@deal_owned_by_publisher_and_not_available_for_syndication)
        assert @deals.include?(@deal_sourced_by_publisher)
        assert @deals.include?(@deal_sourced_by_publisher_and_distributed_by_network)
        assert @deals.include?(@deal_sourced_by_network)
        assert @deals.include?(@deal_sourced_by_network_and_distributed_by_network)
        assert @deals.include?(@distributed_deal_sourced_by_publisher_and_distributed_by_network)
        assert @deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_network)
        assert @deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_publisher)
        assert !@deals.include?(@deal_over)
      end
      
      should "return all 8 deals" do
        assert_equal 8, @deals.size
      end
      
      should "set page_size to 4" do
        assert_equal 4, @search_request.paging.page_size
      end
      
      should "set current_page to 1" do
        assert_equal 1, @search_request.paging.current_page
      end
      
      
    end
    
    context "with a page size of 3 and page 2" do
      
      setup do
        @search_request = Syndication::MapSearchRequest.new( :paging => {:page_size => 3, :current_page => 3} )
        @search_request.publisher = @publisher
      end
      
      should "return all 8 deals" do
        assert_equal 8, @search_request.perform.deals.size
      end        
      
      should "set page_size to 3" do
        assert_equal 3, @search_request.paging.page_size
      end
      
      should "set current_page to 3" do
        assert_equal 3, @search_request.paging.current_page
      end
      
    end
    
  end
  
  context "filter" do
    
    setup do
      @publisher = Factory(:publisher)
    end
    
    context "with location and radius set" do
      
      setup do
        @search_request = Syndication::MapSearchRequest.new( :filter => {:location => "97206", :radius => "100"}, :publisher => @publisher )
      end
      
      should "use publisher latittude for search request latitude" do
        assert_equal @publisher.google_map_latitude, @search_request.latitude
      end
      
      should "use publisher longitude for search request longitude" do
        assert_equal @publisher.google_map_longitude, @search_request.longitude
      end
      
    end
    
    context "with blank location and bounds attributes" do
      
      setup do
        @bounds_attributes  = { :ne => "30.534298295161715,-97.702931237793", :sw => "30.15801914151126,-98.09363253173831", :center => "30.34615871833649,-97.89828188476565", :zoom => "11" }
        @lat_lng            = Geokit::LatLng.normalize(@bounds_attributes[:center])
        @search_request     = Syndication::MapSearchRequest.new( :filter => {:location => "", :radius => "100"}, :bounds => @bounds_attributes, :publisher => @publisher )
      end
      
      should "use the bounds center latitude for the search request latitude" do
        assert_equal @lat_lng.lat, @search_request.latitude
      end
      
      should "use the bounds center longitude for the search request longitude" do
        assert_equal @lat_lng.lng, @search_request.longitude
      end
      
    end
    
    context "with 'Zip Code' location and bounds attributes" do
      
      setup do
        @bounds_attributes  = { :ne => "30.534298295161715,-97.702931237793", :sw => "30.15801914151126,-98.09363253173831", :center => "30.34615871833649,-97.89828188476565", :zoom => "11" }
        @lat_lng            = Geokit::LatLng.normalize(@bounds_attributes[:center])
        @search_request     = Syndication::MapSearchRequest.new( :filter => {:location => "Zip Code", :radius => "100"}, :bounds => @bounds_attributes, :publisher => @publisher )
      end
      
      should "use the bounds center latitude for the search request latitude" do
        assert_equal @lat_lng.lat, @search_request.latitude
      end
      
      should "use the bounds center longitude for the search request longitude" do
        assert_equal @lat_lng.lng, @search_request.longitude
      end
      
    end
    
    context "with blank location and missing bounds attributes" do
      
      setup do
        @bounds_attributes  = {}
        @lat_lng            = Geokit::LatLng.normalize( Syndication::MapSearchRequest::Bounds::DEFAULT_CENTER ) 
        @search_request     = Syndication::MapSearchRequest.new( :filter => {:location => "", :radius => "100"}, :bounds => @bounds_attributes, :publisher => @publisher )
      end
      
      should "use default center latittude for search request latitude" do
        assert_equal @lat_lng.lat, @search_request.latitude
      end
      
      should "use default center longitude for search request longitude" do
        assert_equal @lat_lng.lng, @search_request.longitude
      end      
      
    end
    
  end
  
end