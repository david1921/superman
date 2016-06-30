require File.dirname(__FILE__) + "/../../test_helper"


class Syndication::SearchRequestLocationTest < ActiveSupport::TestCase
  
  def setup
    @publisher = Factory(:publisher)
    
    @zip_78704 = Factory(:zip_code, :zip => "78704", :latitude => 30.241524, :longitude => -97.76877)
    @zip_78765 = Factory(:zip_code, :zip => "78765", :latitude => 30.2667, :longitude => -97.7428)
    @zip_98671 = Factory(:zip_code, :zip => "98671", :latitude => 45.67655, :longitude => -122.204933)
    
    @advertiser_1 = Factory(:advertiser_without_stores, :publisher => @publisher, :name => "advertiser_1")
    @store_1 = Factory(:store, :advertiser => @advertiser_1, :zip => "78704")
    @store_2 = Factory(:store, :advertiser => @advertiser_1, :zip => "78777")
    @advertiser_2 = Factory(:advertiser_without_stores, :publisher => @publisher, :name => "advertiser_2")
    @store_3 = Factory(:store, :advertiser => @advertiser_2, :zip => "78704-1234")
    @advertiser_3 = Factory(:advertiser_without_stores, :publisher => @publisher, :name => "advertiser_3")
    @store_4 = Factory(:store, :advertiser => @advertiser_3, :zip => "98671")
    @advertiser_4 = Factory(:advertiser_without_stores, :publisher => @publisher, :name => "advertiser_4")
    @store_5 = Factory(:store, :advertiser => @advertiser_4, :zip => "78765")
    
    @deal_1 = Factory(:daily_deal_for_syndication,
                      :publisher => @publisher, 
                      :advertiser => @advertiser_1, 
                      :start_at => 1.days.from_now, 
                      :hide_at => 2.days.from_now)
    @deal_2 = Factory(:daily_deal_for_syndication, 
                      :publisher => @publisher, 
                      :advertiser => @advertiser_1, 
                      :start_at => 3.days.from_now, 
                      :hide_at => 4.days.from_now)
    @deal_3 = Factory(:daily_deal_for_syndication, 
                      :publisher => @publisher, 
                      :advertiser => @advertiser_2, 
                      :start_at => 5.days.from_now, 
                      :hide_at => 6.days.from_now)
    @deal_4 = Factory(:daily_deal_for_syndication, 
                      :publisher => @publisher, 
                      :advertiser => @advertiser_3, 
                      :start_at => 7.days.from_now, 
                      :hide_at => 8.days.from_now)
    @deal_5 = Factory(:daily_deal_for_syndication, 
                      :publisher => @publisher, 
                      :advertiser => @advertiser_4, 
                      :start_at => 9.days.from_now, 
                      :hide_at => 10.days.from_now)
  end
  
  context "location" do
    
    setup do
      @search_request = Syndication::SearchRequest.new( :filter => { :location => "78704", :radius => "0" } )
      @search_request.publisher = @publisher
      @deals = @search_request.perform.deals
    end
    
    should "return deals with advertiser store in zip code" do
      assert @deals.include?(@deal_1), "Should include deal with advertiser store in zip"
      assert @deals.include?(@deal_2), "Should include deal with advertiser store in zip"
      assert @deals.include?(@deal_3), "Should include deal with advertiser store in zip"
      assert !@deals.include?(@deal_4), "Should not include deal with advertiser store not in zip"
      assert !@deals.include?(@deal_5), "Should not include deal with advertiser store not in zip"
    end
    
    should "return the location latitude" do
      assert_equal @zip_78704.reload.latitude, @search_request.latitude
    end
    
    should "return the lcoation longitude" do
      assert_equal @zip_78704.reload.longitude, @search_request.longitude
    end
    
  end
  
  context "radius" do
    setup do
      @search_request = Syndication::SearchRequest.new( :filter => { :location => "78704", :radius => "5" } )
      @search_request.publisher = @publisher
      @deals = @search_request.perform.deals
    end
    should "return deals with advertiser store in zip code" do
      assert @deals.include?(@deal_1), "Should include deal with advertiser store in zip"
      assert @deals.include?(@deal_2), "Should include deal with advertiser store in zip"
      assert @deals.include?(@deal_3), "Should include deal with advertiser store in zip"
      assert !@deals.include?(@deal_4), "Should not include deal with advertiser store not in zip"
      assert @deals.include?(@deal_5), "Should include deal with advertiser store in zip"
    end
  end
  
end