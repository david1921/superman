require File.dirname(__FILE__) + "/../../test_helper"

class Admin::ConsumersControllerTest < ActionController::TestCase
  fast_context "as admin" do
    setup do
      login_as Factory(:admin)
    end

    fast_context "on GET :new" do
      setup do
        get :new
      end
      should assign_to(:consumer)
      should respond_with(:success)
      should render_template(:edit)
      should_not set_the_flash

      should "not show the Lock Access links" do
        assert_select "a#lock-access", false
        assert_select "a#unlock-access", false
      end
    end

    fast_context "on POST :create" do
      fast_context "with valid data" do
        setup do
          publisher = Factory(:publisher)
          post :create, :consumer => {
                          :publisher_id => publisher.id,
                          :first_name => "Willie",
                          :last_name => "Nelson",
                          :email => "willie@example.com",
                          :agree_to_terms => true,
                          :password => "secret",
                          :password_confirmation => "secret"
                        }
        end

        should assign_to(:consumer)
        should redirect_to("consumer edit page") { edit_admin_consumer_path(assigns(:consumer)) }
        should set_the_flash
      end

      fast_context "with invalid data" do
        setup do
          publisher = Factory(:publisher)
          post :create, :consumer => {
                          :publisher_id => publisher.id,
                          :first_name => "Willie",
                          :last_name => "Nelson",
                          :agree_to_terms => true
                        }
        end

        should assign_to(:consumer)
        should respond_with(:success)
        should render_template(:consumer)
      end
    end

    fast_context "on GET :edit" do
      setup do
        @consumer = Factory(:consumer)
        get :edit, :id => @consumer.to_param
      end

      should assign_to(:consumer)
      should respond_with(:success)
      should render_template(:edit)
      should_not set_the_flash

      should "show the Lock Access link with an non-locked consumer" do
        assert !@consumer.access_locked?
        assert_select "a#lock-access[href='#{lock_user_lock_path(@consumer)}']"
        assert_select "a#unlock-access", false
      end
    end

    fast_context "on GET :edit with a locked consumer account" do
      setup do
        @consumer = Factory(:consumer)
        @consumer.lock_access!
        get :edit, :id => @consumer.to_param
      end

      should "show the Unlock Access link" do
        assert_select "a#unlock-access[href='#{unlock_user_lock_path(@consumer)}']"
        assert_select "a#lock-access", false
      end
    end
  end

  fast_context "as anonymous" do
    fast_context "on GET :new" do
      setup do
        get :new
      end
      should redirect_to("/session/new")
    end

    fast_context "on GET :edit" do
      setup do
        consumer = Factory(:consumer)
        get :edit, :id => consumer.to_param
      end
      should redirect_to("/session/new")
    end

    fast_context "on PUT :update" do
      setup do
        consumer = Factory(:consumer)
        put :edit, :id => consumer.to_param
      end
      should redirect_to("/session/new")
    end
  end

  fast_context "as consumer" do
    setup do
      @consumer = Factory(:consumer)
      login_as @consumer
    end

    fast_context "on GET :new" do
      setup do
        get :new
      end
      should redirect_to("/session/new")
    end

    fast_context "on GET :edit" do
      setup do
        get :edit, :id => @consumer.to_param
      end
      should redirect_to("/session/new")
    end

    fast_context "on POST :create" do
      setup do
        post :create
      end
      should redirect_to("/session/new")
    end

    fast_context "on PUT :update" do
      setup do
        put :edit, :id => @consumer.to_param
      end
      should redirect_to("/session/new")
    end
  end

  fast_context "#authorize_edit_update filter" do
    setup do
      @consumer = Factory(:consumer)
    end

    fast_context "not logged in" do
      should "deny edit access" do assert_edit_access_denied; end
      should "deny update access" do assert_update_access_denied; end
    end

    fast_context "as a user that cannot manage any consumers" do
      setup do
        login_as Factory(:user_without_company, :can_manage_consumers => false)
      end

      should "deny edit access" do assert_edit_access_denied; end
      should "deny update access" do assert_update_access_denied; end
    end

    fast_context "as a user that cannot manage the consumer" do
      setup do
        login_as Factory(:user_without_company, :can_manage_consumers => true)
      end

      should "deny edit access" do assert_edit_access_denied; end
      should "deny update access" do assert_update_access_denied; end
    end

    context "as a user that can manage the consumer" do
      setup do
        @user = Factory(:user_without_company, :can_manage_consumers => true)
        @user.tap do |user|
          user.user_companies.create!(:company => @consumer.publisher)
        end
        login_as @user
      end

      should "not deny edit access" do
        assert !@consumer.access_locked?
        get :edit, :id => @consumer.to_param
        assert_response :ok
        assert_template "edit"
        assert_select "a#lock-access"
      end

      should "not deny update access" do
        put :update, :id => @consumer.to_param, :consumer => {}
        assert_response :redirect
        assert_redirected_to edit_admin_consumer_path(@consumer)
      end
    end

  end

  private

  def assert_edit_access_denied
    assert_access_denied do
      get :edit, :id => @consumer.id
    end
  end

  def assert_update_access_denied
    assert_access_denied do
      put :update, :id => @consumer.id
    end
  end

  def assert_access_denied(&block)
    yield block
    assert_redirected_to new_session_path
    assert_equal 'Unauthorized access', flash[:notice]
  end

end
