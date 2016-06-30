require File.dirname(__FILE__) + "/../test_helper"

class AffiliateDealsControllerTest < ActionController::TestCase

  context "#create" do
    
    setup do
      @publisher = Factory :publisher, :label => "original-publisher"
      @affiliate_publisher = Factory :publisher, :label => "affiliate-publisher"
      @advertiser = Factory :advertiser, :publisher => @publisher
      @daily_deal = Factory :daily_deal, :advertiser => @advertiser, :value_proposition => "awesome affiliate deal"
      
      @admin = Factory :admin
      @controller.stubs(:current_user).returns(@admin)
    end
    
    should "return an AffiliatePlacement serialized to json if the add was successful" do
      post :create, :publisher_id => "affiliate-publisher", :daily_deal_id => @daily_deal.id, :format => "json"
      assert_response :success
      affiliate_placement = JSON.parse(@response.body)
      assert_equal "affiliate-publisher", affiliate_placement["publisher_label"]
      assert_equal "awesome affiliate deal", affiliate_placement["value_proposition"]
    end
    
    should "return an error message when trying to add an affiliated deal/pub combo that already exists" do
      AffiliatePlacement.create! :affiliate => @affiliate_publisher, :placeable => @daily_deal
      post :create, :publisher_id => "affiliate-publisher", :daily_deal_id => @daily_deal.id, :format => "json"
      assert_response :error
      res = JSON.parse(@response.body)
      assert_match /has already been taken/i, res["error"]
    end
    
    should "should 'undelete' an affiliate placement if it is added back after having been deleted" do
      affiliate_placement = Factory :affiliate_placement, :affiliate => @publisher
      affiliate_placement.soft_delete!
      assert affiliate_placement.deleted_at.present?
      
      post :create, :publisher_id => "original-publisher", :daily_deal_id => affiliate_placement.placeable.id, :format => "json"
      assert_response :success
      assert_nil affiliate_placement.reload.deleted_at
      affiliate_placement_json = JSON.parse(@response.body)
      assert_equal "original-publisher", affiliate_placement_json["publisher_label"]
    end
    
  end

end
