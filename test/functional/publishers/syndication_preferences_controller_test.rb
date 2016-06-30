require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::SyndicationPreferencesController::EditTest < ActionController::TestCase
  tests Publishers::SyndicationPreferencesController

  def setup
    @user = Factory(:admin)
    @publisher = Factory(:publisher)
  end

  should "require authenticated user" do
    [:update, :edit].each do |action|
      get action
      assert_response :redirect
    end
  end

  should "require admin privilege" do
    login_as Factory(:user)
    [:update, :edit].each do |action|
      get action
      assert_response :redirect
    end
  end

  context "edit" do
    setup do
      login_as @user
    end

    should "render :edit" do
      get :edit, :publisher_id => @publisher.to_param
      assert_template :edit
    end

    should "assign @publisher by id" do
      get :edit, :publisher_id => @publisher.to_param
      assert_equal @publisher, assigns(:publisher)
    end

    should "render syndication preferences" do
      get :edit, :publisher_id => @publisher.to_param
      assert_template :edit

      assert_select "#syndication_preferences" do
        assert_select "form[action=#{publisher_syndication_preferences_path(@publisher)}]" do
          assert_select "input[type=hidden][name='publisher[publishers_excluded_from_distribution_ids][]'][value='']"

          assert_select "fieldset#publishers_to_exclude_from_distribution" do
            assert_select "legend", "Do not make my deals available to the following publishers:"
            assert_select "a.select_all", "Select All"
            assert_select "a.select_none", "None"
            assert_select "a.reset", "Reset"

            Publisher.in_syndication_network.each do |pub|
              assert_select "label[for=exclude_publisher_#{pub.id}]"
              assert_select "input[type=checkbox][name='publisher[publishers_excluded_from_distribution_ids][]'][value=#{pub.id}]"
            end
          end

          # DJZ: May be added after launch
          #assert_select "fieldset#new_publisher_defaults" do
          #  assert_select "legend", "When a new publisher joins the network:"
          #  assert_select "input[type=radio][name=publisher[exclude_new_publishers_from_distribution]][value=0]"
          #  assert_select "input[type=radio][name=publisher[exclude_new_publishers_from_distribution]][value=1]"
          #end

          assert_select "input[type=submit][value=Save]"
        end

        assert_select "input[type=submit][value=Cancel]"
      end
    end
  end

  context "update" do
    setup do
      login_as @user
    end

    context "with valid attributes" do
      should "update publishers excluded from distribution" do
        publishers = [Factory(:publisher), Factory(:publisher)]
        put :update, :publisher_id => @publisher.to_param, :publisher => { :publishers_excluded_from_distribution_ids => publishers.map(&:id) }
        assert_response :redirect

        publishers.each do |pub|
          assert_contains @publisher.publishers_excluded_from_distribution, pub
        end

        put :update, :publisher_id => @publisher.to_param, :publisher => { :publishers_excluded_from_distribution_ids => [] }
        assert_response :redirect
        assert @publisher.publishers_excluded_from_distribution(true).empty?
      end

      should "redirect to the publisher edit page" do
        put :update, :publisher_id => @publisher.to_param
        assert_redirected_to edit_publisher_url(@publisher)
      end

      should "set a flash notice" do
        put :update, :publisher_id => @publisher.to_param
        assert_equal 'Syndication Preferences were saved.', flash[:notice]
      end
    end

    #context "with invalid attributes" do
    #  should "render edit" do
    #    put :update, :publisher_id => @publisher.to_param
    #    assert_template :edit
    #  end
    #
    #  should "set a flash error" do
    #    put :update, :publisher_id => @publisher.to_param
    #    assert_equal 'The preferences could not be saved.', flash[:error]
    #  end
    #end
  end
end
