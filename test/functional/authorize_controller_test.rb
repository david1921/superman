require File.dirname(__FILE__) + "/../test_helper"

class AuthorizeControllerTest < ActionController::TestCase
  fast_context "the authorize controller" do

    setup do
      publishing_group = Factory(:publishing_group_with_theme)
      @publisher =  Factory(:publisher, :publishing_group => publishing_group ) 
      @consumer =  Factory(:facebook_consumer, :publisher => @publisher)
      @non_facebook_publisher = Factory.build(:publisher).attributes.symbolize_keys!
    end
    
    subject { @consumer }
    
    should "include the FacebookAuth module" do
      assert AuthorizeController.include?(FacebookAuth)
    end
    
    # init => https://graph.facebook.com/oauth/authorize?scope=email%2Coffline_access%2Cpublish_stream%2Cuser_birthday&client_id=d037226862befdaf3d377f47eb1ec37c&type=web_server&redirect_uri=http%3A%2F%2Fdeals.villagevoice.com%3A3000%2Fauthorize%2Fcallback%2F64
    # callback => {"code"=>"fff56e7e85a30d4ff0097c76-100000752859414|rNsivozHip42GRpQgc3NuSxSQbI", "action"=>"callback", "controller"=>"authorize", "publisher_id"=>"64"}

    should "recognize the auth_init_path with the consumer's publisher" do
      assert_recognizes({ :controller => 'authorize', :action => 'init', :publisher_id => "#{@consumer.publisher[:id]}" }, auth_init_path(@consumer.publisher))                        
    end
    
    should "generate the provided path" do
      assert_generates("/authorize/#{@consumer.publisher[:id]}", { :controller => 'authorize', :action => 'init', :publisher_id => "#{@consumer.publisher[:id]}" })
    end
    
    should "raise not found exception if publisher is missing from the yaml file" do
      publisher = Factory(:publisher, @non_facebook_publisher)
      assert_raise FacebookAuth::NoFacebookApiKeyConfiguredForPublisher do
        # must simulate production environment otherwise we will get the sandbox api_key
        get :init, :publisher_id => publisher.to_param, :rails_env => "production"
      end
    end

    should "return not_found for a user agent contains bot" do
      @request.env["HTTP_USER_AGENT"] = "GoogleBot"
      get :init, :publisher_id => @publisher.to_param, :rails_env => "production"
      assert_response :not_found

      @request.env["HTTP_USER_AGENT"] = "bot"
      get :init, :publisher_id => @publisher.to_param, :rails_env => "production"
      assert_response :not_found

      @request.env["HTTP_USER_AGENT"] = "" # clear this, otherwise it will carry onto other tests within this fast context
    end
    
    should "redirect to daily deal landing page if callback is called with error_reason equal to user_denied" do
      get :callback, :publisher_id => @publisher.id, :error_reason => "user_denied"
      assert_redirected_to public_deal_of_day_path(@publisher.label)
    end
  end
  
  context "callback" do
    
    setup do
      @publisher = Factory(:publisher)
      @access_token_response = {
        "id" => "1234567",
        "name" => "Jonna Smith",
        "first_name" => "Jonna",
        "last_name" => "Smith",
        "link" => "http => //www.facebook.com/jonna-smith",
        "username" => "jonnasmith",
        "birthday" => "10/22/1965",
        "gender" => "female",
        "email" => "jonnasmith@gmail.com",
        "timezone" => -7,
        "locale" => "en_US",
        "verified" => true,
        "updated_time" => "2011-07-27T18:16:27+0000"
      }
      
      @access_token_json = @access_token_response.to_json
      
      @code   = "454545454545"
      @token  = "723322323"
    end
    
    should "redirect to deal of the day path with a 'user_denied' error reason" do
      get :callback, :publisher_id => @publisher.to_param, :error_reason => "user_denied"
      assert_redirected_to public_deal_of_day_path(@publisher.label)
      assert_nil @controller.send(:current_consumer), "there should be no consumer set"      
    end
    
    should "redirect to deal of the day path if facebook connect error occurred" do
      FacebookAuth.expects(:oauth2_client).raises(FacebookAuth::NoFacebookApiKeyConfiguredForPublisher)
      get :callback, :publisher_id => @publisher.to_param, :code => @code
      assert_redirected_to public_deal_of_day_path(@publisher.label)
      assert_nil @controller.send(:current_consumer), "there should be no consumer set"
    end
    
    should "create new consumer based on successful facebook connect" do      
      access_token = mock("access_token")
      access_token.expects(:get).with("/me").returns( @access_token_json.to_s )
      access_token.expects(:token).returns(@token)
      @controller.expects(:access_token_from_code).with(@code).returns(access_token)
      assert_difference("Consumer.count") do
        get :callback, :publisher_id => @publisher.to_param, :code => @code
      end
      assert_redirected_to public_deal_of_day_path(@publisher.label)
      current_consumer = @controller.send(:current_consumer)
      assert_not_nil current_consumer, "there should be a consumer set"
      assert_equal @access_token_response["id"], current_consumer.facebook_id, "should set the facebook id"
      assert_equal @access_token_response["email"], current_consumer.email
    end
    
    should "login existing consumer based on successful facebook connect" do
      consumer = Factory(:consumer, :publisher => @publisher, :email => @access_token_response["email"], :facebook_id => @access_token_response["id"])
      access_token = mock("access_token")
      access_token.expects(:get).with("/me").returns( @access_token_json.to_s )
      access_token.expects(:token).returns(@token)
      @controller.expects(:access_token_from_code).with(@code).returns(access_token)
      assert_no_difference("Consumer.count") do
        get :callback, :publisher_id => @publisher.to_param, :code => @code
      end
      assert_redirected_to public_deal_of_day_path(@publisher.label)
      current_consumer = @controller.send(:current_consumer)
      assert_equal consumer, current_consumer
    end
    
  end
end
