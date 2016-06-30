require File.dirname(__FILE__) + "/../../../test_helper"
# hydra class Publishers::Api::ShowTest
module Publishers
  module Api
    class ShowTest < ActionController::TestCase
      tests PublishersController

      context "publishers controller api actions" do

        setup do
          Time.stubs(:now).returns(Time.parse("Jan 01, 2011 01:00:00 UTC"))
          @publisher = Factory(:publisher, {
            :label => "nytimes",
            :name => "NY Times",
            :phone_number => "212-555-1212",
            :support_url => "http://support.nytimes.com/",
            :support_email_address => "support@nytimes.com",
            :qr_code_host => "http://qr.nytimes.com"
          })
        end
  
        context "invalid requests" do
    
          should "return failure for show.json if the API-Version request header is missing" do
            get :show, :id => @publisher.label, :format => "json"
            assert_response :not_acceptable
            assert_equal ::Api::Versioning::VALID_API_VERSIONS.last, @response.headers["API-Version"]
            assert_equal [{ "API-Version" => "is not valid" }], ActiveSupport::JSON.decode(@response.body)
          end

          should "return failure for show.json if the API-Version request header is wrong" do
            @request.env['API-Version'] = "9.9.9"
            get :show, :id => @publisher.label, :format => "json"
            assert_response :not_acceptable
            assert_equal ::Api::Versioning::VALID_API_VERSIONS.last, @response.headers["API-Version"]
            assert_equal [{ "API-Version" => "is not valid" }], ActiveSupport::JSON.decode(@response.body)
          end
    
          should "return not_found for invalid publisher label (v 1.0.0)" do
            @request.env['API-Version'] = "1.0.0"
            get :show, :id => "blahblah", :format => 'json'
            assert_response :not_found
          end

          should "return not_found for invalid publisher label (v 2.0.0)" do
            @request.env['API-Version'] = "2.0.0"
            get :show, :id => "blahblah", :format => 'json'
            assert_response :not_found
          end      

        end
    
        should "have correct JSON response for show.json (v 1.0.0)" do
          @request.env['API-Version'] = "1.0.0"
          get :show, :id => @publisher.label, :format => 'json'
          assert_response :success
          assert_equal "1.0.0", @response.headers["API-Version"]

          expected = {
            "name" => "NY Times",
            "label" => "nytimes",
            "support_email_address" => "support@nytimes.com",
            "support_url" => "http://support.nytimes.com/",
            "updated_at" => "2011-01-01T01:00:00Z",
            "support_phone_number" => "12125551212",
            "logo" => @publisher.logo.url,
            "connections" => {
              "active_daily_deals" => "http://#{AppConfig.api_host}/publishers/nytimes/daily_deals/active.json"
            },
            "methods" => {
              "signup" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/consumers.json",
              "login" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/daily_deal_sessions.json",
              "facebook_connect" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/facebook_consumers.json",
              "reset_password" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/consumer_password_resets.json",
              "register_push_notification_device" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/push_notification_devices.json",
              "merchant_login"=>"https://#{AppConfig.api_host}/session.json"
            }
          }
          assert_equal expected, ActiveSupport::JSON.decode(@response.body)
        end
  
        should "have correct JSON response for show.json (v 2.0.0)" do
          @request.env['API-Version'] = "2.0.0"
          get :show, :id => @publisher.label, :format => 'json'
          assert_response :success
          assert_equal "2.0.0", @response.headers["API-Version"]
    
          expected = {
            "name" => "NY Times",
            "label" => "nytimes",
            "support_email_address" => "support@nytimes.com",
            "support_url" => "http://support.nytimes.com/",
            "updated_at" => "2011-01-01T01:00:00Z",
            "support_phone_number" => "12125551212",
            "logo" => @publisher.logo.url,
            "connections" => {
              "active_daily_deals" => "http://#{AppConfig.api_host}/publishers/nytimes/daily_deals/active.json"
            },
            "methods" => {
              "signup" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/consumers.json",
              "login" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/daily_deal_sessions.json",
              "facebook_connect" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/facebook_consumers.json",
              "reset_password" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/consumer_password_resets.json",
              "register_push_notification_device" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/push_notification_devices.json",
              "merchant_login"=>"https://#{AppConfig.api_host}/session.json"
            }
          }      
          assert_equal expected, ActiveSupport::JSON.decode(@response.body)
        end  
  
        should "have correct JSON reesponse for show.json (v 3.0.0)" do
          @request.env["API-Version"] = "3.0.0"
          get :show, :id => @publisher.label, :format => 'json'
          assert_response :success
          assert_equal "3.0.0", @response.headers["API-Version"]
    
          expected = {
            "label" => "nytimes",
            "logo" => @publisher.logo.url,
            "name" => "NY Times",
            "support_phone_number" => "12125551212",
            "support_email_address" => "support@nytimes.com",
            "support_url" => "http://support.nytimes.com/",
            "updated_at" => "2011-01-01T01:00:00Z",
            "qr_code_host" => "http://qr.nytimes.com",
            "connections" => {
              "active_daily_deals" => "http://#{AppConfig.api_host}/publishers/nytimes/daily_deals/active.json"
            },
            "methods" => {
              "signup" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/consumers.json",
              "logout" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/daily_deal/logout.json",
              "login" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/daily_deal_sessions.json",
              "facebook_connect" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/facebook_consumers.json",
              "reset_password" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/consumer_password_resets.json",
              "register_push_notification_device" => "https://#{AppConfig.api_host}/publishers/#{@publisher.id}/push_notification_devices.json",
              "merchant_login"=>"https://#{AppConfig.api_host}/session.json"
            }
          }
          assert_equal expected, ActiveSupport::JSON.decode(@response.body)
        end  

      end

    end
  end
end