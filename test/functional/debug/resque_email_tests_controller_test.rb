require File.dirname(__FILE__) + "/../../test_helper"

class Debug::ResqueEmailTestsControllerTest < ActionController::TestCase

  context "admin is required" do

    should "require admin for new" do
      login_as Factory(:user)
      get :new
      assert_redirected_to root_path
    end

    should "require admin for create" do
      login_as Factory(:user)
      post :create
      assert_redirected_to root_path
    end

  end


  context "#new" do

    should "be able to get it as admin" do
      login_as Factory(:admin)
      get :new
      assert_response :success
    end

    should "have a field for entering email" do
      login_as Factory(:admin)
      get :new
      assert_select "input[id=email_address][type=text]"
      assert_select "input[type=submit]"
    end

  end

  context "#create" do

    should "redirect to new and set flash" do
      login_as Factory(:admin)
      email_address = "foobar@yahoo.com"
      Debug::SimpleTestEmailSender.stubs(:perform)
      post :create, { "email_address"=> email_address}
      assert_redirected_to :controller => "resque_email_tests", :action => "new"
      assert_match /queued/i, flash[:notice]
    end

    should "queue email" do
      login_as Factory(:admin)
      email_address = "foobar@yahoo.com"
      Debug::SimpleTestEmailSender.expects(:perform).with(email_address)
      post :create, { "email_address"=> email_address}
    end

    should "send email (because Resque is set to run inline)" do
      login_as Factory(:admin)
      email_address = "foobar@yahoo.com"
      AnalogMailer.any_instance.expects(:simple_test_email).with(email_address)
      post :create, { "email_address"=> email_address}
    end

  end

end