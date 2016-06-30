require File.dirname(__FILE__) + "/../../test_helper"

class ConsumersController::UpdateTest < ActionController::TestCase
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

  def test_update
    consumer = @publisher.consumers.create!(@valid_consumer_attrs.merge(:name => "Joe Jones Blow"))
    consumer.activate!
    original_crypted_password = consumer.crypted_password

    with_consumer_login_required(consumer) do
      assert_no_difference 'Consumer.count' do
        put :update, :publisher_id => @publisher.to_param, :id => consumer.to_param, :consumer => {
          :first_name => "Joseph",
          :last_name => "Jones Blow",
          :email => "joe@hotmail.com",
          :password => "newone",
          :password_confirmation => "newone"
        }
      end
    end
    assert_redirected_to public_deal_of_day_path(@publisher.label)
    assert_equal @publisher.label, cookies['publisher_label']
    assert_equal "Joseph", consumer.reload.first_name
    assert_equal "Jones Blow", consumer.last_name
    assert_equal "joe@hotmail.com", consumer.reload.email, "Email should now, because of BX, be able to update their email"
    assert_not_equal original_crypted_password, consumer.crypted_password, "Password should have been updated"
  end

  def test_update_with_all_updateable_attributes
    daily_deal_category = Factory(:daily_deal_category)
    consumer = @publisher.consumers.create!(@valid_consumer_attrs.merge(:name => "Joe Jones Blow"))
    consumer.activate!
    original_crypted_password = consumer.crypted_password

    with_consumer_login_required(consumer) do
      assert_no_difference 'Consumer.count' do
        put :update, :publisher_id => @publisher.to_param, :id => consumer.to_param, :consumer => {
          :first_name => "Joseph",
          :last_name => "Jones Blow",
          :email => "joe@hotmail.com",
          :password => "newone",
          :password_confirmation => "newone",
          :daily_deal_category_ids => ["#{daily_deal_category.id}"],
          :address_line_1 => "123 Main St.",
          :billing_city => "Portland",
          :state => "OR",
          :zip_code => "97206",
          :country_code => "US",
          :mobile_number => "555-555-5555",
          :birth_year => "1970",
          :gender => "M"
        }
      end
    end

    assert_redirected_to public_deal_of_day_path(@publisher.label)
    consumer.reload
    assert_equal "Joseph", consumer.first_name
    assert_equal "Jones Blow", consumer.last_name
    assert_equal "joe@hotmail.com", consumer.reload.email, "Email should now, because of BX, have been updated"
    assert_not_equal original_crypted_password, consumer.crypted_password, "Password should have been updated"

    assert_equal "123 Main St.", consumer.address_line_1
    assert_equal "Portland", consumer.billing_city
    assert_equal "OR", consumer.state
    assert_equal "97206", consumer.zip_code
    assert_equal "US", consumer.country_code
    assert_equal "555-555-5555", consumer.mobile_number
    assert_equal 1970, consumer.birth_year
    assert_equal "M", consumer.gender
    assert_equal [daily_deal_category], consumer.daily_deal_categories


  end

  def test_update_with_billing_address_required
    @publisher = Factory(:publisher,
                         :name => "Foo",
                         :label => "foo",
                         :theme => "enhanced",
                         :production_subdomain => "sb1",
                         :launched => true,
                         :payment_method  => "credit",
                         :require_billing_address => true)
    consumer = @publisher.consumers.create!(:country_code => "US",
                                            :zip_code => "98671",
                                            :password_confirmation => "[FILTERED]",
                                            :billing_city =>"Washougal",
                                            :address_line_1 =>"123 A street",
                                            :address_line_2 =>"",
                                            :last_name =>"Doe",
                                            :state =>"WA",
                                            :first_name =>"John",
                                            :email => "joe@blow.com",
                                            :password => "secret",
                                            :password_confirmation => "secret",
                                            :agree_to_terms => "1")
    consumer.activate!
    original_crypted_password = consumer.crypted_password
    with_consumer_login_required(consumer) do
      assert_no_difference 'Consumer.count' do
        put :update, :publisher_id => @publisher.to_param, :id => consumer.to_param, :consumer => {
          :first_name => "Joseph",
          :last_name => "Jones Blow",
          :zip_code => "98662",
          :billing_city => "Juneau",
          :address_line_1 => "123 B street",
          :address_line_2 => "suite 4",
          :state => "AK",
          :email => "joe@hotmail.com",
          :password => "newone",
          :password_confirmation => "newone"
        }
      end
    end
    assert_redirected_to public_deal_of_day_path(@publisher.label)
    assert_equal "Joseph", consumer.reload.first_name
    assert_equal "Jones Blow", consumer.last_name
    assert_equal "98662", consumer.zip_code
    assert_equal "Juneau", consumer.billing_city
    assert_equal "123 B street", consumer.address_line_1
    assert_equal "suite 4", consumer.address_line_2
    assert_equal "AK", consumer.state
    assert_equal "joe@blow.com", consumer.reload.email, "Email should *not* have been updated"
    assert_not_equal original_crypted_password, consumer.crypted_password, "Password should have been updated"
  end

  context "updates in which the consumer's membership code and so publisher changes during the update" do

    setup do
      @publishing_group = Factory(:publishing_group, :require_publisher_membership_codes => true)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @code = Factory(:publisher_membership_code, :publisher => @publisher, :code => "1234")
      @consumer = Factory(:consumer, :publisher => @publisher, :publisher_membership_code => @code, :email => "foobar@yahoo.com")
      @publisher2 = Factory(:publisher, :publishing_group => @publishing_group)
      @code2 = Factory(:publisher_membership_code, :publisher => @publisher2, :code => "3456")
    end

    should "redirect to the daily deal of the new publisher" do
      login_as @consumer
      put :update, :publisher_id => @publisher.to_param, :id => @consumer.to_param, :consumer => {
        :first_name => "Fred",
        :last_name => @consumer.last_name,
        :zip_code => @consumer.zip_code,
        :billing_city => @consumer.billing_city,
        :address_line_1 => @consumer.address_line_1,
        :address_line_2 => @consumer.address_line_2,
        :state => @consumer.state,
        :publisher_membership_code_as_text => @code2.code
      }
      @consumer.reload
      assert_redirected_to public_deal_of_day_path(@publisher2.label)
      assert_equal "Fred", @consumer.first_name
      assert_equal @publisher2, @consumer.publisher
      assert_equal @code2, @consumer.publisher_membership_code
      assert_equal @consumer, @controller.send(:current_consumer)
      assert_equal "foobar@yahoo.com", @consumer.email
    end

  end

end
