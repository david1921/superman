require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Mobile::Version35Test
module Mobile
  class Version35Test < ActionController::IntegrationTest
    
    def setup
      @consumer  = Factory(:consumer, :password => "password", :password_confirmation => "password", :activated_at => 2.minutes.ago)      
      @publisher = @consumer.publisher
      @headers   = {"API-Version" => "3.5.0"}
    end    
    
    test "mobile api requests publisher details" do
      get "/publishers/#{@publisher.label}.json", {}, @headers      
      assert_response :success
    end
    
  end
end