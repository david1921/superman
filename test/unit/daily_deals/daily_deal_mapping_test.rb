require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealMappingTest < ActiveSupport::TestCase
  include ActionView::Helpers::NumberHelper
  
  context "to_map_json" do
    setup do
      @daily_deal = Factory(:daily_deal)
      @json       = JSON.parse(@daily_deal.to_map_json)
    end

    should "have top level items" do
      assert_equal @daily_deal.id, @json["daily_deal"]["id"]
      assert_equal @daily_deal.value_proposition, @json["daily_deal"]["value_proposition"]
      assert_equal @daily_deal.hide_at.strftime("%m/%d/%Y"),  @json["daily_deal"]["hide_at"]
      assert_equal @daily_deal.start_at.strftime("%m/%d/%Y"), @json["daily_deal"]["start_at"]
      assert_equal number_to_currency( @daily_deal.price, :unit => @daily_deal.currency_code ), @json["daily_deal"]["price"]
    end

    should "have store items" do
      store = @daily_deal.advertiser.stores.first
      assert_equal store.latitude.to_s,  @json["daily_deal"]["stores"].first["latitude"]
      assert_equal store.longitude.to_s, @json["daily_deal"]["stores"].first["longitude"]
    end

  end
  
  context "distance_to" do
    
    setup do
      @point = GeoKit::LatLng.normalize("44.2486,-88.3519")
    end
    
    context "with no stores" do
      
      setup do
        @daily_deal = Factory(:daily_deal)
        @daily_deal.advertiser.stores.destroy_all
      end
      
      should "have not stores" do
        assert @daily_deal.advertiser.stores.empty?
      end
      
      should "return 99999 for distance_to" do
        assert 99999, @daily_deal.distance_to(@point, {})
      end
      
    end
    
    context "with just one store with no latitude/longitude" do
      
      setup do
        @daily_deal = Factory(:daily_deal)
        @daily_deal.advertiser.stores.first.update_attributes(:latitude => nil, :longitude => nil)
      end
      
      should "have one store, with no latitude or longitude" do
        assert_equal 1, @daily_deal.advertiser.stores.size
        assert_nil @daily_deal.advertiser.stores.first.latitude
        assert_nil @daily_deal.advertiser.stores.first.longitude
      end
      
      should "return 99999 for distance_to" do
        assert_equal 99999, @daily_deal.distance_to(@point, {})
      end
      
    end
    
    context "with just one store with latitude/longitude" do
      
      setup do        
        @daily_deal = Factory(:daily_deal)
        @expected_distance = @daily_deal.advertiser.stores.first.distance_to(@point, {})
      end
      
      should "have one store with latitude and longitude" do
        assert_equal 1, @daily_deal.advertiser.stores.size
        assert @daily_deal.advertiser.stores.first.latitude.present?
        assert @daily_deal.advertiser.stores.first.longitude.present?
      end
      
      should "return a distance based on the only store latitude/longitude" do
        assert_equal @expected_distance, @daily_deal.distance_to(@point, {})
      end
      
    end
    
    context "with multiple stores that have latitude/longitude" do
      
      setup do
        @daily_deal = Factory(:daily_deal)
        @advertiser = @daily_deal.advertiser
        @advertiser.stores.first.update_attributes(:longitude => -118.107, :latitude => 34.1371)
        @advertiser.stores.create( Factory.attributes_for(:store).merge(:longitude => -80.3496, :latitude => 25.7329))
        @expected_distance = @advertiser.stores.last.distance_to(@point, {})
      end
      
      should "have two stores" do
        assert_equal 2, @daily_deal.advertiser.stores.size
      end
      
      should "return a distance based on the closest store (store #2) latitude/longitude" do
        assert_equal @expected_distance, @daily_deal.distance_to(@point, {})
      end
      
      
    end
    
  end
end
