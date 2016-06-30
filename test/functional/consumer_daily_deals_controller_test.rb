require File.dirname(__FILE__) + "/../test_helper"

class ConsumerDailyDealsControllerTest < ActionController::TestCase
  
	context "index" do

		context "with no current user" do

			should "redirect new session path" do
				get :index
				assert_redirected_to new_session_path
			end

		end

		context "with a consumer" do

			setup do
				@publisher = Factory(:publisher)
				@consumer  = Factory(:consumer, :publisher => @publisher)
			end

			should "render the index template" do
				login_as @consumer
				get :index
				assert_response :success
				assert_template :index
			end

		end

	end

end
