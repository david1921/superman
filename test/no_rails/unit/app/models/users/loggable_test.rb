require File.dirname(__FILE__) + "/../../models_helper"

class Users::LockableTest < Test::Unit::TestCase
  class UserStub
    include Users::Core
    include Users::Loggable
  end

  context "action logging" do
    setup do
      @user = UserStub.new
    end

    context "log_action" do
      should "create a new log record" do
        user_logs_stub = stub
        user_logs_stub.expects(:create).with(:action => "login", :ip_address => "123.123.123.123")
        @user.stubs(:user_logs).returns(user_logs_stub)
        @user.log_action("login", "123.123.123.123")
      end
    end
  end

end
