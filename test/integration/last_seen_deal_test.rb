require File.dirname(__FILE__) + "/../test_helper"

class LastSeenDealTest < ActionController::IntegrationTest

  include ConsumersHelper

  # NOTE:
  # after the user signs in they will sometimes get 2 redirects.  the first to the last seen deal and the second to their publishers syndicated version of the deal.
  # unit test doesn't seem to support testing double redirects, so below we just do a get request to the the page returned in the first redirect then assert on the second redirect.

  context "logging in" do
    setup do
      @publishing_group = Factory(:publishing_group, :enable_redirect_to_last_seen_deal_on_login => true)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @consumer = Factory(:consumer, :publisher => @publisher, :email => "foobar@yahoo.com", :password => "password", :password_confirmation => "password")
      @side_daily_deal = Factory(:side_daily_deal, :publisher => @publisher)
      @featured_deal = Factory(:featured_daily_deal, :publisher => @publisher)
    end

    context "using the consumer's publisher" do
      should "redirect to the last seen deal after viewing a deal's show page and then logging in" do
        get daily_deal_url(@side_daily_deal)
        post "/publishers/#{@publisher.id}/daily_deal_session/create", :publisher_id => @publisher.to_param, :session => { :email => "foobar@yahoo.com", :password => "password" }
        assert_response :redirect
        assert_redirected_to daily_deal_url(@side_daily_deal)
      end

      should "redirect to the last seen deal after viewing the publisher's deal of the day and then logging in" do
        get public_deal_of_day_url(@publisher.label)
        post "/publishers/#{@publisher.id}/daily_deal_session/create", :publisher_id => @publisher.to_param, :session => { :email => "foobar@yahoo.com", :password => "password" }
        assert_response :redirect
        assert_redirected_to daily_deal_url(@featured_deal)
      end

      should "redirect to the publisher's deal of the day after log in without viewing a deal" do
        post "/publishers/#{@publisher.id}/daily_deal_session/create", :publisher_id => @publisher.to_param, :session => { :email => "foobar@yahoo.com", :password => "password" }
        assert_response :redirect
        assert_redirected_to public_deal_of_day_url(@publisher.label)
      end
    end

    context "not using the consumer's publisher with allow_publisher_switch_on_login enabled for publishing group" do
      setup do
        @publishing_group.update_attributes!(:enable_redirect_to_users_publisher => true)
        @publishing_group.update_attribute(:allow_publisher_switch_on_login, true)
        @other_publisher = Factory(:publisher, :publishing_group => @publishing_group)
      end

      should "redirect to the consumer's publisher's deal of the day after viewing a deal's show page and then logging in" do
        get daily_deal_url(@side_daily_deal)
        post "/publishers/#{@other_publisher.id}/daily_deal_session/create", :publisher_id => @other_publisher.to_param, :session => { :email => "foobar@yahoo.com", :password => "password" }
        assert_response :redirect
        get daily_deal_url(@side_daily_deal)
      end

      should "redirect to the consumer's publisher's deal of the day after viewing the publisher's deal of the day page and then logging in" do
        cookies['publisher_label'] = @publisher.label   # because the user is not logged in they would redirect to bcbsa-national's deal page unless this cookie is set.  Crazy!
        get public_deal_of_day_url(@publisher.label)
        post "/publishers/#{@other_publisher.id}/daily_deal_session/create", :publisher_id => @other_publisher.to_param, :session => { :email => "foobar@yahoo.com", :password => "password" }
        assert_response :redirect
        assert_redirected_to daily_deal_url(@featured_deal)
      end

      should "redirect to the consumer's publisher's deal of the day after logging in without viewing a deal" do
        post "/publishers/#{@other_publisher.id}/daily_deal_session/create", :publisher_id => @other_publisher.to_param, :session => { :email => "foobar@yahoo.com", :password => "password" }
        assert_response :redirect
        assert_redirected_to public_deal_of_day_url(@publisher.label)
      end

      should "redirect to the consumer's publisher's version of the syndicated deal after seeing a syndicated deal on another publisher that is also available in the consumer's market and then logging in" do
        source_publisher = Factory(:publisher, :publishing_group => @publishing_group)
        source_deal = Factory(:daily_deal_for_syndication, :publisher => source_publisher, :show_on_landing_page => true)
        syndicated_deal = Factory(:distributed_daily_deal, :source => source_deal, :publisher => @publisher)
        other_syndicated_deal = Factory(:distributed_daily_deal, :source => source_deal, :publisher => @other_publisher)

        get daily_deal_url(other_syndicated_deal)
        assert_redirected_to daily_deal_url(source_deal)
        get daily_deal_url(source_deal)

        post "/publishers/#{@other_publisher.id}/daily_deal_session/create", :publisher_id => @other_publisher.to_param, :session => { :email => "foobar@yahoo.com", :password => "password" }
        assert_response :redirect
        assert_redirected_to daily_deal_url(source_deal)
        get daily_deal_url(source_deal)
        assert_response :redirect
        assert_redirected_to daily_deal_url(syndicated_deal)
      end

      should "redirect to the consumer's publisher's deal of the day after seeing a syndicated deal on another publisher that is unavailable in the consumer's market and then logging in" do
        source_publisher = Factory(:publisher, :publishing_group => @publishing_group)
        source_deal = Factory(:daily_deal_for_syndication, :publisher => source_publisher)
        other_syndicated_deal = Factory(:distributed_daily_deal, :source => source_deal, :publisher => @other_publisher)

        cookies[:publisher_label] = other_syndicated_deal.publisher.label
        get daily_deal_url(other_syndicated_deal)
        post "/publishers/#{@other_publisher.id}/daily_deal_session/create", :publisher_id => @other_publisher.to_param, :session => { :email => "foobar@yahoo.com", :password => "password" }
        assert_response :redirect
        assert_redirected_to daily_deal_url(other_syndicated_deal)
        get daily_deal_url(other_syndicated_deal)
        assert_redirected_to public_deal_of_day_url(@publisher.label)
      end
    end
  end

  context "after consumer activation" do
    setup do
      @publishing_group = Factory(:publishing_group, :enable_redirect_to_last_seen_deal_on_login => true)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @unactivated_consumer = Factory(:consumer, :activated_at => nil, :publisher => @publisher)
      @side_daily_deal = Factory(:side_daily_deal, :publisher => @publisher)
      @featured_deal = Factory(:featured_daily_deal, :publisher => @publisher)
    end

    should "redirect to the last seen deal after viewing a deal's show page and then activating" do
      get daily_deal_url(@side_daily_deal)
      post activate_consumer_url(@unactivated_consumer)
      assert_response :redirect
      assert_redirected_to daily_deal_url(@side_daily_deal)
    end

    should "redirect to the publisher's deal of the day after activating without viewing a deal" do
      post activate_consumer_url(@unactivated_consumer)
      assert_response :redirect
      assert_redirected_to public_deal_of_day_url(@publisher.label)
    end

    context "with enable_redirect_to_users_publisher set for the publishing group" do
      setup do
        @publishing_group.update_attributes(:enable_redirect_to_users_publisher => true)
        @other_publisher = Factory(:publisher, :publishing_group => @publishing_group)
        @source_publisher = Factory(:publisher, :publishing_group => @publishing_group)
        @source_deal = Factory(:daily_deal_for_syndication, :publisher => @source_publisher)
        @other_syndicated_deal = Factory(:distributed_daily_deal, :source => @source_deal, :publisher => @other_publisher)
      end

      should "redirect to the consumer's publisher's version of the syndicated deal after seeing a syndicated deal on another publisher that is also available in the consumer's market and then activating" do
        syndicated_deal = Factory(:distributed_daily_deal, :source => @source_deal, :publisher => @publisher)
        cookies[:publisher_label] = @other_syndicated_deal.publisher.label
        get daily_deal_url(@other_syndicated_deal)
        post activate_consumer_url(@unactivated_consumer)
        assert_response :redirect
        assert_redirected_to daily_deal_url(@other_syndicated_deal)
        get daily_deal_url(@other_syndicated_deal)
        assert_response :redirect
        assert_redirected_to daily_deal_url(syndicated_deal)
      end

      should "redirect to the consumer's publisher's deal of the day after seeing a syndicated deal on another publisher that is unavailable in the consumer's market and then activating" do
        cookies[:publisher_label] = @other_syndicated_deal.publisher.label
        get daily_deal_url(@other_syndicated_deal)
        post activate_consumer_url(@unactivated_consumer)
        assert_response :redirect
        assert_redirected_to daily_deal_url(@other_syndicated_deal)
        get daily_deal_url(@other_syndicated_deal)
        assert_redirected_to public_deal_of_day_url(@publisher.label)
      end
    end
  end
end
