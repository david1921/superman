require File.dirname(__FILE__) + "/../../test_helper"

class ConsumersController::ShowTest < ActionController::TestCase
  include ConsumersHelper
  tests ConsumersController

  context "show" do

    should "render show template if publisher is set to allow_consumer_show_action" do
      # should only be available for blue cross template, so using bcbsa label
      p = Factory(:publisher, :allow_consumer_show_action => true, :label => "bcbsa")
      c = Factory(:consumer, :publisher => p)
      login_as c
      get :show, :publisher_id => p.to_param, :id => c.to_param
      assert_response :success
      assert_template :show
      assert_theme_layout "bcbsa/layouts/daily_deals"
    end

    should "render show template if publisher's publishing group is set to allow_consumer_show_action" do
      # should only be available for blue cross template, so using bcbsa label
      pg = Factory(:publishing_group, :label => 'bcbsa', :allow_consumer_show_action => true)
      p = Factory(:publisher, :allow_consumer_show_action => false, :publishing_group => pg)
      c = Factory(:consumer, :publisher => p)
      login_as c
      get :show, :publisher_id => p.to_param, :id => c.to_param
      assert_response :success
      assert_template :show
      assert_theme_layout "bcbsa/layouts/daily_deals"
    end

    should "return a 404 exception if publisher allow_consumer_show_action is set to false" do
      p = Factory(:publisher, :allow_consumer_show_action => false)
      c = Factory(:consumer, :publisher => p)
      login_as c
      get :show, :publisher_id => p.to_param, :id => c.to_param
      assert_response :not_found
    end

    should "return a 404 exception if publisher and publishing_group allow_consumer_show_action are set to false" do
      pg = Factory(:publishing_group, :allow_consumer_show_action => false)
      p = Factory(:publisher, :allow_consumer_show_action => false, :publishing_group => pg)
      c = Factory(:consumer, :publisher => p)
      login_as c
      get :show, :publisher_id => p.to_param, :id => c.to_param
      assert_response :not_found
    end

    should "redirect to my publisher's account if accessing other publisher" do
      p = Factory(:publisher, :allow_consumer_show_action => true, :label => "bcbsa")
      c = Factory(:consumer, :publisher => p)
      other_p = Factory(:publisher, :allow_consumer_show_action => true, :label => "bcbsmi")
      login_as c
      get :show, :publisher_id => other_p.to_param, :id => c.to_param

      assert_redirected_to publisher_consumer_path(:publisher_id => p.id, :id => c.id)
      assert_nil flash[:notice]
    end

  end
end
