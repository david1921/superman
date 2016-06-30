require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::BusinessContactRequestsControllerTest < ActionController::TestCase

  context "index" do
    setup do
      @publisher = Factory(:publisher, :label => "wcax")
      get :index, :publisher_id => @publisher.to_param
    end

    should "redirect to new" do
      assert_redirected_to new_publisher_business_contact_request_path(@publisher)
    end
  end

  context "new" do
    setup do
      @publisher = Factory(:publisher, :label => "wcax")
      get :new, :publisher_id => @publisher.to_param
    end

    should assign_to(:publisher)
    should respond_with(:success)
    should render_template("themes/wcax/publishers/business_contact_requests/new.html.erb")
  end

  context "create" do
    setup do
      @publisher = Factory(:publisher, :label => "wcax")
    end

    context "given valid attributes" do
      setup do
        ActionMailer::Base.deliveries.clear
        get :create, :publisher_id => @publisher.to_param, :business_contact_request => {
          :publisher          => @publisher,
          :first_name         => "John",
          :last_name          => "Smith",
          :email              => "john@example.com",
          :business           => "Holy Shirts and Pants",
          :message            => "hello"
        }
      end

      should "redirect to thank you page" do
        assert_redirected_to thank_you_publisher_business_contact_requests_path(@publisher)
      end

      should "send email" do
        assert_equal 1, ActionMailer::Base.deliveries.size, "should deliver 1 email"
      end
    end

    context "given invalid attributes" do
      setup do
        ActionMailer::Base.deliveries.clear
        get :create, :publisher_id => @publisher.to_param, :business_contact_request => {
          :publisher => @publisher,
          :first_name => "John",
          :last_name => "Smith"
        }
      end

      should render_template("themes/wcax/publishers/business_contact_requests/new.html.erb")

      should "not send email" do
        assert_equal 0, ActionMailer::Base.deliveries.size, "should deliver 0 emails"
      end
    end
  end

  context "thank_you" do
    setup do
      @publisher = Factory(:publisher, :label => "wcax")
      get :thank_you, :publisher_id => @publisher.to_param
    end

    should assign_to(:publisher)
    should respond_with(:success)
    should render_template("themes/wcax/publishers/business_contact_requests/thank_you.html.erb")
  end

end
