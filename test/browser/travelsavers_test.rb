require File.dirname(__FILE__) + "/browser_test"
require File.dirname(__FILE__) + "/../helpers/travelsavers_test_helper"
require 'timecop'

class TravelsaversTest < BrowserTest
  include TravelsaversTestHelper

  def setup
    @port = 8080
    Capybara.server_port = @port
    Capybara.current_driver = Capybara.javascript_driver
    Factory(:country, :code => 'US') # publishers use US by default
    @ts_transaction_id = "XXX-12345"
  end

  test "show 'processing' page and then 'thank you' page for successful purchase" do
    @purchase = Factory(:travelsavers_daily_deal_purchase)
    set_ts_booking_as_pending!
    ts_redirect_browser_to_processing_page!
    let_browser_poll_for_few_seconds
    set_ts_booking_as_successful!
    wait_until_thank_you_page
  end

  test "show pre-populated 'confirm' page when purchase attempt had user-correctable errors " do
    @purchase = Factory(:travelsavers_daily_deal_purchase)
    set_ts_booking_as_failed_with_validation_errors!
    ts_redirect_browser_to_processing_page!
    wait_until_confirm_page
    assert_form_is_prepopulated
  end

  test "show 'processing' page and then 'thank you' page after successful purchase that previously failed" do
    failed_booking = Factory(:travelsavers_booking_with_validation_errors, :book_transaction_id => @ts_transaction_id)
    @purchase = failed_booking.daily_deal_purchase

    more_than_30_seconds_after_initial_purchase_attempt do
      set_ts_booking_as_pending!
      ts_redirect_browser_to_processing_page!
      let_browser_poll_for_few_seconds
      set_ts_booking_as_successful!
      wait_until_thank_you_page
    end
  end


  private

  def more_than_30_seconds_after_initial_purchase_attempt
    Timecop.travel(31.seconds.from_now) do
      yield
    end
  end

  def let_browser_poll_for_few_seconds
    sleep 3
  end

  def set_ts_booking_as_successful!
    stub_ts_success_response(travelsavers_booking_url(@ts_transaction_id))
  end

  def set_ts_booking_as_pending!
    stub_ts_pending_response(travelsavers_booking_url(@ts_transaction_id))
  end

  def ts_redirect_browser_to_processing_page!
    processing_url = "http://localhost:#{@port}/daily_deal_purchases/#{@purchase.to_param}/travelsavers_bookings/handle_redirect?ts_transaction_id=#{@ts_transaction_id}"
    visit processing_url
    assert_equal processing_url, current_url
  end

  def set_ts_booking_as_failed_with_validation_errors!
    stub_ts_validation_errors_response(travelsavers_booking_url(@ts_transaction_id))
  end

  def wait_until_thank_you_page
    thank_you_path = "/daily_deal_purchases/#{@purchase.to_param}/thank_you"
    wait_until { thank_you_path == current_path }
  end

  def wait_until_confirm_page
    confirm_path = "/daily_deal_purchases/#{@purchase.to_param}/confirm"
    wait_until { current_path == confirm_path }
  end

  def assert_form_is_prepopulated
    assert page.find_field("Address 1:").value.present?
  end

end
