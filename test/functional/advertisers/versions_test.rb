require File.dirname(__FILE__) + "/../../test_helper"

class AdvertisersController::VersionsTest < ActionController::TestCase
  tests AdvertisersController

  context "edit" do

  	setup do
  		@advertiser = Factory(:advertiser)
  		login_as Factory(:admin)
  		get :edit, :id => @advertiser.to_param
		end	

		should "render the edit template" do
			assert_template :edit
		end

		should "display the 'View Changes' link" do
			assert_select "div#view_changes" do
				assert_select "a[href='#{advertiser_versions_path(@advertiser)}']", :text => "View Changes"
			end
		end

  end

end