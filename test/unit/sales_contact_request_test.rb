require File.dirname(__FILE__) + "/../test_helper"

class SalesContactRequestTest < ActiveSupport::TestCase

  context "validations" do
    should validate_presence_of :first_name
    should validate_presence_of :last_name
    should validate_presence_of :email
    should validate_presence_of :company
    should validate_presence_of :message

    should "validate format of email" do
      sales_contact_request = SalesContactRequest.new
      
      assert_bad_value(sales_contact_request, :email, "not_an_email")
      assert_good_value(sales_contact_request, :email, "a.valid@email.com")
    end
  end

  context "deliver" do
    setup do
      @publisher = Factory(:publisher)
    end

    context "given valid attributes" do
      setup do
        @sales_contact_request = SalesContactRequest.new(
          :publisher  => @publisher,
          :first_name => "John",
          :last_name  => "Doe",
          :company    => "Widgets R Us",
          :email      => "john@example.com",
          :message    => "Hello\n\nThis is a test.\n\nThanks, John"
        )
      end

      should "send email" do
        ActionMailer::Base.deliveries.clear
        @sales_contact_request.deliver
        assert_equal 1, ActionMailer::Base.deliveries.size, "should deliver 1 email"
      end
    end

    context "given invalid attributes" do
      setup do
        @sales_contact_request = SalesContactRequest.new(
          :publisher  => @publisher,
          :first_name => "John",
          :last_name  => "Doe"
        )
      end

      should "return false" do
        assert_equal false, @sales_contact_request.deliver
      end

      should "not send email" do
        ActionMailer::Base.deliveries.clear
        @sales_contact_request.deliver
        assert_equal 0, ActionMailer::Base.deliveries.size, "should deliver 0 emails"
      end
    end
  end
end
