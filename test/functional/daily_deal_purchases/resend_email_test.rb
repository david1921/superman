require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::ResendEmailTest < ActionController::TestCase
  tests DailyDealPurchasesController

  def setup
    @booking = Factory :successful_travelsavers_booking
    @captured_purchase = @booking.daily_deal_purchase
    @uncaptured_purchase = Factory :pending_daily_deal_purchase
    ActionMailer::Base.deliveries = []
  end

  context "POST to :resend_email" do
    
    should "allow ssl" do
      assert DailyDealPurchasesController.ssl_allowed.include?(:resend_email)
    end

    should "be routable" do
      assert_recognizes(
        { :controller => "daily_deal_purchases", :action => "resend_email", :id => @captured_purchase.to_param },
        { :path => "daily_deal_purchases/#{@captured_purchase.to_param}/resend_email", :method => :post })
    end

    should "raise an exception when called on an uncaptured purchase and not send any email" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        e = assert_raises(ArgumentError) do
          post :resend_email, :id => @uncaptured_purchase.to_param
        end
        assert_equal "can't resend confirmation email for DailyDealPurchase #{@uncaptured_purchase.uuid} because " +
                     "its status must be 'captured', but is 'pending'", e.message
      end
    end

    should "send an email when called on a captured purchase and redirect back to the daily deal purchase index" do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        post :resend_email, :id => @captured_purchase.to_param
      end
      assert_redirected_to publisher_consumer_daily_deal_purchases_url(
        :publisher_id => @captured_purchase.publisher.to_param, :consumer_id => @captured_purchase.consumer.to_param)
      assert_equal "Confirmation email successfully resent", flash[:notice]
    end

  end

end


