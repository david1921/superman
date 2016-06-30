require File.dirname(__FILE__) + "/../test_helper"

class ConsumerPasswordResetsControllerTest < ActionController::TestCase

  def test_new
    publisher = Factory(:publisher, :name => "OC Register", :label => "ocregister")
    get :new, :publisher_id => publisher.to_param
    assert_response :success
    assert_template "consumer_password_resets/new"
  end
  
  def test_new_with_ny_daily_news
    publisher = Factory(:publisher,  :name => "NY Daily News", :label => "nydailynews" )
    get :new, :publisher_id => publisher.to_param
    assert_response :success
    assert_template "consumer_password_resets/new"
  end
  
  def test_edit
    setup_objects

    @consumer.deliver_password_reset_instructions!
    get :edit, :id => @consumer.perishable_token, :publisher_id => @publisher.to_param
    
    assert_response :success
    assert_template :edit
    assert_select "form[action=/publishers/#{@publisher.to_param}/consumer_password_resets/#{@consumer.perishable_token}]", 1 do
      assert_select "input[type=hidden][name=_method][value=put]", 1
      assert_select "input[type=password][name='consumer[password]']", 1
      assert_select "input[type=password][name='consumer[password_confirmation]']", 1
      assert_select "input[type=submit]", 1
    end
  end
  
  def test_create_with_activated_consumer
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    consumer.update_attribute(:perishable_token, nil)
    consumer.activate!
    assert_nil consumer.perishable_token, "should not have a perishable token yet"    
    assert consumer.active?, "consumer should be active"
    
    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.size

    post :create, :publisher_id => publisher.to_param, :email => consumer.email
    assert_template :create
    assert_layout   "daily_deals"
    
    assert_equal 1, ActionMailer::Base.deliveries.size, "should send out reset password instructions"
    assert_not_nil consumer.reload.perishable_token, "should set the perishable token"    
    assert_equal 16, consumer.perishable_token.length, "should user a perishable token of lenght 16"
  end

  test "single sign on consumer from other publisher" do
    pg = Factory(:publishing_group, :allow_single_sign_on => true, :unique_email_across_publishing_group => true)
    publisher = Factory(:publisher, :publishing_group => pg)
    publisher2 = Factory(:publisher, :publishing_group => pg)
    consumer = Factory(:consumer, :publisher => publisher)
    consumer.update_attribute(:perishable_token, nil)
    consumer.activate!

    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.size

    post :create, :publisher_id => publisher2.to_param, :email => consumer.email
    assert_template :create
    assert_equal 1, ActionMailer::Base.deliveries.size, "should send out reset password instructions"
    assert_not_nil consumer.reload.perishable_token, "should set the perishable token"

    put :update, :publisher_id => publisher2.to_param, :id => consumer.perishable_token, :consumer => { :password => "mynewpassword", :password_confirmation => "mynewpassword" }
    assert_redirected_to  public_deal_of_day_path(publisher2.label)
    assert_equal          "Password successfully updated!", flash[:notice]
  end
  
  def test_create_with_unactivated_consumer
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    consumer.update_attribute(:perishable_token, nil)
    consumer.update_attribute(:activated_at, nil)
    assert_nil consumer.perishable_token, "should not have a perishable token yet"    
    assert !consumer.active?, "consumer should NOT be active"
    
    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.size
    
    post :create, :publisher_id => publisher.to_param, :email => consumer.email
    assert_template "consumers/create" 
    assert_layout   "daily_deals"
    
    assert_equal 1, ActionMailer::Base.deliveries.size, "should resend activation email"
    assert_nil   consumer.reload.perishable_token, "should not set the perishable token"    
  end
  
  def test_create_with_email_adddress_that_does_not_belong_to_a_customer
    publisher = Factory(:publisher)
    post :create, :publisher_id => publisher.to_param, :email => "blah@blah.com"
    assert_redirected_to new_publisher_consumer_password_reset_path(publisher)
    assert_equal "Sorry, no user was found.", flash[:warn]
  end
  
  def test_create_with_invalid_email_address
    publisher = Factory(:publisher)
    post :create, :publisher_id => publisher.to_param, :email => "blahblah"
    assert_redirected_to new_publisher_consumer_password_reset_path(publisher)
    assert_equal "Invalid email address.", flash[:warn]
  end

  def test_create_with_api_1_0_0_with_missing_api_header
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    post :create, :publisher_id => publisher.to_param, :email => consumer.email, :format => "json"
    assert_response :not_acceptable
  end
  
  def test_create_with_api_1_0_0_with_invalid_api_header
    @request.env['API-Version'] = "9.9.9"
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    post :create, :publisher_id => publisher.to_param, :email => consumer.email, :format => "json"
    assert_response :not_acceptable
  end
  
  def test_create_with_api_1_0_0_with_active_consumer
    @request.env['API-Version'] = "1.0.0"    
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    consumer.update_attribute(:perishable_token, nil)
    consumer.activate!
    assert_nil consumer.perishable_token, "should not have a perishable token yet"    
    assert consumer.active?, "consumer should be active"
    
    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.size    
    
    post :create, :publisher_id => publisher.to_param, :email => consumer.email, :format => "json"

    assert_equal 1, ActionMailer::Base.deliveries.size, "should send out reset password instructions"
    assert_not_nil consumer.reload.perishable_token, "should set the perishable token"
    assert_equal 8, consumer.reload.perishable_token.size, "should set a smaller perishable token"
    
    expected_reset_url = publisher_consumer_password_reset_url(publisher.to_param, consumer.perishable_token, :host => AppConfig.api_host, :format => "json", :protocol => "http")
        
    assert_match consumer.perishable_token, ActionMailer::Base.deliveries.first.encoded
    
    json = JSON.parse( @response.body )
    assert_equal expected_reset_url, json["methods"]["update_password"]
  end  
  
  def test_create_with_api_1_0_0_with_unactivate_consumer
    @request.env['API-Version'] = "1.0.0"
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    consumer.update_attribute(:perishable_token, nil)
    consumer.update_attribute(:activated_at, nil)
    assert_nil consumer.perishable_token, "should not have a perishable token yet"    
    assert !consumer.active?, "consumer should NOT be active"
    
    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.size
    
    post :create, :publisher_id => publisher.to_param, :email => consumer.email, :format => "json"
    
    assert_response :conflict
    json = JSON.parse( @response.body )
    assert_equal ["Account is not active, please activate the account first"], json["errors"]
  end  
  
  def test_create_with_api_1_0_0_with_invalid_email_address
    @request.env['API-Version'] = "1.0.0"
    publisher = Factory(:publisher)
    post :create, :publisher_id => publisher.to_param, :email => "blah@blahblah.com", :format => "json"
    assert_response :conflict
    json = JSON.parse( @response.body )
    assert_equal ["Unable to find an account associated with that email address"], json["errors"]
  end 
  
  def test_update_with_valid_token_and_new_password
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    assert_not_nil consumer.perishable_token
    
    put :update, :publisher_id => publisher.to_param, :id => consumer.perishable_token, :consumer => { :password => "mynewpassword", :password_confirmation => "mynewpassword" }
    
    assert_redirected_to  public_deal_of_day_path(publisher.label)
    assert_equal          "Password successfully updated!", flash[:notice]
    
  end
  
  def test_update_with_valid_token_and_invalid_passwords
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    assert_not_nil consumer.perishable_token
    
    put :update, :publisher_id => publisher.to_param, :id => consumer.perishable_token, :consumer => { :password => "mynewpassword", :password_confirmation => "blah" }
    
    assert_template :edit
    assert assigns(:consumer)    
  end
  
  def test_update_with_invalid_token
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    assert_not_nil consumer.perishable_token
    
    put :update, :publisher_id => publisher.to_param, :id => "blahblah", :consumer => { :password => "mynewpassword", :password_confirmation => "mynewpassword" }
    
    assert_redirected_to  public_deal_of_day_path(publisher.label)
    assert_equal "We're sorry, but we could not locate your account.", flash[:warn]
    
  end
  

  def test_update_with_api_1_0_0_with_missing_api_header
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    post :update, :publisher_id => publisher.to_param, :id => consumer.perishable_token, :consumer => { :password => "mynewpassword" }, :format => "json"
    assert_response :not_acceptable
  end
  
  def test_update_with_api_1_0_0_with_invalid_api_header
    @request.env['API-Version'] = "9.9.9"
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    post :update, :publisher_id => publisher.to_param, :id => consumer.perishable_token, :consumer => { :password => "mynewpassword" }, :format => "json"
    assert_response :not_acceptable
  end 
  
  def test_update_with_api_1_0_0_with_invalid_token
    @request.env['API-Version'] = "1.0.0"
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    post :update, :publisher_id => publisher.to_param, :id => "blahblah", :consumer => { :password => "mynewpassword" }, :format => "json"    
    assert_response :not_found
  end
  
  def test_update_with_api_1_0_0_with_invalid_reset_code
    @request.env['API-Version'] = "1.0.0"
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    post :update, {
      :publisher_id => publisher.to_param,
      :id => consumer.perishable_token,
      :consumer => { :reset_code => "h@x0r", :password => "mynewpassword" },
      :format => "json"
    }
    assert_response :conflict
    json = JSON.parse( @response.body )
    assert_equal ["Invalid reset code"], json["errors"]
  end
  
  def test_update_with_api_1_0_0_with_invalid_password
    @request.env['API-Version'] = "1.0.0"
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    post :update, {
      :publisher_id => publisher.to_param,
      :id => consumer.perishable_token,
      :consumer => { :reset_code => consumer.perishable_token, :password => "" },
      :format => "json"
    }
    assert_response :conflict
    json = JSON.parse( @response.body )
    assert_equal ["Password can't be blank","Password is too short (minimum is 6 characters)","Confirm Password can't be blank"], json["errors"]
  end
  
  def test_update_with_api_1_0_0
    @request.env['API-Version'] = "1.0.0"
    publisher = Factory(:publisher)
    consumer  = Factory(:consumer, :publisher => publisher)
    post :update, {
      :publisher_id => publisher.to_param,
      :id => consumer.perishable_token,
      :consumer => { :reset_code => consumer.perishable_token, :password => "mynewpassword" },
      :format => "json"
    }
    assert_response :success
    json = JSON.parse( @response.body )
    assert_equal @controller.send(:verifier).generate({:user_id => consumer.id, :active_session_token => consumer.active_session_token}), json["session"]
    assert_equal consumer.name, json["name"]
    assert_equal consumer.credit_available, json["credit_available"]        
  end


  private
  
  def setup_objects
    @publisher = Factory(:publisher, :name => "OC Register", :label => "ocregister")
    @advertiser = @publisher.advertisers.create!(:name => "Advertiser", :description => "test description")
    @daily_deal = @advertiser.daily_deals.create!(
      :price => 39,
      :value => 80,
      :description => "awesome deal",
      :terms => "GPL",
      :value_proposition => "buy now",
      :start_at => 1.day.ago,
      :hide_at => 3.days.from_now
    )
    @consumer = @publisher.consumers.create!(
      :login => "joe@blow.com",
      :email => "joe@blow.com",
      :name => "Joe Blow",
      :password => "secret",
      :password_confirmation => "secret",
      :agree_to_terms => "1"
    )
  end
end
