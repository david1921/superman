require File.dirname(__FILE__) + "/../../models_helper"

class Users::LockableTest < Test::Unit::TestCase

  class UserStub
    stubs(:named_scope)
    include Users::Core
    include Users::Lockable
    attr_accessor :locked_at, :failed_login_attempts
  end

  context "account locking" do
    setup do
      @user = UserStub.new
      @user.stubs(:randomize_password!)
      @user.stubs(:save)
      @user.stubs(:login).returns("bob")
    end

    context "lock_access!" do
      should "set locked_at" do
        Timecop.freeze(Time.now) do
          @user.expects(:locked_at=).with(Time.now)
          @user.expects(:save)
          @user.lock_access!
        end
      end
    end

    context "unlock_access!" do
      should "clear locked_at and set failed_login_attempts to 0" do
        Timecop.freeze(Time.now) do
          @user.expects(:locked_at=).with(nil)
          @user.expects(:failed_login_attempts=).with(0)
          @user.expects(:save)
          @user.unlock_access!
        end
      end
    end

    context "given account is locked" do
      setup do
        @user.expects(:locked_at).returns(Time.now)
      end

      context "access_locked?" do
        should "return true" do
          assert_equal true, @user.access_locked?
        end
      end
    end

    context "given account is not locked" do
      setup do
        @user.expects(:locked_at).returns(nil)
      end

      context "access_locked?" do
        should "return false" do
          assert_equal false, @user.access_locked?
        end
      end
    end

    context "failed_login!" do
      should "record failed login" do
        @user.expects(:save).once
        @user.failed_login_attempts = 1
        @user.failed_login!
        assert_equal 2, @user.failed_login_attempts
      end

      context "exceeding the maximum failed attempts" do
        should "lock account X" do
          @user.failed_login_attempts = Users::Lockable::MAXIMUM_FAILED_ATTEMPTS - 1
          @user.failed_login!
          assert @user.locked_at
        end
      end

      context "not exceeding the maximum failed attempts" do
        should "not lock account" do
          @user.failed_login_attempts = 0
          @user.failed_login!
          assert !@user.locked_at
        end
      end
    end

    context "successful_login!" do
      should "clear failed login attempts record and save" do
        @user.expects(:save).once
        @user.failed_login_attempts = 1
        @user.successful_login!
        assert_equal 0, @user.failed_login_attempts
      end
    end

  end

end
