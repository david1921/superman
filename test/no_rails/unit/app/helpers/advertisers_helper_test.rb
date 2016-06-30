require File.dirname(__FILE__) + "/../helpers_helper"

class AdvertisersHelperTest < Test::Unit::TestCase

  def setup
    @helper = Object.new.extend(AdvertisersHelper)
    @user = mock('user')
    @helper.stubs(:current_user).returns(@user)
  end

  context "#can_edit_store_listing?" do
    should "return false when no current user" do
      @helper.stubs(:current_user).returns(nil)
      assert !@helper.can_edit_store_listing?
    end

    context "with current user" do
      setup do
        @helper.stubs(:current_user).returns(@user)
      end

      should "return true for admin" do
        @helper.stubs(:admin_user?).with(@user).returns(true)
        assert @helper.can_edit_store_listing?
      end

      should "return true for entertainment group user" do
        @helper.stubs(:admin_user?).returns(false)
        @helper.stubs(:entertainment_group_user?).with(@user).returns(true)
        assert @helper.can_edit_store_listing?
      end

    end
  end

  context "#entertainment_group_user?" do
    setup do
      @helper.stubs(:admin_user?).returns(false)
    end
    #@user.stubs(:companies).returns([@group])

    should "return false when group not found" do
      @helper.stubs(:entertainment_group).returns(nil)
      assert !@helper.entertainment_group_user?(@user)
    end

    context "entertainment group exists" do
      setup do
        @group = mock('entertainment group')
        @helper.stubs(:entertainment_group).returns(@group)
      end

      should "return false when user companies don't include group'" do
        @user.stubs(:companies).returns([])
        assert !@helper.entertainment_group_user?(@user)
      end

      should "return true when user companies include group" do
        @user.stubs(:companies).returns([@group])
        assert @helper.entertainment_group_user?(@user)
      end

    end
  end
end
