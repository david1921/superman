require File.dirname(__FILE__) + "/../test_helper"

class PushNotificationDevicesControllerTest < ActionController::TestCase
  context "api" do
    setup do
      @publisher = Factory(:publisher)
      @token = "FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660"
    end
    
    should "return failure for create if the API-Version header is missing" do
      post :create, :format => "json", :publisher_id => @publisher.to_param, :device => {
        :token => @token
      }
      assert_response :not_acceptable
      assert_equal Api::Versioning::VALID_API_VERSIONS.last, @response.headers["API-Version"]
      assert_equal [{ "API-Version" => "is not valid" }], JSON.parse(@response.body)
    end
  
    should "return failure for create if the API-Version header is wrong" do
      @request.env['API-Version'] = "9.9.9"
      post :create, :format => "json", :publisher_id => @publisher.to_param, :device => {
        :token => @token
      }
      assert_response :not_acceptable
      assert_equal Api::Versioning::VALID_API_VERSIONS.last, @response.headers["API-Version"]
      assert_equal [{ "API-Version" => "is not valid" }], JSON.parse(@response.body)
    end
  
    should "create a registration in create when token is not registered for this publisher (v 1.0.0)" do
      @request.env['API-Version'] = "1.0.0"
      assert_difference '@publisher.push_notification_devices.count' do
        post :create, :format => "json", :publisher_id => @publisher.to_param, :device => {
          :token => @token
        }
        assert_response :success
      end
      assert_equal @token, PushNotificationDevice.last.token
    end

    should "create a registration in create when token is not registered for this publisher (v 2.0.0)" do
      @request.env['API-Version'] = "2.0.0"
      assert_difference '@publisher.push_notification_devices.count' do
        post :create, :format => "json", :publisher_id => @publisher.to_param, :device => {
          :token => @token
        }
        assert_response :success
      end
      assert_equal @token, PushNotificationDevice.last.token
    end

    should "do nothing in create when token is already registered for this publisher (v 1.0.0)" do
      @publisher.push_notification_devices.create! :token => @token
      
      @request.env['API-Version'] = "1.0.0"
      assert_no_difference 'PushNotificationDevice.count' do
        post :create, :format => "json", :publisher_id => @publisher.to_param, :device => {
          :token => @token
        }
        assert_response :success
      end
    end
    
    should "do nothing in create when token is already registered for this publisher (v 2.0.0)" do
      @publisher.push_notification_devices.create! :token => @token
      
      @request.env['API-Version'] = "2.0.0"
      assert_no_difference 'PushNotificationDevice.count' do
        post :create, :format => "json", :publisher_id => @publisher.to_param, :device => {
          :token => @token
        }
        assert_response :success
      end
    end
    
    should "delete a registration in destroy when token is registered for this publisher (v 1.0.0)" do
      @publisher.push_notification_devices.create! :token => @token
      
      @request.env['API-Version'] = "1.0.0"
      assert_difference '@publisher.push_notification_devices.count', -1 do
        delete :destroy, :format => "json", :publisher_id => @publisher.to_param, :id => @token
        assert_response :success
      end
    end
    
    should "delete a registration in destroy when token is registered for this publisher (v 2.0.0)" do
      @publisher.push_notification_devices.create! :token => @token
      
      @request.env['API-Version'] = "2.0.0"
      assert_difference '@publisher.push_notification_devices.count', -1 do
        delete :destroy, :format => "json", :publisher_id => @publisher.to_param, :id => @token
        assert_response :success
      end
    end

    should "do nothing in destroy when token is not registered for this publisher (v 1.0.0)" do
      @request.env['API-Version'] = "1.0.0"
      assert_no_difference 'PushNotificationDevice.count' do
        delete :destroy, :format => "json", :publisher_id => @publisher.to_param, :id => @token
        assert_response :success
      end
    end
    
    should "do nothing in destroy when token is not registered for this publisher (v 2.0.0)" do
      @request.env['API-Version'] = "2.0.0"
      assert_no_difference 'PushNotificationDevice.count' do
        delete :destroy, :format => "json", :publisher_id => @publisher.to_param, :id => @token
        assert_response :success
      end
    end    
    
  end
end
