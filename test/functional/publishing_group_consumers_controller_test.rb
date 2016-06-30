require File.dirname(__FILE__) + "/../test_helper"

class PublishingGroupConsumersControllerTest < ActionController::TestCase

  context "show" do
    setup do
      @publishing_group = Factory(:publishing_group, :label => 'cyd')
      @publisher = Factory(:publisher, :publishing_group_id => @publishing_group.id)
      @referring_user = Factory(:consumer, :publisher => @publisher)
      @consumer = Factory(:consumer,
                          :publisher => @publisher,
                          :referral_code => @referring_user.referrer_code,
                          :mobile_number => "5554443333",
                          :facebook_id => "22123"
      )
    end

    should "not respond to HTML format" do
      user = Factory(:user, :company => @publishing_group)
      login_with_basic_auth(:login => user.login, :password => "test")
      get :show, :publishing_group_id => @publishing_group.label, :id => @consumer.to_param
      assert_response :not_acceptable
    end

    context "when requested as JSON" do
      should "not be successful without logging in via basic auth" do
        get :show, :publishing_group_id => @publishing_group.label, :id => @consumer.to_param, :format => "json"
        assert_response 401
      end

      should "not be successful with an invalid user" do
        login_with_basic_auth(:login => "i_dont_exist", :password => "fail")
        get :show, :publishing_group_id => @publishing_group.label, :id => @consumer.to_param, :format => "json"
        assert_response 401
      end

      should "allow a pub group user to see a consumer that is theirs" do
        user = Factory(:user, :company => @publishing_group)
        login_with_basic_auth(:login => user.login, :password => "test")
        get :show, :publishing_group_id => @publishing_group.label, :id => @consumer.to_param, :format => "json"
        assert_equal @publishing_group, assigns(:publishing_group)
        assert_equal @consumer, assigns(:consumer)
        assert_response 200
      end

      should "not allow a pub group user to see a consumer that is not theirs" do
        not_their_consumer = Factory(:consumer)
        user = Factory(:user, :company => @publishing_group)
        login_with_basic_auth(:login => user.login, :password => "test")
        get :show, :publishing_group_id => @publishing_group.label, :id => not_their_consumer.to_param, :format => "json"
        assert_response 401
      end

      should "not allow a pub group user to see a pub group that is not theirs" do
        user = Factory(:user, :company => Factory(:publishing_group))
        login_with_basic_auth(:login => user.login, :password => "test")
        get :show, :publishing_group_id => @publishing_group.label, :id => @consumer.to_param, :format => "json"
        assert_response 401
      end

      should "return a 401 if the user does not have a company" do
        user = Factory(:user)
        login_with_basic_auth(:login => user.login, :password => "test")
        get :show, :publishing_group_id => @publishing_group.label, :id => @consumer.to_param, :format => "json"
        assert_response 401
      end

      should "return a 404 if the publishing group does not exist" do
        user = Factory(:user, :company => Factory(:publishing_group))
        login_with_basic_auth(:login => user.login, :password => "test")
        get :show, :publishing_group_id => "not_gonna_doit", :id => @consumer.to_param, :format => "json"
        assert_response 404
      end

      should "return a 404 if the consumer does not exist" do
        user = Factory(:user, :company => @publishing_group)
        login_with_basic_auth(:login => user.login, :password => "test")
        get :show, :publishing_group_id => @publishing_group.label, :id => "666", :format => "json"
        assert_response 404
      end

      should "allow an admin access" do
        user = Factory(:admin)
        login_with_basic_auth(:login => user.login, :password => "monkey")
        get :show, :publishing_group_id => @publishing_group.label, :id => @consumer.to_param, :format => "json"
        assert_response 200
      end

      context "JSON format" do
        setup do
          @user = Factory(:user, :company => @publishing_group)
          login_with_basic_auth(:login => @user.login, :password => "test")
        end

        should "return consumer information in JSON format" do
          get :show, :publishing_group_id => @publishing_group.label, :id => @consumer.to_param, :format => "json"
          response = ActiveSupport::JSON.decode(@response.body)
          assert_equal @consumer.id, response["id"]
          assert_equal @consumer.first_name, response["first_name"]
          assert_equal @consumer.last_name, response["last_name"]
          assert_equal @consumer.referral_code, response["referral_code"]
          assert_equal @consumer.referrer_code, response["referrer_code"]
          assert_equal @consumer.referring_consumer.id, response["referring_consumer_id"]
          assert_equal @consumer.mobile_number, response["mobile_number"]
          assert_equal @consumer.facebook_id, response["facebook_id"]
          assert_equal @consumer.publisher.name, response["publisher_name"]
        end

        should "be OK with consumers without referrers" do
          @consumer.referral_code = nil
          @consumer.save!
          get :show, :publishing_group_id => @publishing_group.label, :id => @consumer.to_param, :format => "json"
          response = ActiveSupport::JSON.decode(@response.body)
          assert_equal "", response["referral_code"]
          assert_equal "", response["referring_consumer_id"]
        end
      end

    end
  end
end

