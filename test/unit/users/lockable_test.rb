require File.dirname(__FILE__) + "/../../test_helper"

class Users::LockableTest < ActiveSupport::TestCase

  # Also see no-rails Users::LockableTest

  context "account locking" do
    setup do
      @user = Factory(:user, :login => "someuser", :failed_login_attempts => Users::Lockable::MAXIMUM_FAILED_ATTEMPTS - 1)
    end

    context "lock_access!" do
      setup do
        @user.lock_access!
      end

      should "lock account" do
        assert @user.access_locked?
      end
    end

    context "unlocking access" do
      should "unlock account, and log that it has done so" do
        ::Users::Lockable.expects(:log_account_locking_activity).with("User someuser unlocked automatically")
        @user.unlock_access!
        assert !@user.access_locked?
      end
    end

    context "exceeding the maximum number of failed login attempts" do
      setup do
        @user.failed_login!
      end

      should "lock account" do
        assert @user.access_locked?
      end
    end

  end

  context "Users::Lockable.log_account_locking_activity" do

    should "log the string it is passed with a log type prefix and a timestamp" do
      Rails.logger.expects(:info).with("[Account Locking] 2012-09-09 12:34: User foo locked by bar")
      Timecop.freeze(Time.zone.parse("2012-09-09 12:34Z")) do
        ::Users::Lockable.log_account_locking_activity("User foo locked by bar")
      end
    end
    
  end

end
