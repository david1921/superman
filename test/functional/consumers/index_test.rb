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

  def test_index
    login_as :aaron
    get :index
    assert_response :success
    assert_equal 2, assigns(:consumers).size, "@consumers"
    assert_layout "application"
  end

  def test_index_with_search
    login_as :aaron
    get :index, :text => "john@public.com"
    assert_response :success
    assert_equal [ users(:john_public) ], assigns(:consumers), "@consumers"
    assert_layout "application"
    assert_select "tr.consumer", 1 do
      assert_select "td.credit a"      
    end
  end
  
  def test_consumer_has_credit
    login_as :aaron
    publisher = Factory(:publisher)
    discount = Factory(:discount, :publisher => publisher)
    consumer = Factory(:consumer, :publisher => publisher, :signup_discount => discount)
  
    get :index, :text => consumer.email
    assert_response :success
  
    assert_select "tr.consumer" do
      assert_select "td.credit a", 0      
    end  
  end

  def test_index_with_self_serve_publisher_user_who_can_manage_consumers
    publisher = Factory(:publisher, :self_serve => true)
    user      = Factory(:user, :company => publisher, :can_manage_consumers => true)
    consumer  = Factory(:consumer, :publisher => publisher)
    login_as user
    get :index, :publisher_id => publisher.to_param
    assert_response :success
    assert_template :index
    assert_equal 1, assigns(:consumers).size, "should have 1 consumer returned"

    assert_select "table.consumers" do
      assert_select "tr:nth-child(2)" do
        assert_select "td", :text => consumer.name
        assert_select "td", :text => consumer.login
        assert_select "td", :text => consumer.publisher.label
        assert_select "td", :text => consumer.activation_code
      end
    end
  end

  def test_index_with_self_serve_publisher_user_who_can_not_manage_consumers
    publisher = Factory(:publisher, :self_serve => true)
    user      = Factory(:user, :company => publisher, :can_manage_consumers => false)
    consumer  = Factory(:consumer, :publisher => publisher)
    login_as user
    get :index, :publisher_id => publisher.to_param
    assert_redirected_to new_session_path
  end

  def test_index_with_publishing_group_user_who_can_manage_consumers_for_given_self_serve_publisher
    publishing_group = Factory(:publishing_group, :self_serve => true)
    publisher        = Factory(:publisher, :publishing_group => publishing_group, :self_serve => true)
    user             = Factory(:user, :company => publishing_group, :can_manage_consumers => true)
    consumer         = Factory(:consumer, :publisher => publisher)
    login_as user
    get :index, :publisher_id => publisher.to_param
    assert_response :success
    assert_template :index
    assert_equal 1, assigns(:consumers).size, "should ahve 1 consumer returned"
  end

  def test_index_with_self_serve_publisher_user_who_can_manage_consumers_but_trying_to_access_a_different_self_serve_publisher
    publisher  = Factory(:publisher, :self_serve => true)
    publisher2 = Factory(:publisher, :self_serve => true)
    consumer   = Factory(:consumer, :publisher => publisher)
    user       = Factory(:user, :company => publisher, :can_manage_consumers => true)
    login_as user
    get :index, :publisher_id => publisher2.to_param
    assert_redirected_to new_session_path
  end


  def test_index_not_admin
    login_as :john_public
    get :index
    assert_redirected_to new_session_path
  end

  def test_index_not_logged
    get :index
    assert_redirected_to new_session_path
  end

  def test_index_shows_manage_locked_accounts_link_to_admins
    admin = Factory :admin
    login_as(admin)
    get :index
    assert_response :success
    assert_select "a#manage-locked-accounts[href=#{user_locks_path}]"
  end

  def test_index_does_not_show_manage_locked_accounts_link_to_non_admins
    publisher_user = Factory :user, :can_manage_consumers => true
    assert_instance_of Publisher, publisher_user.company
    publisher_user.company.update_attributes! :self_serve => true
    login_as(publisher_user)
    get :index, :publisher_id => publisher_user.company.id
    assert_response :success
    assert_select "a#manage-locked-accounts[href=#{user_locks_path}]", false
  end
  
end
