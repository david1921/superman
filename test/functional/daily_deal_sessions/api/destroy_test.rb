require File.dirname(__FILE__) + "/../../../test_helper"
# hydra class DailyDealSessions::Api::DestroyTest
module DailyDealSessions
  module Api
    class DestroyTest < ActionController::TestCase
      tests DailyDealSessionsController

      context "daily deal sessions controller destroy api actions" do
        
        setup do
          @publisher = Factory(:publisher)     
          @consumer  = Factory(:consumer, :publisher => @publisher)
          @consumer.reset_active_session_token!
        end

        should "render a 200 response" do
          verifier = mock("verifier")
          @controller.expects(:verifier).returns(verifier)
          verifier.expects(:verify).with(@consumer.active_session_token).returns(session)
          login_as @consumer          
          @request.env['API-Version'] = "3.0.0"
          delete :destroy, :publisher_id => @publisher.to_param, :format => "json", :session => session["active_session_token"]
          assert_response :success
        end
        
      end

    end
  end
end