require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Advertisers::VersionsControllerTest
class Advertisers::VersionsControllerTest < ActionController::TestCase
  
	context "#index" do

		setup do
			@advertiser = Factory(:advertiser, :label => "mylabel")
			@publisher  = @advertiser.publisher
			@publisher.update_attribute(:self_serve, true)
			@account    = Factory(:user, :company => @publisher)
		end

		context "with no versions" do

			context "without an account that can manage advertiser" do

				should "redirect to new session page" do
					get :index, :advertiser_id => @advertiser.to_param
					assert_redirected_to new_session_path
				end

			end

			context "with an account that can manage the advertiser" do

				should "allow @account to manage @advertiser" do
					assert @account.can_manage?( @advertiser )
				end

				should "render the index template page with application layout" do
					login_as @account
					get :index, :advertiser_id => @advertiser.to_param
					assert_template :index
					assert_layout   :application
					assert_not_nil assigns(:presenter), "presenter should be created"
				end

			end


			context "with an admin account" do

				should "render the index template page with application layout" do
					login_as Factory(:admin)
					get :index, :advertiser_id => @advertiser.to_param
					assert_template :index
					assert_layout  	:application								
					assert_not_nil assigns(:presenter), "presenter should be created"
				end

			end

		end

		context "with versions on the main advertiser record" do

			setup do
				@advertiser.update_attributes!(:label => "changed label 1", :size => nil)
				@advertiser.update_attributes!(:label => "changed label 2", :size => "Large")
				@advertiser.reload
			end

			should "have 3 versions on the advertiser" do
				assert_equal 3, @advertiser.versions.size
			end

			should "render the index template with 2, version entries" do
				login_as @account
				get :index, :advertiser_id => @advertiser.to_param
				assert_template :index
				assert_layout   :application
				assert_not_nil assigns(:presenter), "presenter should be created"
			end

		end

	end	

end
