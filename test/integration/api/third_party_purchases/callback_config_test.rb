require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Api::ThirdPartyPurchases::CallbackConfigTest

module Api::ThirdPartyPurchases
  class CallbackConfigTest < ActionController::IntegrationTest

    should "require basic authentication" do
      get '/api/third_party_purchases/callback_config'
      assert_response :unauthorized
    end

    context "authorized" do
      setup do
        user = Factory(:user)
        @headers ||= {'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(user.login, 'test')}
      end

      context "HTTP request" do
        setup do
          CallbackConfigsController.stubs(:ssl_rails_environment?).returns(true)
        end

        context "GET" do
          should "return callback config xml" do
            get '/api/third_party_purchases/callback_config', nil, @headers
            assert_response :forbidden
          end
        end

        context "POST" do
          should "update and return callback config xml" do
            post '/api/third_party_purchases/callback_config', callback_config_xml, @headers
            assert_response :forbidden
          end
        end
      end

      context "HTTPS request" do
        setup do
          https!
        end

        context "GET" do
          should "return callback config xml" do
            get '/api/third_party_purchases/callback_config', nil, @headers
            assert_response :ok
            assert_template 'callback_configs/show.xml' # functional test checks the details
          end
        end

        context "POST" do
          should "update and return callback config xml" do
            assert_difference 'ThirdPartyPurchasesApiConfig.count' do
              post '/api/third_party_purchases/callback_config', callback_config_xml, @headers
            end
            assert_response :ok
            assert_template 'callback_configs/show.xml' # functional test checks the details
          end
        end
      end
    end


    private

    def callback_config_xml
      File.read(Rails.root + "test/data/api/third_party_purchases/callback_config.xml")
    end


  end
end
