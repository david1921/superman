require File.dirname(__FILE__) + "/../test_helper"

class UserLocksControllerTest < ActionController::TestCase

  context "logged in as an admin" do

    setup do
      @user = Factory(:user, :login => "nlawson")
      @user_path = publisher_user_path(@user.publisher, @user)

      @admin = Factory(:admin, :login => "joliver")
      login_as @admin

      @request.env["HTTP_REFERER"] = @user_path
    end

    fast_context "lock" do
      setup do
        @user.unlock_access!
        ::Users::Lockable.expects(:log_account_locking_activity).with("User nlawson locked by joliver")
        put :lock, :id => @user.to_param
      end

      should "lock user account" do
        assert @user.reload.access_locked?
      end

      should "redirect to user show path" do
        assert_redirected_to @user_path
      end

      should "set flash message" do
        assert !flash[:notice].empty?
      end
    end

    fast_context "unlock" do
      setup do
        @user.lock_access!
        @user.update_attributes!(:email => "test@example.com")
        ::Users::Lockable.expects(:log_account_locking_activity).with("User nlawson unlocked by joliver")
        put :unlock, :id => @user.to_param
      end

      should "unlock user account" do
        assert !@user.reload.access_locked?
      end

      should "redirect to user show path" do
        assert_redirected_to @user_path
      end

      should "set flash message" do
        assert !flash[:notice].empty?
      end

    end

    fast_context "lock with a consumer" do

      setup do
        @consumer = Factory :consumer
        assert !@consumer.access_locked?
        @request.env["HTTP_REFERER"] = "http://test.host/previous/page"
        put :lock, :id => @consumer.to_param
        @consumer.reload
      end
      
      should "lock the user account" do
        assert @consumer.access_locked?
      end

      should "redirect to :back" do
        assert_redirected_to "http://test.host/previous/page"
      end

      should "set flash message" do
        assert !flash[:notice].empty?
      end

    end

    fast_context "unlock with a consumer" do
      
      setup do
        @consumer = Factory :consumer
        @consumer.lock_access!
        @request.env["HTTP_REFERER"] = "http://test.host/previous/page"
        put :unlock, :id => @consumer.to_param
        @consumer.reload
      end
      
      should "unlock user account" do
        assert !@consumer.access_locked?
      end

      should "redirect to :back" do
        assert_redirected_to "http://test.host/previous/page"
      end

      should "set flash message" do
        assert !flash[:notice].empty?
      end

    end

    fast_context "GET to :index" do

      setup do
        setup_locked_users
        get :index
      end
      
      should "respond successfully" do
        assert_response :success
      end

      should "show a table of locked users, with links to their respective edit pages" do
        assert_select "table#locked-users" do
          assert_select "tr", :count => 7

          assert_select "tr" do
            assert_select "th", "Name"
            assert_select "th", "Login"
            assert_select "th", "Publisher"
            assert_select "th", "Locked At"
            assert_select "th", "Created At"
          end

          assert_select "tr" do
            assert_select "td a[href=#{edit_admin_consumer_path(:id => @locked_consumer_1.to_param)}]"
            assert_select "td", @locked_consumer_1.login
            assert_select "td", @locked_consumer_1.name
            assert_select "td", @locked_consumer_1.publisher.label
            assert_select "td", @locked_consumer_1.locked_at.to_s(:compact)
            assert_select "td", @locked_consumer_1.created_at.to_s(:compact)
          end
          assert_select "td a[href=#{edit_admin_consumer_path(:id => @locked_consumer_2.to_param)}]"
          assert_select "td a[href=#{edit_advertiser_user_path(:advertiser_id => @locked_advertiser_user.company.to_param, :id => @locked_advertiser_user.to_param)}]"
          assert_select "td a[href=#{edit_publisher_user_path(:publisher_id => @locked_publisher_user.company.to_param, :id => @locked_publisher_user.to_param)}]"
          assert_select "td a[href=#{edit_publishing_group_user_path(:publishing_group_id => @locked_pub_group_user.company.to_param, :id => @locked_pub_group_user.to_param)}]"
          assert_select "td a[href=#{edit_admin_path(:id => @locked_admin.to_param)}]"
        end
      end

      should "assign to @locked_users, with most recently locked users first" do
        assert_equal [
          @locked_publisher_user, @locked_pub_group_user, @locked_advertiser_user,
          @locked_consumer_1, @locked_consumer_2, @locked_admin], assigns(:locked_users)
      end

    end

    fast_context "GET to :index, with paging params" do

      setup do
        setup_locked_users
        get :index, :page => 2, :per_page => 2
      end
      
      should "respond successfully" do
        assert_response :success
      end

      should "assign to @locked_users, with most recently locked users first, with results at the appropriate page boundary" do
        assert_equal [@locked_advertiser_user, @locked_consumer_1], assigns(:locked_users)
      end

    end

    fast_context "GET to :index, without paging params" do
      
      should "use a default of page 1 and per_page 50" do
        locked_stub = mock("User.locked")
        locked_stub.expects(:paginate).with(:page => 1, :per_page => 50).returns(stub(:each => nil, :total_pages => 1))
        User.expects(:locked).returns(locked_stub)
        get :index
      end

    end

  end

  context "logged in as a user that can manage consumers" do

    setup do
      @user_that_can_manage_consumers = Factory :user, :can_manage_consumers => true
      @manageable_consumer = Factory :consumer, :publisher => @user_that_can_manage_consumers.company
      @unmanageable_consumer = Factory :consumer
      @request.env["HTTP_REFERER"] = "http://test.host/previous/page"
      login_as @user_that_can_manage_consumers
    end

    should "be able to lock a consumer account they can manage" do
      assert !@manageable_consumer.access_locked?
      put :lock, :id => @manageable_consumer.to_param
      assert_redirected_to "http://test.host/previous/page"
      assert @manageable_consumer.reload.access_locked?
    end

    should "return a 403 Forbidden when trying to lock a consumer they can't manage" do
      assert !@unmanageable_consumer.access_locked?
      put :lock, :id => @unmanageable_consumer.to_param
      assert_response :forbidden
      assert !@unmanageable_consumer.reload.access_locked?
    end

    should "return a 403 Forbidden when trying to lock an admin account" do
      admin = Factory :admin
      put :lock, :id => admin.to_param
      assert_response :forbidden
      assert !admin.reload.access_locked?
    end

    should "return a 403 Forbidden on a GET to :index"
    
  end

  context "not logged in" do

    setup do
      @user = Factory(:user)
    end

    fast_context "lock" do
      setup do
        put :lock, :id => @user.to_param
      end

      should "redirect to the login page" do
        assert_redirected_to new_session_path
      end
    end

    fast_context "unlock" do
      setup do
        put :unlock, :id => @user.to_param
      end

      should "redirect to the login page" do
        assert_redirected_to new_session_path
      end
    end

    fast_context "index" do

      setup do
        get :index
      end

      should "redirect to the login page" do
        assert_redirected_to new_session_path
      end
      
    end

  end

  def setup_locked_users
    @locked_admin = Factory :admin, :login => "admin1"
    @locked_consumer_1 = Factory :consumer
    @locked_consumer_2 = Factory :consumer
    @locked_advertiser_user = Factory :user, :company => Factory(:advertiser)
    @locked_publisher_user = Factory :user, :company => Factory(:publisher)
    @locked_pub_group_user = Factory :user, :company => Factory(:publishing_group)

    @unlocked_admin = Factory :admin, :login => "admin2"
    @unlocked_consumer = Factory :consumer
    @unlocked_advertiser_user = Factory :user, :company => Factory(:advertiser)
    @unlocked_publisher_user = Factory :user, :company => Factory(:publisher)
    @unlocked_pub_group_user = Factory :user, :company => Factory(:publishing_group)

    Timecop.freeze(Time.zone.parse("2012-10-10 12:34"))
    @locked_admin.lock_access!
    Timecop.freeze(Time.zone.parse("2012-10-10 13:34"))
    @locked_consumer_2.lock_access!
    Timecop.freeze(Time.zone.parse("2012-10-11 13:34"))
    @locked_consumer_1.lock_access!
    Timecop.freeze(Time.zone.parse("2012-10-13 13:34"))
    @locked_advertiser_user.lock_access!
    Timecop.freeze(Time.zone.parse("2012-10-13 16:34"))
    @locked_pub_group_user.lock_access!
    Timecop.freeze(Time.zone.parse("2012-10-15 16:34"))
    @locked_publisher_user.lock_access!
    Timecop.return
  end

end
