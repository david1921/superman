require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ThirdPartyDealsApi::PublisherTest

module ThirdPartyDealsApi
  
  class PublisherTest < ActiveSupport::TestCase
  
    context "publishers using the third party deals api" do

      setup do
        @publisher = Factory :publisher
      end

      should "have one third_party_deals_api_config associated to them" do
        assert @publisher.third_party_deals_api_config.blank?
        Factory :third_party_deals_api_config, :publisher => @publisher
        assert @publisher.reload.third_party_deals_api_config.present?
      end

    end

    context "#third_party_deals_api_get" do

      setup do
        third_party_config = Factory :third_party_deals_api_config
        @publisher = third_party_config.publisher
        FakeWeb.register_uri(:get, "http://example.com/somepage", :body => "an answer")
      end

      should "return an array of [Net::HTTPResponse, ApiActivityLog]" do
        response, api_activity_log = @publisher.third_party_deals_api_get("http://example.com/somepage")
        assert response.is_a?(Net::HTTPResponse)
        assert api_activity_log.is_a?(ApiActivityLog)
        assert_equal "an answer", response.body
      end
      
      should "log the request" do
        assert_difference "ApiActivityLog.count", 1 do
          @publisher.third_party_deals_api_get("http://example.com/somepage")
        end
      end
      
    end
    
    context "#third_party_deals_api_post" do
      
      setup do
        third_party_config = Factory :third_party_deals_api_config
        @publisher = third_party_config.publisher
        FakeWeb.register_uri(:post, "http://example.com/somepage", :body => "an answer")        
      end
      
      should "return an array of [Net::HTTPResponse, ApiActivityLog]" do
        response, api_activity_log = @publisher.third_party_deals_api_post("http://example.com/somepage", "some request")
        assert response.is_a?(Net::HTTPResponse)
        assert api_activity_log.is_a?(ApiActivityLog)
        assert_equal "an answer", response.body
      end
      
      should "log the request" do
        assert_difference "ApiActivityLog.count", 1 do
          @publisher.third_party_deals_api_post("http://example.com/somepage", "some request")
        end        
      end
      
    end
    
  end
  
end