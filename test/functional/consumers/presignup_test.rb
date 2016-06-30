require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ConsumersController::PresignupTest
class ConsumersController::PresignupTest < ActionController::TestCase
  include ConsumersHelper
  tests ConsumersController

  def setup
    @publisher = publishers(:sdh_austin)
  end

  def test_presignup
    get :presignup, :publisher_id => @publisher.to_param
    assert_response :success
  
    assert_select "form[action='#{publisher_consumers_path(@publisher)}']", 1 do
      assert_select "input[name='consumer[name]']", 1
      assert_select "input[name='consumer[email]']", 1
      assert_select "input[name='consumer[password]']", 1
      assert_select "input[name='consumer[password_confirmation]']", 1
      assert_select "input[name='consumer[agree_to_terms]'][type=checkbox]", 1
    end
  end
  
  def test_presignup_layout
    Rails.configuration.action_controller.stubs(:perform_caching?).returns(true)
    publisher = Factory(:publisher, :label => "vvdailypress")
    get :presignup, :publisher_id => publisher.to_param
    assert_response :success

    assert_theme_layout "vvdailypress/layouts/presignup"
    assert_template "themes/vvdailypress/consumers/presignup"
  end
  
  def test_presignup_layout_cached
    publisher = Factory(:publisher, :label => "vvdailypress")
    get :presignup, :publisher_id => publisher.to_param
    assert_response :success

    assert_theme_layout "vvdailypress/layouts/presignup"
    assert_template "themes/vvdailypress/consumers/presignup"
  end

  context "membership code entry" do
    setup do
      @publishing_group = Factory(:publishing_group)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
    end

    context "given a publisher not using membership codes" do
      setup do
        @publishing_group.update_attribute(:require_publisher_membership_codes, false)
        get :presignup, :publisher_id => @publisher.to_param
      end

      should "not show membership code entry for consumer" do
        assert_select "input[type='text'][name='consumer[publisher_membership_code_as_text_as_text]']", false
      end
    end

    context "given a publisher using membership codes" do
      setup do
        @publishing_group.update_attribute(:require_publisher_membership_codes, true)
        get :presignup, :publisher_id => @publisher.to_param
      end

      should "show membership code entry for consumer" do
        assert_select "input[type='text'][name='consumer[publisher_membership_code_as_text]']", true
      end
    end
  end
end
