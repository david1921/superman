require File.dirname(__FILE__) + "/../test_helper"

class SyndicatedDealsControllerTest < ActionController::TestCase

  context "an unauthenticated user" do

    setup do
      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @target_publisher = Factory(:publisher)
    end

    should "NOT be able to view syndicated deal index" do
      get_index_results_in_redirect_to_login
    end

    should "NOT be able to create syndicated deal" do
      post_create_results_in_redirect_to_login
    end

    should "NOT be able to destroy syndicated deal" do
      post_destroy_results_in_redirect_to_login
    end

  end

  context "a user without admin privilege" do

    setup do
      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @non_admin_user = Factory(:user_without_company)
      @target_publisher = Factory(:publisher)
    end

    should "NOT be able to view syndicated deal index" do
      login_as @non_admin_user
      get_index_results_in_redirect_to_login
    end

    should "NOT be able to create syndicated deal" do
      login_as @non_admin_user
      post_create_results_in_redirect_to_login
    end

    should "NOT be able to destroy syndicated deal" do
      login_as @non_admin_user
      post_destroy_results_in_redirect_to_login
    end

  end

  context "a user not belonging to self service publisher" do

    setup do
      @publisher = Factory(:publisher, :self_serve => true)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @another_publisher = Factory(:publisher, :self_serve => true)
      @unauthorized_user = Factory(:user, :company => @another_publisher)
      @target_publisher = Factory(:publisher)
    end

    should "NOT be able to view syndicated deal index" do
      login_as @unauthorized_user
      get_index_results_in_record_not_found
    end

    should "NOT be able to create syndicated deal" do
      login_as @unauthorized_user
      post_create_results_in_record_not_found
    end

    should "NOT be able to destroy syndicated deal" do
      login_as @unauthorized_user
      post_destroy_results_in_record_not_found
    end

  end

  context "a user belonging to non self service publisher" do

    setup do
      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @another_publisher = Factory(:publisher)
      @unauthorized_user = Factory(:user, :company => @another_publisher)
      @target_publisher = Factory(:publisher)
    end

    should "NOT be able to view syndicated deal index" do
      login_as @unauthorized_user
      get_index_results_in_record_not_found
    end

    should "NOT be able to create syndicated deal" do
      login_as @unauthorized_user
      post_create_results_in_record_not_found
    end

    should "NOT be able to destroy syndicated deal" do
      login_as @unauthorized_user
      post_destroy_results_in_record_not_found
    end

  end

  context "a user not belonging to advertiser" do

    setup do
      @publisher = Factory(:publisher, :self_serve => true, :advertiser_self_serve => true)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @another_advertiser = Factory(:advertiser, :publisher => @publisher)
      @unauthorized_user = Factory(:user, :company => @another_advertiser)
      @target_publisher = Factory(:publisher)
    end

    should "NOT be able to view syndicated deal index" do
      login_as @unauthorized_user
      get_index_results_in_record_not_found
    end

    should "NOT be able to create syndicated deal" do
      login_as @unauthorized_user
      post_create_results_in_record_not_found
    end

    should "NOT be able to destroy syndicated deal" do
      login_as @unauthorized_user
      post_destroy_results_in_record_not_found
    end

  end

  context "a user belonging to a non self service advertiser" do

    setup do
      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @unauthorized_user = Factory(:user, :company => @advertiser)
      @target_publisher = Factory(:publisher)
    end

    should "NOT be able to view syndicated deal index" do
      login_as @unauthorized_user
      get_index_results_in_record_not_found
    end

    should "NOT be able to create syndicated deal" do
      login_as @unauthorized_user
      post_create_results_in_record_not_found
    end

    should "NOT be able to destroy syndicated deal" do
      login_as @unauthorized_user
      post_destroy_results_in_record_not_found
    end

  end

  context "an admin user" do

    setup do
      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @admin_user = Factory(:admin)
      @target_publisher = Factory(:publisher)
    end

    should "be able to view syndicated deal index" do
      login_as @admin_user
      get_index_with_success
    end

    should "be able to create syndicated deal" do
      login_as @admin_user
      post_create_with_success
    end

    should "be able to destroy syndicated deal" do
      login_as @admin_user
      post_destroy_with_success
    end

  end

  context "a user belonging to self service publisher" do

    setup do
      @publisher = Factory(:publisher, :self_serve => true)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @authorized_user = Factory(:user, :company => @publisher)
      @target_publisher = Factory(:publisher)
    end

    should "be able to view syndicated deal index" do
      login_as @authorized_user
      get_index_with_success
    end

    should "be able to create syndicated deal" do
      login_as @authorized_user
      post_create_with_success
    end

    should "be able to destroy syndicated deal" do
      login_as @authorized_user
      post_destroy_with_success
    end

  end

  context "a user belonging to self service advertiser" do

    setup do
      @publisher = Factory(:publisher, :self_serve => true, :advertiser_self_serve => true)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @authorized_user = Factory(:user, :company => @advertiser)
      @target_publisher = Factory(:publisher)
    end

    should "be able to view syndicated deal index" do
      login_as @authorized_user
      get_index_with_success
    end

    should "be able to create syndicated deal" do
      login_as @authorized_user
      post_create_with_success
    end

    should "be able to destroy syndicated deal" do
      login_as @authorized_user
      post_destroy_with_success
    end

  end

  context "syndicate deals" do

    setup do
      @admin_user = Factory(:admin)
      @target_publisher = Factory(:publisher)
      @daily_deal = Factory(:daily_deal_for_syndication)
    end

    should "NOT display syndicated deals if none exist" do
      login_as @admin_user
      get :index, :daily_deal_id => @daily_deal.to_param
      assert_response :success
      assert_template :index
      assert_layout :application
      assert_select "h3", :count => 0, :text => "Syndicated Deals"
      assert_select "a[href=*]", :count => 0, :text => "Delete"
      assert_select "label", :count => 1, :text => "Syndicate To"
      assert_select "select[name='publisher_id']", :count => 1
    end

    should "display syndicated deals if one exists" do
      syndicated_deal = syndicate(@daily_deal, @target_publisher)
      login_as @admin_user
      get :index, :daily_deal_id => @daily_deal.to_param
      assert_response :success
      assert_template :index
      assert_layout :application
      assert_select "h3", :count => 1, :text => "Syndicated Deals"
      assert_select "a[href=?]", daily_deal_syndicated_deal_path(@daily_deal, syndicated_deal),:count => 1, :text => "Delete"
      assert_select "a[href=?]", edit_daily_deal_path(syndicated_deal),:count => 1, :text => "Edit"
      assert_select "label", :count => 1, :text => "Syndicate To"
      assert_select "select[name='publisher_id']", :count => 1

    end

    should "syndicate a deal" do
      daily_deal = DailyDeal.find(@daily_deal.id);
      assert_equal 0, daily_deal.syndicated_deals.count

      login_as @admin_user
      post :create, :daily_deal_id => @daily_deal.to_param, :publisher_id => @target_publisher.id
      assert_redirected_to daily_deal_syndicated_deals_path(@daily_deal)

      daily_deal = DailyDeal.find(@daily_deal.id);
      assert_equal 1, daily_deal.syndicated_deals.count
      syndicated_deal = daily_deal.syndicated_deals.first
      assert_equal "Created syndicated deal for #{syndicated_deal.publisher.name}", flash[:notice]
    end

    should "delete syndicated deal" do
      syndicated_deal = syndicate(@daily_deal, @target_publisher)
      daily_deal = DailyDeal.find(@daily_deal.id);
      assert_equal 1, daily_deal.syndicated_deals.count

      login_as @admin_user
      post :destroy, :daily_deal_id => @daily_deal.to_param, :id => syndicated_deal.to_param

      assert DailyDeal.find(syndicated_deal.id).deleted?
      assert_redirected_to daily_deal_syndicated_deals_path(@daily_deal)
      assert_equal flash[:notice], "Syndicated daily deal was deleted."
    end

  end

  context "syndicated Travelsavers deals" do

    setup do
      @admin_user = Factory(:admin)
      @publisher_not_in_ts_syndication_network = Factory(:publisher, :in_travelsavers_syndication_network => false)
      @daily_deal = Factory(:travelsavers_daily_deal_for_syndication)
    end

    should "offer no publishers to syndicate to when no publishers have in_travelsavers_syndication_network set to true" do
      login_as @admin_user
      get :index, :daily_deal_id => @daily_deal.to_param
      assert_response :success
      assert_select "select[name='publisher_id']" do
        assert_select "option", false
      end
    end

    should "offer publishers to syndicate to when they have in_travelsavers_syndication_network set to true" do
      @publisher_in_ts_syndication_network = Factory(:publisher, :in_travelsavers_syndication_network => true)
      login_as @admin_user
      get :index, :daily_deal_id => @daily_deal.to_param
      assert_response :success
      assert_select "select[name='publisher_id']" do
        assert_select "option", :count => 1
        assert_select "option[value=#{@publisher_in_ts_syndication_network.id}]"
      end
    end

  end

  private

  def get_index_results_in_redirect_to_login
    @daily_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher, :advertiser => @advertiser)
    @syndicated_deal = syndicate(@daily_deal, @target_publisher)
    get :index, :daily_deal_id => @daily_deal.to_param
    assert_redirected_to new_session_path
  end

  def post_create_results_in_redirect_to_login
    @daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    post :create, :daily_deal_id => @daily_deal.to_param, :publisher_id => @target_publisher.id
    assert_redirected_to new_session_path
  end

  def post_destroy_results_in_redirect_to_login
    @daily_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher, :advertiser => @advertiser)
    @syndicated_deal = syndicate(@daily_deal, @target_publisher)
    post :destroy, :daily_deal_id => @daily_deal.to_param, :id => @syndicated_deal.to_param
    assert_redirected_to new_session_path
  end

  def get_index_results_in_record_not_found
    @daily_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher, :advertiser => @advertiser)
    @syndicated_deal = syndicate(@daily_deal, @target_publisher)
    assert_raises(ActiveRecord::RecordNotFound) do
      get :index, :daily_deal_id => @daily_deal.to_param
    end
  end

  def post_create_results_in_record_not_found
    @daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    assert_raises(ActiveRecord::RecordNotFound) do
      post :create, :daily_deal_id => @daily_deal.to_param, :publisher_id => @target_publisher.id
    end
  end

  def post_destroy_results_in_record_not_found
    @daily_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher, :advertiser => @advertiser)
    @syndicated_deal = syndicate(@daily_deal, @target_publisher)
    assert_raises(ActiveRecord::RecordNotFound) do
      post :destroy, :daily_deal_id => @daily_deal.to_param, :id => @syndicated_deal.to_param
    end
  end

  def get_index_with_success
    @daily_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher, :advertiser => @advertiser)
    @syndicated_deal = syndicate(@daily_deal, @target_publisher)
    get :index, :daily_deal_id => @daily_deal.to_param
    assert_response :success
    assert_template :index
    assert_layout :application
  end

  def post_create_with_success
    @daily_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher, :advertiser => @advertiser)
    post :create, :daily_deal_id => @daily_deal.to_param, :publisher_id => @target_publisher.id
    @daily_deal.reload
    assert_equal flash[:notice], "Created syndicated deal for #{@target_publisher.name}"
    assert_equal 1, @daily_deal.syndicated_deals.size, "daily deal should have 1 syndicated deal"
    assert       @daily_deal.available_for_syndication?, "daily deal should be marked as available for syndication"
    assert_redirected_to daily_deal_syndicated_deals_path(@daily_deal)
  end

  def post_destroy_with_success
    @daily_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher, :advertiser => @advertiser)
    @syndicated_deal = syndicate(@daily_deal, @target_publisher)
    post :destroy, :daily_deal_id => @daily_deal.to_param, :id => @syndicated_deal.to_param
    assert_equal flash[:notice], "Syndicated daily deal was deleted."
    assert_redirected_to daily_deal_syndicated_deals_path(@daily_deal)
  end
end
