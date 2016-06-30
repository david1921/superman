require File.dirname(__FILE__) + "/../test_helper"

class ConsumerAccountLockingTest < ActiveSupport::TestCase

  context "#authenticate" do

    setup do
      @consumer = Factory :consumer, :email => "test@example.com", :password => "foobar", :password_confirmation => "foobar"
    end

    should "return a Consumer instance when authentication is successful" do
      assert_instance_of Consumer, Consumer.authenticate(@consumer.publisher, "test@example.com", "foobar")
    end

    should "return nil when trying the auth with a non-existent consumer" do
      assert_nil Consumer.authenticate(@consumer.publisher, "doesnotexist@example.com", "foobar")
    end

    should "increment the failed_login_attempts counter for every failed login attempt" do
      assert_difference "@consumer.failed_login_attempts", 2 do
        Consumer.authenticate(@consumer.publisher, "test@example.com", "wrongpassword")
        Consumer.authenticate(@consumer.publisher, "test@example.com", "wrongpassword")
        @consumer.reload
      end
    end

    should "reset failed_login_attempts to 0 when authentication succeeds" do
      Consumer.authenticate(@consumer.publisher, "test@example.com", "wrongpassword")
      @consumer.reload
      assert_equal 1, @consumer.failed_login_attempts
      Consumer.authenticate(@consumer.publisher, "test@example.com", "foobar")
      @consumer.reload
      assert_equal 0, @consumer.failed_login_attempts
    end

    should "return :locked when failed_login_attempts exceeds Users::Lockable::MAXIMUM_FAILED_ATTEMPTS, and set locked_at" do
      assert_equal 5, Users::Lockable::MAXIMUM_FAILED_ATTEMPTS
      @consumer.failed_login_attempts = 4
      @consumer.save!
      assert_nil @consumer.locked_at
      assert_equal :locked, Consumer.authenticate(@consumer.publisher, "test@example.com", "wrongpassword")
      @consumer.reload
      assert @consumer.locked_at.present?
    end
    
  end

end
