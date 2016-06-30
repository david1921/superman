require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Api::ThirdPartyPurchases::CallbackConfigsControllerTest

class Api::ThirdPartyPurchases::CallbackConfigsControllerTest < ActionController::TestCase
  def setup
    ssl_on
    @user = Factory(:user)
    login_with_basic_auth(@user)
  end

  def teardown
    ssl_off
  end

  should "inherit from Api::ThirdPartyPurchases::ApplicationController" do
    assert_equal Api::ThirdPartyPurchases::ApplicationController, Api::ThirdPartyPurchases::CallbackConfigsController.superclass
  end

  context "#show" do
    should "render xml with new callback config" do
      get :show
      assert_response :ok
      assert_select_config(ThirdPartyPurchasesApiConfig.new)
    end

    should "render xml with existing callback config" do
      config = Factory(:third_party_purchases_api_config, :user => @user)
      get :show
      assert_response :ok
      assert_select_config(config)
    end
  end

  context "#create" do
    should "create new config' and render xml" do
      input_xml = callback_xml
      @request.env['RAW_POST_DATA'] = input_xml

      assert_difference 'ThirdPartyPurchasesApiConfig.count' do
        post :create
      end

      assert_response :ok
      config = assigns(:config)
      expected = Hash.from_xml(input_xml)['callback_config']
      assert_config_updates(config, expected)
      assert_select_config(config)
    end

    should "update an existing config" do
      config = Factory(:third_party_purchases_api_config, :user => @user)
      input_xml = callback_xml
      @request.env['RAW_POST_DATA'] = input_xml

      assert_no_difference 'ThirdPartyPurchasesApiConfig.count' do
        post :create
      end

      assert_response :ok
      assert_equal config, assigns(:config)

      expected = Hash.from_xml(input_xml)['callback_config']
      assert_config_updates(config.reload, expected)
    end
  end

  private

  def callback_xml
    File.read(Rails.root + "test/data/api/third_party_purchases/callback_config.xml")
  end

  def assert_select_config(config)
    assert_select 'callback_config' do
      assert_select 'url', config.callback_url, @response.body
      assert_select 'username', config.callback_username, @response.body
      assert_select 'password', config.callback_password, @response.body
    end
  end

  def assert_config_updates(config, expected)
    assert_equal expected['url'], config.callback_url
    assert_equal expected['username'], config.callback_username
    assert_equal expected['password'], config.callback_password
  end

end
