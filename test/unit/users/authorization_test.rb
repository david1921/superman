require File.dirname(__FILE__) + "/../../test_helper"

class Users::AuthorizationTest < ActiveSupport::TestCase

  context "#can_manage_consumer?" do
    setup do
      @user = Factory(:user)
      @consumer = Factory(:consumer)
    end

    context "with full admin privilege" do
      should "return true" do
        @user.admin_privilege = User::FULL_ADMIN
        @user.save!
        assert @user.can_manage_consumer?(@consumer)
      end
    end

    context "with restricted admin privilege" do
      setup do
        @user.admin_privilege = User::RESTRICTED_ADMIN
        @user.save!
      end

      context "for manageable publisher" do
        should "return true" do
          @user.user_companies.create(:company => @consumer.publisher)
          assert @user.can_manage_consumer?(@consumer)
        end
      end

      context "for non-manageable publisher" do
        should "return false" do
          @user.user_companies = []
          assert !@user.can_manage_consumer?(@consumer)
        end
      end
    end

    context "can manage consumers" do
      setup do
        @user.can_manage_consumers = true
        @user.save!
      end

      context "for manageable publisher" do
        should "return true" do
          @user.user_companies = []
          @user.user_companies.create!(:company => @consumer.publisher)
          assert @user.can_manage_consumer?(@consumer)
        end
      end

      context "for non-manageable publisher" do
        should "return false" do
          @user.user_companies = []
          assert !@user.can_manage_consumer?(@consumer)
        end
      end
    end

    context "cannot manage consumers" do
      should "return false" do
        assert !@user.can_manage_consumers
        assert !@user.can_manage_consumer?(@consumer)
      end
    end
  end

end
