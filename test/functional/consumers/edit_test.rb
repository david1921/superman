require File.dirname(__FILE__) + "/../../test_helper"

class ConsumersController::EditTest < ActionController::TestCase
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

  def test_edit
    consumer = @publisher.consumers.create!(@valid_consumer_attrs.merge(:name => "Joe Bob Blow"))
    consumer.activate!

    with_consumer_login_required(consumer) do
      assert_no_difference 'Consumer.count' do
        get :edit, :publisher_id => @publisher.to_param, :id => consumer.to_param
      end
    end
    assert_response :success
    assert_select "form[action='#{publisher_consumer_path(@publisher, consumer)}']", 1 do
      assert_select "input[name='consumer[email]'][disabled=disabled]", 1
      assert_select "input[name='consumer[first_name]'][value='Joe Bob']", 1
      assert_select "input[name='consumer[last_name]'][value='Blow']", 1
      assert_select "input[name='consumer[password]']", 1
      assert_select "input[name='consumer[password_confirmation]']", 1
      assert_select "input[name='consumer[agree_to_terms]'][type=checkbox]", 0
      assert_select "input[type=submit]", 1
    end
  end

  def test_edit_with_billing_addr
    @publisher.update_attributes! :require_billing_address => true
    @valid_consumer_attrs.merge!(
      :address_line_1 => 'somewhere',
      :address_line_2 => 'nice',
      :billing_city => 'brooklyn',
      :state => 'NY',
      :country_code => 'US',
      :zip_code => '11215'
    )
    consumer = @publisher.consumers.create!(@valid_consumer_attrs)
    consumer.activate!

    with_consumer_login_required(consumer) do
      get :edit, :publisher_id => @publisher.to_param, :id => consumer.to_param
    end
    assert_select "input[name='consumer[address_line_1]'][value='somewhere']"
    assert_select "input[name='consumer[address_line_2]'][value='nice']"
    assert_select "input[name='consumer[billing_city]'][value='brooklyn']"
    assert_select "select[name='consumer[state]']"
    assert_select "select[name='consumer[country_code]']"
    assert_select "input[name='consumer[zip_code]'][value='11215']"
  end

  def test_edit_with_timewarner_cable_publisher
    publishing_group  = Factory(:publishing_group, :label => "rr")
    publisher         = Factory(:publisher, :label => "clickedin-austin", :publishing_group => publishing_group)
    consumer          = Factory(:consumer, :publisher => publisher)
    consumer.activate!

    login_as( consumer )
    get :edit, :publisher_id => publisher.to_param, :id => consumer.to_param

    assert_template "themes/rr/consumers/edit"
  end

  def test_edit_with_no_enabled_locales_for_consumer
    @publisher.stubs(:enabled_locales_for_consumer).returns([])
    consumer = @publisher.consumers.create!(@valid_consumer_attrs)
    consumer.activate!

    with_consumer_login_required(consumer) do
      get :edit, :publisher_id => @publisher.to_param, :id => consumer.to_param
    end
    assert_select "input[type='radio'][name='consumer[preferred_locale]']", :count => 0
  end

  def test_edit_with_enabled_locales_for_consumer
    @publisher.update_attribute(:enabled_locales, ["en", "es"])
    consumer = @publisher.consumers.create!(@valid_consumer_attrs)
    consumer.activate!
    with_consumer_login_required(consumer) do
      get :edit, :publisher_id => @publisher.to_param, :id => consumer.to_param
    end
    assert_select "input[type='radio'][name='consumer[preferred_locale]'][value='en']"
    assert_select "input[type='radio'][name='consumer[preferred_locale]'][value='es']"
  end

  context "membership code entry" do
    setup do
      @publishing_group = Factory(:publishing_group)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group, :launched => true)
      @consumer = Factory(:consumer, :publisher => @publisher)
      @consumer.activate!
    end

    context "given a publisher not using membership codes" do
      setup do
        @publishing_group.update_attribute(:require_publisher_membership_codes, false)
        with_consumer_login_required(@consumer) do
          get :edit, :id => @consumer.to_param, :publisher_id => @publisher.to_param
        end
      end

      should "not show membership code entry for consumer" do
        assert_select "input[type='text'][name='consumer[publisher_membership_code_as_text]']", false
      end
    end

    context "given a publisher using membership codes" do
      setup do
        @publishing_group.update_attribute(:require_publisher_membership_codes, true)
        with_consumer_login_required(@consumer) do
          get :edit, :id => @consumer.to_param, :publisher_id => @publisher.to_param
        end
      end

      should "show membership code entry for consumer" do
        assert_select "input[type='text'][name='consumer[publisher_membership_code_as_text]']", true
      end
    end
  end
end
