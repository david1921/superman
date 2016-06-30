require File.dirname(__FILE__) + "/../test_helper"

class DailyDealAffiliateRedirectsControllerTest < ActionController::TestCase

  context "create" do
    setup do
      @publisher = Factory(:publisher, :label => "abc-publishing")
      @daily_deal = Factory(:daily_deal,
                            :publisher => @publisher,
                            :affiliate_url => "http://example.com?pub_label=%publisher_label%")
    end

    context "consumer logged in" do
      setup do
        @consumer = Factory(:consumer, :publisher => @daily_deal.publisher)
        login_as @consumer
      end

      should "create new redirect record" do
        assert_difference "@daily_deal.daily_deal_affiliate_redirects.count", 1 do
          post :create, :daily_deal_id => @daily_deal.to_param

          redirect = @daily_deal.daily_deal_affiliate_redirects.last
          assert_equal @consumer.id, redirect.consumer_id
        end
      end

      should "redirect to affiliate URL" do
        post :create, :daily_deal_id => @daily_deal.to_param
        assert_redirected_to daily_deal_affiliate_redirect_path( @daily_deal.daily_deal_affiliate_redirects.last )
      end
    end

    context "consumer logged in for another publisher" do
      setup do
        @publisher2 = Factory(:publisher)
        @consumer = Factory(:consumer, :publisher => @publisher2)
        login_as @consumer
      end

      should "redirect to login page" do
        post :create, :daily_deal_id => @daily_deal.to_param
        assert_redirected_to new_publisher_daily_deal_session_path(@daily_deal.publisher)
      end
    end

    context "no consumer logged in" do
      should "redirect to login page" do
        post :create, :daily_deal_id => @daily_deal.to_param
        assert_redirected_to new_publisher_daily_deal_session_path(@daily_deal.publisher)
      end
    end


  end

  context "show" do

    setup do
      @publisher = Factory(:publisher, :label => "abc-publishing")
      @daily_deal = Factory(:daily_deal,
                            :publisher => @publisher,
                            :affiliate_url => "http://example.com?pub_label=%publisher_label%")
      @consumer = Factory(:consumer, :publisher => @publisher)
      @affiliate_redirect = @daily_deal.daily_deal_affiliate_redirects.create(:consumer => @consumer)
    end


    context "with an affiliate redirect" do
      should "redirect to the daily deal affiliate_url" do
        get :show, :id => @affiliate_redirect
        assert_template :show
      end
    end

  end

end
