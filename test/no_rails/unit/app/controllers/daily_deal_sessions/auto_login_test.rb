require File.dirname(__FILE__) + "/../../controllers_helper"

class AutoLoginTest < Test::Unit::TestCase
  context "flag_password_as_md5_on_get" do

    should "not add the flag if the request is not a get request" do
      controller = stub
      controller.extend(DailyDealSessions::AutoLogin)
      request = stub(:get? => false)
      params = { :session => { :password => "foobar" } }
      controller.expects(:request).returns(request)
      controller.stubs(:params).returns(params)
      controller.flag_password_as_md5_on_get
      assert !params[:session][:password].respond_to?(:md5?), "arbitrary string should not respond to m5d?"
    end

    should "add the flag if the requst is a get request" do
      controller = stub
      controller.extend(DailyDealSessions::AutoLogin)
      request = stub(:get? => true)
      params = { :session => { :password => "foobar" } }
      controller.expects(:request).returns(request)
      controller.expects(:params).at_least_once.returns(params)
      controller.flag_password_as_md5_on_get
      assert params[:session][:password].respond_to?(:md5?), "md5? method should have been added"
      assert params[:session][:password].md5?
    end

  end
end
