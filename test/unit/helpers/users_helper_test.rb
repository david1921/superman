require File.dirname(__FILE__) + "/../../test_helper"

class UsersHelperTest < ActionView::TestCase

  context "first_time_visitor?" do
    should "return true if session[:first_time_visitor] exists" do
      @request = ActionController::TestRequest.new
      @request.session[:first_time_visitor] = true
      assert first_time_visitor?
    end

    should "return false if session[:first_time_visitor] does not exist" do
      @request = ActionController::TestRequest.new
      @request.session = {}
      assert_equal false, first_time_visitor?
    end
  end

  context "polymorphic_edit_user_path" do

    should "return an edit link for an admin user" do
      user = Factory :admin
      assert_equal edit_admin_path(:id => user.to_param), polymorphic_edit_user_path(user)
    end

    should "return an edit link for a consumer" do
      user = Factory :consumer
      assert_equal edit_admin_consumer_path(:id => user.to_param), polymorphic_edit_user_path(user)
    end
    
    should "return an edit link for a publisher user" do
      user = Factory :user, :company => Factory(:publisher)
      assert_equal edit_publisher_user_path(:publisher_id => user.company.to_param, :id => user.to_param), polymorphic_edit_user_path(user)
    end

    should "return an edit link for a publishing group user" do
      user = Factory :user, :company => Factory(:publishing_group)
      assert_equal edit_publishing_group_user_path(:publishing_group_id => user.company.to_param, :id => user.to_param), polymorphic_edit_user_path(user)
    end

    should "return an edit link for an advertiser user" do
      user = Factory :user, :company => Factory(:advertiser)
      assert_equal edit_advertiser_user_path(:advertiser_id => user.company.to_param, :id => user.to_param), polymorphic_edit_user_path(user)
    end

  end

end
