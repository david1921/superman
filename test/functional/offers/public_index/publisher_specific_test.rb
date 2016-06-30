require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class OffersController::PublicIndex::PublisherSpecificTest
module OffersController::PublicIndex
  class PublisherSpecificTest < ActionController::TestCase
    tests OffersController

    def test_public_index_for_vcreporter
      publisher = publishers(:vcreporter)
      publisher.update_attribute :coupons_home_link, false
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      get(:public_index, :publisher_id => publisher.to_param)
      assert_response(:success)
      assert_nil(session[:user_id], "Should not automatically login user")
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/vcreporter/public_index")
      assert_template("offers/standard/public_index")
      assert_select "#coupons_home a", {:count => 0, :text => "Coupons Home"}
    end

    def test_public_index_for_knoxville
      publisher = publishers(:knoxville)
      publisher.update_attribute :coupons_home_link, false
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      get(:public_index, :publisher_id => publisher.to_param)
      assert_response(:success)
      assert_nil(session[:user_id], "Should not automatically login user")
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/knoxville/public_index")
      assert_template("offers/standard/public_index")
      assert_select "#coupons_home a", {:count => 0, :text => "Coupons Home"}
    end

    def test_public_index_for_express_milwaukee
      publisher = publishers(:express_milwaukee)
      publisher.update_attribute :coupons_home_link, false
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      get(:public_index, :publisher_id => publisher.to_param)
      assert_response(:success)
      assert_nil(session[:user_id], "Should not automatically login user")
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/expressmilwaukee/public_index")
      assert_template("offers/standard/public_index")
      assert_select "#coupons_home a", {:count => 0, :text => "Coupons Home"}
    end

    def test_public_index_for_north_shore_sun
      publisher = publishers(:north_shore_sun)
      publisher.update_attribute :coupons_home_link, false
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      get(:public_index, :publisher_id => publisher.to_param)
      assert_response(:success)
      assert_nil(session[:user_id], "Should not automatically login user")
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/northshoresun/public_index")
      assert_template("offers/standard/public_index")
      assert_select "#coupons_home a", {:count => 0, :text => "Coupons Home"}
    end

    def test_public_index_for_monthly_grapevine
      publisher = publishers(:monthlygrapevine)
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      get(:public_index, :publisher_id => publisher.to_param)
      assert_response(:success)
      assert_nil(session[:user_id], "Should not automatically login user")
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/monthlygrapevine/public_index")
      assert_template("offers/monthlygrapevine/public_index.html.erb")
    end

    def test_public_index_with_universityofarizonatucson_label
      publisher = Factory(:publisher, :name => "New", :theme => "standard", :label => "universityofarizonatucson")
      offer = publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      get :public_index, :publisher_id => offer.publisher.to_param
      assert_response :success
      assert_not_nil assigns(:offers), "assigns @offers"
      assert_layout("offers/universityofarizonatucson/public_index")
      assert_template("offers/universityofarizonatucson/public_index")
    end

    def test_public_index_with_arizonastateuniversitymetropolitanphoenix_label
      publisher = Factory(:publisher, :name => "New", :theme => "standard", :label => "arizonastateuniversitymetropolitanphoenix")
      offer = publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      get :public_index, :publisher_id => offer.publisher.to_param
      assert_response :success
      assert_not_nil assigns(:offers), "assigns @offers"
      assert_layout("offers/arizonastateuniversitymetropolitanphoenix/public_index")
      assert_template("offers/arizonastateuniversitymetropolitanphoenix/public_index")
    end
  end
end
