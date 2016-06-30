require File.dirname(__FILE__) + "/../helpers_helper"
require File.dirname(__FILE__) + "/../../../../../app/models/travelsavers/booking_request_form"

class DailyDealPurchaseHelperTest < Test::Unit::TestCase

  def setup
    @helper = Object.new.extend(DailyDealPurchaseHelper)
  end

  context "#travelsavers_booking_request_transaction_data" do
    should "return the transaction data from a new BookingRequestForm for the passed daily deal purchase" do
      mock_purchase = mock("purchase")
      mock_booking_request_form = mock("booking request form", :transaction_data => "the transaction data")
      redirect_url = "the redirect url"
      @helper.expects(:ssl_rails_environment?).returns(true)
      @helper.expects(:handle_redirect_daily_deal_purchase_travelsavers_bookings_url).with(mock_purchase, :protocol => "https").returns(redirect_url)
      Travelsavers::BookingRequestForm.stubs(:new).with(mock_purchase, redirect_url).returns(mock_booking_request_form)

      assert_equal "the transaction data", @helper.travelsavers_booking_request_transaction_data(mock_purchase)
    end
  end
end
