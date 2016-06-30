require File.dirname(__FILE__) + "/../../../test_helper"

class DailyDealsController::EditTest < ActionController::TestCase
  tests DailyDealsController
  include DailyDealHelper

  context "daily deal variations" do

    setup do
      @daily_deal = Factory(:daily_deal)
      @publisher  = @daily_deal.publisher
      login_as Factory(:admin)
    end

    context "with publisher that is NOT setup for daily deal variations" do

      setup do
        @publisher.update_attribute(:enable_daily_deal_variations, false)  
      end

      should "not display variations section" do      
        get :edit, :id => @daily_deal.to_param
        assert_select "div#variations_preview", :count => 0
      end

    end

    context "with publisher that IS setup for daily deal variations" do

      setup do
        @publisher.update_attribute(:enable_daily_deal_variations, true)
      end

      context "with no daily deal variations" do

        should "have no daily deal variations" do
          assert @daily_deal.daily_deal_variations.empty?
        end

        should "display variations section" do
          get :edit, :id => @daily_deal.to_param
          assert_select "div#variations_preview" do
            assert_select "a[href='#{new_daily_deal_daily_deal_variation_path(@daily_deal)}']"
          end
        end

      end

      context "with daily deal variations" do

        setup do
          @variation = Factory(:daily_deal_variation, :daily_deal => @daily_deal )
          @daily_deal.reload
        end

        should "have daily deal variations" do
          get :edit, :id => @daily_deal.to_param
          assert assigns(:daily_deal_variations).any?
        end

        should "display variations section" do
          get :edit, :id => @daily_deal.to_param
          assert_select "div#variations_preview" do
            assert_select "a[href='#{new_daily_deal_daily_deal_variation_path(@daily_deal)}']"
          end
        end
      end

      context "with deleted daily deal variations" do
        setup do
          @variation = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :deleted_at => 2.days.ago)
          @daily_deal.reload
        end

        should "not have daily deal variations" do
          get :edit, :id => @daily_deal.to_param
          assert !assigns(:daily_deal_variations).any?
        end
      end

    end
  end

end
