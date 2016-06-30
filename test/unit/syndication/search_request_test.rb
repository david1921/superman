require File.dirname(__FILE__) + "/../../test_helper"

class Syndication::SearchRequestTest < ActiveSupport::TestCase
  
  #Location and radius tests are in Syndication::SearchRequestLocationTest since they 
  #required a different setup
  
  def setup
    
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
  
  fast_context "all deals" do
    setup do
      @search_request = Syndication::SearchRequest.new
      @search_request.publisher = @publisher
      @search_request.paging.page_size = 200
      @deals = @search_request.perform.deals
    end
    
    should "include all applicable deals" do
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
    
    should "return latitude based on publisher google map latitude setting" do
      assert_equal @publisher.reload.google_map_latitude, @search_request.latitude
    end
    
    should "return longitude based on publisher google map longitude setting" do
      assert_equal @publisher.reload.google_map_longitude, @search_request.longitude
    end
    
  end
  
  fast_context "paging" do
    fast_context "with page size of 5 and current page of 1" do
    
      setup do
        @search_request = Syndication::SearchRequest.new( :paging => {:page_size => 5, :current_page => 1} )
        @search_request.publisher = @publisher
      end
      
      should "return just 5 daily deals" do
        assert_equal 5, @search_request.perform.deals.size
      end
    
    end
    
    fast_context "with a page size of 3 and page 2" do
      
      setup do
        @search_request = Syndication::SearchRequest.new( :paging => {:page_size => 3, :current_page => 3} )
        @search_request.publisher = @publisher
      end
      
      should "return just 2 daily deals" do
        assert_equal 2, @search_request.perform.deals.size
      end        
      
    end
  end
  
  fast_context "sort deals" do
    setup do
      @search_request = Syndication::SearchRequest.new
      @search_request.publisher = @publisher
    end
    
    fast_context "date ascending" do
      should "order by earliest to latest date" do
        @search_request.sort = Syndication::SearchRequest::Sort::START_DATE_ASCENDING
        deals = @search_request.perform.deals
        assert deals.first.start_at < deals.last.start_at
      end
    end
    
    fast_context "date descending" do
      should "order by latest to earliest date" do
        @search_request.sort = Syndication::SearchRequest::Sort::START_DATE_DESCENDING
        deals = @search_request.perform.deals
        assert deals.first.start_at > deals.last.start_at
      end
    end
    
    fast_context "price ascending" do
      should "order by lowest to highest price" do
        @search_request.sort = Syndication::SearchRequest::Sort::PRICE_ASCENDING
        deals = @search_request.perform.deals
        assert deals.first.price < deals.last.price
      end
    end
    
    fast_context "price descending" do
      should "order by highest to lowest price" do
        @search_request.sort = Syndication::SearchRequest::Sort::PRICE_DESCENDING
        deals = @search_request.perform.deals
        assert deals.first.price > deals.last.price
      end
    end
  end
  
  fast_context "text search" do
    
    setup do
      @advertiser = Factory(:advertiser, :name => "great food restaurant")
      @deal_with_keyword_in_advertiser_name = Factory(:daily_deal_for_syndication, 
                                                      :publisher => @advertiser.publisher, 
                                                      :advertiser => @advertiser)
      @deal_with_keyword_in_category = Factory(:daily_deal_for_syndication, :analytics_category => @food)
      
      @search_request = Syndication::SearchRequest.new(:filter => { :text => "food" })
      @search_request.publisher = @publisher
      @deals = @search_request.perform.deals
    end
    
    should "return deals with text in advertiser name, category or value proposition" do
      assert !@deals.include?(@deal_of_publisher_not_in_network)
      assert !@deals.include?(@deal_of_publisher_excluded_by_publisher)
      assert !@deals.include?(@deal_not_owned_by_publisher_and_not_available_for_syndication)
      assert !@deals.include?(@deal_owned_by_publisher_and_not_available_for_syndication)
      assert !@deals.include?(@deal_sourced_by_publisher)
      assert @deals.include?(@deal_sourced_by_publisher_and_distributed_by_network)
      assert !@deals.include?(@deal_sourced_by_network)
      assert !@deals.include?(@deal_sourced_by_network_and_distributed_by_network)
      assert @deals.include?(@distributed_deal_sourced_by_publisher_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_publisher)
      assert @deals.include?(@deal_with_keyword_in_advertiser_name)
      assert @deals.include?(@deal_with_keyword_in_category)
      assert !@deals.include?(@deal_over)
    end
    
  end
  
  fast_context "filter by categories" do
    setup do
      @search_request = Syndication::SearchRequest.new( :filter => { :categories => [@travel.id.to_s] } )
      @search_request.publisher = @publisher
      @deals = @search_request.perform.deals
    end
            
    should "return deals in @travel category" do
      assert !@deals.include?(@deal_of_publisher_not_in_network)
      assert !@deals.include?(@deal_of_publisher_excluded_by_publisher)
      assert !@deals.include?(@deal_not_owned_by_publisher_and_not_available_for_syndication)
      assert !@deals.include?(@deal_owned_by_publisher_and_not_available_for_syndication)
      assert !@deals.include?(@deal_sourced_by_publisher)
      assert !@deals.include?(@deal_sourced_by_publisher_and_distributed_by_network)
      assert !@deals.include?(@deal_sourced_by_network)
      assert @deals.include?(@deal_sourced_by_network_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_publisher_and_distributed_by_network)
      assert @deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_network)
      assert @deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_publisher)
      assert !@deals.include?(@deal_over)
    end
        
    should "return 0 deals for @automotive category" do
      @search_request = Syndication::SearchRequest.new( :filter => { :categories => [@automotive.id.to_s] } )
      @search_request.publisher = @publisher
      @deals = @search_request.perform.deals
      assert_equal 0, @deals.size
    end
    
  end
  
  fast_context "filter by national deals" do
    
    setup do
      @search_request = Syndication::SearchRequest.new( :filter => { :national_deals => true } ) 
      @search_request.publisher = @publisher
      @deals = @search_request.perform.deals
    end
    
    should "return national deals" do
      assert !@deals.include?(@deal_of_publisher_not_in_network)
      assert !@deals.include?(@deal_of_publisher_excluded_by_publisher)
      assert !@deals.include?(@deal_not_owned_by_publisher_and_not_available_for_syndication)
      assert !@deals.include?(@deal_owned_by_publisher_and_not_available_for_syndication)
      assert @deals.include?(@deal_sourced_by_publisher)
      assert !@deals.include?(@deal_sourced_by_publisher_and_distributed_by_network)
      assert @deals.include?(@deal_sourced_by_network)
      assert !@deals.include?(@deal_sourced_by_network_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_publisher_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_publisher)
      assert !@deals.include?(@deal_over)
    end
  end
    
  fast_context "filter by date" do
    
    fast_context "start date of 3 days ago" do
    
      setup do
        @search_request = Syndication::SearchRequest.new( :filter => { :start_date => (Time.zone.now - 3.days).to_s(:compact) } )
        @search_request.publisher = @publisher
        @deals = @search_request.perform.deals
      end
      
      should "return 1 deal" do
        assert !@deals.include?(@deal_of_publisher_not_in_network)
        assert !@deals.include?(@deal_of_publisher_excluded_by_publisher)
        assert !@deals.include?(@deal_not_owned_by_publisher_and_not_available_for_syndication)
        assert @deals.include?(@deal_owned_by_publisher_and_not_available_for_syndication)
        assert !@deals.include?(@deal_sourced_by_publisher)
        assert !@deals.include?(@deal_sourced_by_publisher_and_distributed_by_network)
        assert !@deals.include?(@deal_sourced_by_network)
        assert !@deals.include?(@deal_sourced_by_network_and_distributed_by_network)
        assert !@deals.include?(@distributed_deal_sourced_by_publisher_and_distributed_by_network)
        assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_network)
        assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_publisher)
        assert !@deals.include?(@deal_over)
      end
      
    end
    
    fast_context "with just an end date of 6 days from now" do
      
      setup do
        @search_request = Syndication::SearchRequest.new( :filter => { :end_date => (Time.zone.now + 6.days).to_s(:compact) } )
        @search_request.publisher = @publisher
        @deals = @search_request.perform.deals
      end
      
      should "return 2 deals" do
        assert !@deals.include?(@deal_of_publisher_not_in_network)
        assert !@deals.include?(@deal_of_publisher_excluded_by_publisher)
        assert !@deals.include?(@deal_not_owned_by_publisher_and_not_available_for_syndication)
        assert !@deals.include?(@deal_owned_by_publisher_and_not_available_for_syndication)
        assert !@deals.include?(@deal_sourced_by_publisher)
        assert @deals.include?(@deal_sourced_by_publisher_and_distributed_by_network)
        assert !@deals.include?(@deal_sourced_by_network)
        assert !@deals.include?(@deal_sourced_by_network_and_distributed_by_network)
        assert @deals.include?(@distributed_deal_sourced_by_publisher_and_distributed_by_network)
        assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_network)
        assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_publisher)
        assert !@deals.include?(@deal_over)
      end
    
    end
          
    fast_context "with start date 3 days from now and end date of 4 days from now" do
      
      setup do
        @search_request = Syndication::SearchRequest.new( :filter => { :start_date => (Time.zone.now + 3.days).to_s(:compact), :end_date => (Time.zone.now + 4.days).to_s(:compact) } )
        @search_request.publisher = @publisher
        @deals = @search_request.perform.deals
      end
      
      should "return 2 deals" do
        assert !@deals.include?(@deal_of_publisher_not_in_network)
        assert !@deals.include?(@deal_of_publisher_excluded_by_publisher)
        assert !@deals.include?(@deal_not_owned_by_publisher_and_not_available_for_syndication)
        assert !@deals.include?(@deal_owned_by_publisher_and_not_available_for_syndication)
        assert @deals.include?(@deal_sourced_by_publisher)
        assert !@deals.include?(@deal_sourced_by_publisher_and_distributed_by_network)
        assert @deals.include?(@deal_sourced_by_network)
        assert !@deals.include?(@deal_sourced_by_network_and_distributed_by_network)
        assert !@deals.include?(@distributed_deal_sourced_by_publisher_and_distributed_by_network)
        assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_network)
        assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_publisher)
        assert !@deals.include?(@deal_over)
      end
      
    end
    
  end
  
  fast_context "filter by sourceable_by_publisher" do
    setup do        
      @search_request = Syndication::SearchRequest.new
      @search_request.publisher = @publisher
      @search_request.status = :sourceable_by_publisher
      @deals = @search_request.perform.deals
    end
    
    should "should only return deals sourced by publisher" do
      assert !@deals.include?(@deal_of_publisher_not_in_network)
      assert !@deals.include?(@deal_of_publisher_excluded_by_publisher)
      assert !@deals.include?(@deal_not_owned_by_publisher_and_not_available_for_syndication)
      assert @deals.include?(@deal_owned_by_publisher_and_not_available_for_syndication)
      assert @deals.include?(@deal_sourced_by_publisher)
      assert @deals.include?(@deal_sourced_by_publisher_and_distributed_by_network)
      assert !@deals.include?(@deal_sourced_by_network)
      assert !@deals.include?(@deal_sourced_by_network_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_publisher_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_publisher)
      assert !@deals.include?(@deal_over)
    end
  end
  
  fast_context "filter by sourced_by_publisher" do
    setup do        
      @search_request = Syndication::SearchRequest.new
      @search_request.publisher = @publisher
      @search_request.status = :sourced_by_publisher
      @deals = @search_request.perform.deals
    end
    
    should "should only return deals sourced by publisher" do
      assert !@deals.include?(@deal_of_publisher_not_in_network)
      assert !@deals.include?(@deal_of_publisher_excluded_by_publisher)
      assert !@deals.include?(@deal_not_owned_by_publisher_and_not_available_for_syndication)
      assert !@deals.include?(@deal_owned_by_publisher_and_not_available_for_syndication)
      assert @deals.include?(@deal_sourced_by_publisher)
      assert @deals.include?(@deal_sourced_by_publisher_and_distributed_by_network)
      assert !@deals.include?(@deal_sourced_by_network)
      assert !@deals.include?(@deal_sourced_by_network_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_publisher_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_publisher)
      assert !@deals.include?(@deal_over)
    end
  end
  
  fast_context "filter by sourced_by_network" do
    setup do        
      @search_request = Syndication::SearchRequest.new
      @search_request.publisher = @publisher
      @search_request.status = :sourced_by_network
      @deals = @search_request.perform.deals
    end
    
    should "should only return deals sourced by other publisher in network" do
      assert !@deals.include?(@deal_of_publisher_not_in_network)
      assert !@deals.include?(@deal_of_publisher_excluded_by_publisher)
      assert !@deals.include?(@deal_not_owned_by_publisher_and_not_available_for_syndication)
      assert !@deals.include?(@deal_owned_by_publisher_and_not_available_for_syndication)
      assert !@deals.include?(@deal_sourced_by_publisher)
      assert !@deals.include?(@deal_sourced_by_publisher_and_distributed_by_network)
      assert @deals.include?(@deal_sourced_by_network)
      assert @deals.include?(@deal_sourced_by_network_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_publisher_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_publisher)
      assert !@deals.include?(@deal_over)
    end
  end
  
  fast_context "filter by distributed_by_publisher" do
    setup do        
      @search_request = Syndication::SearchRequest.new
      @search_request.publisher = @publisher
      @search_request.status = :distributed_by_publisher
      @deals = @search_request.perform.deals
    end
    
    should "should only return deals distributed by publisher" do
      assert !@deals.include?(@deal_of_publisher_not_in_network)
      assert !@deals.include?(@deal_of_publisher_excluded_by_publisher)
      assert !@deals.include?(@deal_not_owned_by_publisher_and_not_available_for_syndication)
      assert !@deals.include?(@deal_owned_by_publisher_and_not_available_for_syndication)
      assert !@deals.include?(@deal_sourced_by_publisher)
      assert !@deals.include?(@deal_sourced_by_publisher_and_distributed_by_network)
      assert !@deals.include?(@deal_sourced_by_network)
      assert !@deals.include?(@deal_sourced_by_network_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_publisher_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_network)
      assert @deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_publisher)
      assert !@deals.include?(@deal_over)
    end
  end
  
  fast_context "filter by distributed_by_network" do
    setup do        
      @search_request = Syndication::SearchRequest.new
      @search_request.publisher = @publisher
      @search_request.status = :distributed_by_network
      @deals = @search_request.perform.deals
    end
    
    should "should only return source deals distributed by publishers in network" do
      assert !@deals.include?(@deal_of_publisher_not_in_network)
      assert !@deals.include?(@deal_of_publisher_excluded_by_publisher)
      assert !@deals.include?(@deal_not_owned_by_publisher_and_not_available_for_syndication)
      assert !@deals.include?(@deal_owned_by_publisher_and_not_available_for_syndication)
      assert !@deals.include?(@deal_sourced_by_publisher)
      assert @deals.include?(@deal_sourced_by_publisher_and_distributed_by_network)
      assert !@deals.include?(@deal_sourced_by_network)
      assert @deals.include?(@deal_sourced_by_network_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_publisher_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_network)
      assert !@deals.include?(@distributed_deal_sourced_by_network_and_distributed_by_publisher)
      assert !@deals.include?(@deal_over)
    end
  end
  
end
