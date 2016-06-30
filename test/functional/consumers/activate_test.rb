require File.dirname(__FILE__) + "/../../test_helper"

class ConsumersController::IndexTest < ActionController::TestCase
  include ConsumersHelper
  tests ConsumersController

  def setup
    @publisher = publishers(:sdh_austin)
    @valid_consumer_attrs = {
      :name => "Joe Blow",
      :email => "joe@blow.com",
      :password => "secret",
      :password_confirmation => "secret",
      :agree_to_terms => "1"
    }
    ActionMailer::Base.deliveries.clear
  end

  def test_activate
    consumer = @publisher.consumers.create!(@valid_consumer_attrs)
    assert !consumer.active?, "Test consumer should not be active yet"
    assert_no_difference 'Consumer.count' do
      post :activate, :publisher_id => @publisher.to_param, :activation_code => consumer.activation_code
    end
    assert_redirected_to public_deal_of_day_path(@publisher.label)
    assert_match /welcome/i, flash[:notice]
    assert consumer.reload.active?, "Consumer should have been activated"
    assert_equal consumer.id, session[:user_id], "Consumer should be logged in"
  end  
  
  def test_activate_with_api_1_0_0_with_missing_api_header
    consumer = @publisher.consumers.create!( @valid_consumer_attrs )
    assert !consumer.active?, "Test consumer should not be active yet"
    post :activate, :publisher_id => @publisher.to_param, :activation_code => consumer.activation_code, :format => "json"
    assert_response :not_acceptable
    assert !consumer.active?, "Test consumer should still not be active"
  end
  
  def test_activate_with_api_1_0_0_with_invalid_api_header
    @request.env['API-Version'] = "9.9.9"          
    consumer = @publisher.consumers.create!( @valid_consumer_attrs )
    assert !consumer.active?, "Test consumer should not be active yet"
    post :activate, :publisher_id => @publisher.to_param, :activation_code => consumer.activation_code, :format => "json"
    assert_response :not_acceptable
    assert !consumer.active?, "Test consumer should still not be active"
  end  
  
  def test_activate_with_api_1_0_0
    @request.env['API-Version'] = "1.0.0"          
    consumer = @publisher.consumers.create!( @valid_consumer_attrs )
    assert !consumer.active?, "Test consumer should not be active yet"
    post :activate, :publisher_id => @publisher.to_param, :activation_code => consumer.activation_code, :format => "json"
    assert_response :success
    assert consumer.reload.active?, "Test consumer should be active"
    json = JSON.parse( @response.body )
    assert_equal @controller.send(:verifier).generate({:user_id => consumer.id, :active_session_token => consumer.active_session_token}), json["session"]
    assert_equal consumer.name, json["name"]
    assert_equal consumer.credit_available, json["credit_available"]
  end  

  def test_activate_with_api_1_0_0_with_invalid_activation_code
    @request.env['API-Version'] = "1.0.0"          
    consumer = @publisher.consumers.create!( @valid_consumer_attrs )
    assert !consumer.active?, "Test consumer should not be active yet"
    post :activate, :publisher_id => @publisher.to_param, :activation_code => "blah", :format => "json"
    assert_response :not_found
  end
  
  def test_activate_with_no_billing_address
    publisher = Factory(:publisher, 
                          :name => "Foo",
                          :label => "foo",
                          :theme => "enhanced",
                          :production_subdomain => "sb1",
                          :launched => true,
                          :payment_method  => "credit",
                          :require_billing_address => false)
    consumer = publisher.consumers.create!(@valid_consumer_attrs)
    publisher.require_billing_address = true
    publisher.save!
    publisher.reload
    consumer.reload

    assert !consumer.active?, "Test consumer should not be active yet"
    assert !consumer.valid?, "Test consumer should not be valid"
    assert_no_difference 'Consumer.count' do
      post :activate, :publisher_id => publisher.to_param, :activation_code => consumer.activation_code
    end
    assert !consumer.active?, "Test consumer should not be active due to no billing address"
    assert_select "input[name='consumer[address_line_1]']", 1
    assert_select "input[name='consumer[address_line_2]']", 1
    assert_select "input[name='consumer[billing_city]']", 1
    assert_select "select[name='consumer[state]']", 1
    assert_select "select[name='consumer[country_code]']", 1
    assert_select "input[name='consumer[zip_code]']", 1

    assert_no_difference 'Consumer.count' do
      post :activate, :publisher_id => publisher.to_param, :activation_code => consumer.activation_code, :format => "json"
    end
    assert_response :unprocessable_entity
    c = assigns(:consumer)
    assert c
    assert !c.errors.empty?
    assert !c.active?, "Test consumer should not be active due to no billing address"
  end
  
  def test_activate_on_UNlaunched_publisher
    consumer = @publisher.consumers.create!(@valid_consumer_attrs)
    @publisher.disable!
    assert !consumer.active?, "Test consumer should not be active yet"
    assert_no_difference 'Consumer.count' do
      post :activate, :publisher_id => @publisher.to_param, :activation_code => consumer.activation_code
    end
  
    assert consumer.reload.active?, "Consumer should have been activated"
    assert_equal consumer.id, session[:user_id], "Consumer should be logged in"
  
    assert_redirected_to thank_you_publisher_consumer_url(@publisher, consumer)
  end

  def test_activate_while_active_and_logged_in
    consumer = @publisher.consumers.create!(@valid_consumer_attrs)
    consumer.activate!
    assert_not_nil consumer.activation_code, "Consumer should stil have an activation code"
    login_as consumer
    assert_no_difference 'Consumer.count' do
      post :activate, :publisher_id => @publisher.to_param, :activation_code => consumer.activation_code
    end
    assert_redirected_to public_deal_of_day_path(@publisher.label)
  
    assert consumer.reload.active?, "Consumer should still be active"
    assert_equal consumer.id, session[:user_id], "Consumer should be logged in"
  end

  def test_activate_while_active_and_not_logged_in
    consumer = @publisher.consumers.create!(@valid_consumer_attrs)
    consumer.activate!
    assert_not_nil consumer.activation_code, "Consumer should stil have an activation code"
    assert_no_difference 'Consumer.count' do
      post :activate, :publisher_id => @publisher.to_param, :activation_code => consumer.activation_code
    end
    assert_redirected_to daily_deal_login_path(@publisher)

    assert consumer.reload.active?, "Consumer should still be active"
    assert_equal nil, session[:user_id], "Consumer should not be logged in"
  end
  
  def test_activate_with_bad_activation_code
    assert_no_difference 'Consumer.count' do
      post :activate, :publisher_id => @publisher.to_param, :activation_code => "123"
    end
    assert_response :success
    assert_select "form[action='#{activate_publisher_consumers_path(@publisher)}']", 1 do
      assert_select "input[name=activation_code]", 1
      assert_select "input[type=submit]", 1
    end
    assert_nil session[:user_id], "Consumer should not be logged in"
  end
  
  def test_activate_with_no_activation_code
    assert_no_difference 'Consumer.count' do
      get :activate, :publisher_id => @publisher.to_param
    end
    assert_response :success
    assert_select "form[action='#{activate_publisher_consumers_path(@publisher)}']", 1 do
      assert_select "input[name=activation_code]", 1
      assert_select "input[type=submit]", 1
    end
    assert_nil session[:user_id], "Consumer should not be logged in"
  end
  
  def test_activate_with_blank_activation_code
    assert_no_difference 'Consumer.count' do
      post :activate, :publisher_id => @publisher.to_param, :activation_code => ""
    end
    assert_response :success
    assert_select "form[action='#{activate_publisher_consumers_path(@publisher)}']", 1 do
      assert_select "input[name=activation_code]", 1
      assert_select "input[type=submit]", 1
    end
    assert_nil session[:user_id], "Consumer should not be logged in"
  end
  
  def test_activate_by_administrator
    login_as :aaron
    consumer = @publisher.consumers.create!(@valid_consumer_attrs)
    assert !consumer.active?, "Test consumer should not be active yet"
    assert_no_difference 'Consumer.count' do
      post :activate_by_administrator, :id => consumer.to_param
    end
    assert_redirected_to consumers_path
  
    assert consumer.reload.active?, "Consumer should have been activated"
    assert_equal users(:aaron).id, session[:user_id], "Admin should still be logged in, not Consumer"
  end

  def test_activate_by_administrator_no_consumer_bill_addr_publisher_req_bill_addr
    login_as :aaron
    publisher = Factory(:publisher)
    consumer = publisher.consumers.create!(@valid_consumer_attrs)

    publisher.require_billing_address = true
    publisher.save!
    publisher.reload
    consumer.reload

    assert publisher.require_billing_address
    assert !consumer.billing_address_present?
    assert !consumer.active?, "Test consumer should not be active yet"
    assert !consumer.valid?, "Consumer should not be valid, no billing address"

    assert_no_difference 'Consumer.count' do 
      post :activate_by_administrator, :id => consumer.to_param
    end
    assert !consumer.reload.active?, "Consumer should not have been activated"
    assert_equal users(:aaron).id, session[:user_id], "Admin should still be logged in, not Consumer"
    consumer = assigns(:consumer)
    assert_not_nil consumer
    assert !consumer.errors.empty?
    assert !consumer.errors.on(:address_line_1).empty?
    assert !consumer.errors.on(:billing_city).empty?
    assert !consumer.errors.on(:state).empty?
    assert !consumer.errors.on(:zip_code).empty?
    assert !consumer.errors.on(:country_code).empty?
  end

  context "can_manage_consumers" do

    context "with self serve publisher" do

      setup do
        @publisher = Factory(:publisher, :self_serve => true)
        @consumer  = Factory(:consumer, :publisher => @publisher, :activated_at => nil)
        @user      = Factory(:user, :company => @publisher)
      end

      should "be able to activate_by_administrator with user who is allowed to manage consumers and the consumer is not active" do
        assert !@consumer.active?
        @user.update_attribute(:can_manage_consumers, true)
        login_as @user
        assert_no_difference 'Consumer.count' do
          post :activate_by_administrator, :id => @consumer.to_param
        end
        assert_redirected_to publisher_consumers_path(@publisher.to_param)
        assert @consumer.reload.active?, "should activate the consumer"
      end

      should "not be able to activate_by_administrator with user who is NOT allowed to manage consumers and the consumer is not active" do
        assert !@consumer.active?
        @user.update_attribute(:can_manage_consumers, false)
        login_as @user
        assert_no_difference 'Consumer.count' do
          post :activate_by_administrator, :id => @consumer.to_param
        end
        assert_redirected_to root_path
        assert !@consumer.reload.active?, "should not activate the consumer"
      end

    end

    context "with self serve publishing group" do

      setup do
        @publishing_group = Factory(:publishing_group, :self_serve => true)
        @publisher        = Factory(:publisher, :publishing_group => @publishing_group, :self_serve => true)
        @consumer         = Factory(:consumer, :publisher => @publisher, :activated_at => nil)
        @user             = Factory(:user, :company => @publishing_group)
      end

      should "be able to activate_by_administrator with user who is allowed to manage consumers and the consumer is not active" do
        assert !@consumer.active?
        @user.update_attribute(:can_manage_consumers, true)
        login_as @user
        assert_no_difference 'Consumer.count' do
          post :activate_by_administrator, :id => @consumer.to_param
        end
        assert_redirected_to publisher_consumers_path(@publisher.to_param)
        assert @consumer.reload.active?, "should activate the consumer"
      end

      should "not be able to activate_by_administrator with user who is NOT allowed to manage consumers and the consumer is not active" do
        assert !@consumer.active?
        @user.update_attribute(:can_manage_consumers, false)
        login_as @user
        assert_no_difference 'Consumer.count' do
          post :activate_by_administrator, :id => @consumer.to_param
        end
        assert_redirected_to root_path
        assert !@consumer.reload.active?, "should not activate the consumer"
      end

    end


  end
end
