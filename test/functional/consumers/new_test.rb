require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ConsumersController::NewTest
class ConsumersController::NewTest < ActionController::TestCase
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

  def test_new
    get :new, :publisher_id => @publisher.to_param
    assert_response :success
    assert_template "consumers/new"
    assert_select "form[action='#{publisher_consumers_path(@publisher)}']", 1 do
      assert_select "input[name='consumer[name]']", 1
      assert_select "input[name='consumer[email]']", 1
      assert_select "input[name='consumer[password]']", 1
      assert_select "input[name='consumer[password_confirmation]']", 1
      assert_select "input[name='consumer[agree_to_terms]'][type=checkbox]", 1
      assert_select "input[type=submit]", 1
    end
  end

  def test_new_with_sign_up_message
    publisher = publishers(:entercom)
    get :new, :publisher_id => publisher.to_param
    assert_response :success
    assert_template "consumers/new"
    assert_select "div[class=sign_up_message]"
    assert @response.body["please sign up"], "Should show account sign up message"
  end

  def test_new_without_sign_up_message
    publisher = publishers(:sdh_austin)
    get :new, :publisher_id => publisher.to_param
    assert_response :success
    assert_template "consumers/new"
    assert_select "div[class=sign_up_message]", false
    assert !@response.body["please sign up"], "Should NOT show account sign up message"
  end

  def test_new_with_ny_daily_news
    @publisher.update_attributes! :label => "nydailynews", :launched => true
    get :new, :publisher_id => @publisher.to_param
    assert_response :success
    assert_template "themes/nydailynews/consumers/new"
    assert_select "form[action='#{publisher_consumers_path(@publisher)}']", 1 do
      assert_select "input[type='hidden'][name='consumer[zip_code_required]'][value='true']", 1
      assert_select "input[name='consumer[name]']", 1
      assert_select "input[name='consumer[zip_code]']", 1
      assert_select "input[name='consumer[email]']", 1
      assert_select "input[name='consumer[password]']", 1
      assert_select "input[name='consumer[password_confirmation]']", 1
      assert_select "input[name='consumer[agree_to_terms]'][type=checkbox]", 1
      assert_select "input[type=submit]", 1
    end
  end

  def test_new_with_publisher_billing_address_required
    @publisher.update_attributes! :require_billing_address => true
    get :new, :publisher_id => @publisher.to_param

    assert_select "input[name='consumer[address_line_1]']"
    assert_select "input[name='consumer[address_line_2]']"
    assert_select "input[name='consumer[billing_city]']"
    assert_select "select[name='consumer[state]']"
    assert_select "select[name='consumer[country_code]']"
    assert_select "input[name='consumer[zip_code]']"
  end

  def test_new_with_freedom_publication
    publishing_group = Factory(:publishing_group, :name => "Freedom", :label => "freedom")
    [ "ocregister", "gazette", "themonitor" ].each_with_index do |label, index|

      publisher        = Factory(:publisher, :name => "Publication #{index}", :label => label, :publishing_group_id => publishing_group.id)
      assert_equal publishing_group, publisher.publishing_group

      get :new, :publisher_id => publisher.to_param

      assert_theme_layout "#{publisher.publishing_group.label}/layouts/daily_deals"
      assert_template     "themes/freedom/consumers/new"

      assert @response.body.include?( "/javascripts/analog/device.js" ), "should have device.js for #{label}"

      # for the subscriber email signup
      assert_select "input[name='subscriber[device]']", true, "should have subscriber device field for #{label}" unless ["shelbystar"].include?(label)

      # for the consumer form
      assert_select "input[name='consumer[first_name]']"
      assert_select "input[name='consumer[last_name]']"
      assert_select "input[name='consumer[email]']"
      assert_select "input[name='consumer[password]']"
      assert_select "input[name='consumer[password_confirmation]']"
      assert_select "select[name='consumer[birth_year]']"
      assert_select "select[name='consumer[gender]']"
      assert_select "input[name='consumer[agree_to_terms]']"
      assert_select "input[name='consumer[device]'][type='hidden']"
    end
  end

  def test_new_with_novadog
    publisher = Factory(:publisher, :label => "novadog")
    get :new, :publisher_id => publisher.to_param

    assert_response :success
    assert_template "themes/novadog/consumers/new"
    assert_select "form[action='#{publisher_consumers_path(publisher)}']" do
      assert_select "input[type=text][name='consumer[referral_code]']"
    end
  end

  def test_new_with_no_enabled_locales_for_consumer
    @publisher.stubs(:enabled_locales_for_consumer).returns([])
    get :new, :publisher_id => @publisher.to_param
    assert_select "input[type='radio'][name='consumer[preferred_locale]']", :count => 0
  end

  def test_new_with_enabled_locales_for_consumer
    @publisher.update_attribute(:enabled_locales, ["en", "es"])
    get :new, :publisher_id => @publisher.to_param
    assert_select "input[type='radio'][name='consumer[preferred_locale]'][value='en']"
    assert_select "input[type='radio'][name='consumer[preferred_locale]'][value='es']"
  end

  context "membership code entry" do
    setup do
      @publishing_group = Factory(:publishing_group)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
    end

    context "given a publisher not using membership codes" do
      setup do
        @publishing_group.update_attribute(:require_publisher_membership_codes, false)
        get :new, :publisher_id => @publisher.to_param
      end

      should "not show membership code entry for consumer" do
        assert_select "input[type='text'][name='consumer[publisher_membership_code_as_text]']", false
      end
    end

    context "given a publisher using membership codes" do
      setup do
        @publishing_group.update_attribute(:require_publisher_membership_codes, true)
        get :new, :publisher_id => @publisher.to_param
      end

      should "show membership code entry for consumer" do
        assert_select "input[type='text'][name='consumer[publisher_membership_code_as_text]']", true
      end
    end
  end
end
