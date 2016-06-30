require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class DailyDealsController::Show::RedirectToLocalDealTest

module DailyDealsController::Show
  class RedirectToLocalDealTest < ActionController::TestCase
    tests DailyDealsController

    context '#enable_redirect_to_users_publisher' do
      setup do
        @publishing_group = Factory(:publishing_group, :label => "bcbsa", :enable_redirect_to_users_publisher => true)
        @publisher = Factory(:publisher, :publishing_group => @publishing_group, :label => 'test-pub')
        @consumer = Factory(:consumer, :publisher => @publisher, :email => "foobar@yahoo.com", :password => "password", :password_confirmation => "password")
        @source_publisher = Factory(:publisher, :publishing_group => @publishing_group, :main_publisher => true)
        @other_publisher = Factory(:publisher, :publishing_group => @publishing_group)
        @source_deal = Factory(:daily_deal_for_syndication, :publisher => @source_publisher, :show_on_landing_page => true)
        @syndicated_daily_deal = Factory(:distributed_daily_deal, :source => @source_deal, :publisher => @publisher)
        @other_syndicated_deal = Factory(:distributed_daily_deal, :source => @source_deal, :publisher => @other_publisher)
      end

      should "redirect to the consumer's publisher's version of the source_deal when they are logged in" do
        login_as @consumer
        get :show, :id => @source_deal.to_param
        assert_redirected_to daily_deal_url(@syndicated_daily_deal)
      end

      should "redirect to the consumer's publisher's version of the syndicated_deal when they are logged in" do
        login_as @consumer
        get :show, :id => @other_syndicated_deal.to_param
        assert_redirected_to daily_deal_url(@syndicated_daily_deal)
      end

      should "redirect to the consumer's publisher's version of the source_deal whey they have the publisher_label cookie" do
        @request.cookies['publisher_label'] = @publisher.label
        get :show, :id => @source_deal.to_param
        assert_redirected_to daily_deal_url(@syndicated_daily_deal)
      end

      should "redirect to the consumers's publisher's public deal page with a notice because the deal is not available" do
        random_pub = Factory(:publisher, :publishing_group => @publishing_group)
        random_deal = Factory(:daily_deal, :publisher => random_pub)
        login_as @consumer
        get :show, :id => random_deal.to_param
        assert_equal "Sorry! It appears that your Blue Company is currently not offering this deal. Browse other great deals below, and check for new offers soon.", flash[:notice]
        assert_redirected_to public_deal_of_day_path(@publisher.label)
      end


      should "redirect to the main publisher's public deal page with a notice because the deal is not available and the user is not logged in" do
        random_pub = Factory(:publisher, :publishing_group => @publishing_group)
        random_deal = Factory(:daily_deal, :publisher => random_pub)
        get :show, :id => random_deal.to_param
        assert_equal "Sorry! It appears that your Blue Company is currently not offering this deal. Browse other great deals below, and check for new offers soon.", flash[:notice]
        assert_redirected_to public_deal_of_day_path(@source_publisher.label)
      end

      should "redirect to the main publishers version of the deal when the user is not logged in and doesn't have a publisher_label cookie" do
        get :show, :id => @other_syndicated_deal.to_param
        assert_equal "Oops! Please log in or register to view all deals that are currently available to you.", flash[:notice]
        assert_redirected_to daily_deal_url(@source_deal)
      end

      should "redirect to the main publishers public deal page when the user is not logged in and doesn't have a publisher_label cookie and the main publish does not have a version of the deal on the landing page" do
        @source_deal.update_attributes(:show_on_landing_page => false)
        get :show, :id => @other_syndicated_deal.to_param
        assert_equal "Sorry! It appears that your Blue Company is currently not offering this deal. Browse other great deals below, and check for new offers soon.", flash[:notice]
        assert_redirected_to public_deal_of_day_path(@source_publisher.label)
      end

      should "redirect to the main publishers public deal page because the deal is not shown on the landing page" do
        @source_deal.update_attributes(:show_on_landing_page => false)
        get :show, :id => @source_deal.to_param
        assert_equal "Sorry! It appears that your Blue Company is currently not offering this deal. Browse other great deals below, and check for new offers soon.", flash[:notice]
        assert_redirected_to public_deal_of_day_path(@source_publisher.label)
      end

      should "not redirect because the deal is at the users publisher" do
        login_as @consumer
        get :show, :id => @syndicated_daily_deal.to_param
        assert_response :success
        assert_template :show
      end

      should "not redirect to another deal if the consumer has already bought the deal with single sign on enabled in the publishing group" do
        @publishing_group.update_attribute(:allow_single_sign_on, true)
        @consumer.update_attribute(:publisher_id, @other_publisher.id)
        daily_deal_purchase = Factory(:daily_deal_purchase, :daily_deal => @other_syndicated_deal, :consumer => @consumer)
        @consumer.reload
        @consumer.update_attribute(:publisher_id, @publisher.id)
        login_as @consumer
        get :show, :id => @other_syndicated_deal.to_param
        assert_response :success
        assert_template :show
      end

      should "not redirect a consumer with a master publisher membership code on a publishing group with single sign on enabled when accessing a syndicated deal" do
        @publishing_group.update_attributes(:allow_single_sign_on => true)
        @publishing_group.update_attribute(:require_publisher_membership_codes, true)
        master_publisher_membership_code = Factory(:publisher_membership_code, :publisher => @publisher, :master => true)
        @consumer.update_attribute(:publisher_membership_code, master_publisher_membership_code)
        login_as @consumer
        get :show, :id => @syndicated_daily_deal.to_param
        assert_response :success
        assert_template :show
        assert_nil flash[:notice]
      end

      should "not redirect a consumer with a master publisher membership code on a publishing group with single sign on enabled when accessing the deal at the main publisher" do
        @publishing_group.update_attributes(:allow_single_sign_on => true)
        @publishing_group.update_attribute(:require_publisher_membership_codes, true)
        master_publisher_membership_code = Factory(:publisher_membership_code, :publisher => @publisher, :master => true)
        @consumer.update_attribute(:publisher_membership_code, master_publisher_membership_code)
        @source_deal.update_attributes(:show_on_landing_page => false)
        login_as @consumer
        get :show, :id => @source_deal.to_param
        assert_response :success
        assert_template :show
        assert_nil flash[:notice]
      end

    end
  end
end
