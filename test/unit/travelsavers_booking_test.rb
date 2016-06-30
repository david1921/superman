require File.dirname(__FILE__) + "/../test_helper"

class TravelsaversBookingTest < ActiveSupport::TestCase

  setup do
    FakeWeb.allow_net_connect = false
  end

  should "be versioned" do
    assert TravelsaversBooking.versioned?
  end

  should "belong_to :daily_deal_purchase" do
    purchase = Factory(:daily_deal_purchase)
    booking = Factory(:travelsavers_booking, :daily_deal_purchase => purchase)
    assert_equal purchase, booking.daily_deal_purchase
  end

  should "validate presence of a purchase" do
    booking = Factory.build(:travelsavers_booking, :daily_deal_purchase => nil)
    assert !booking.valid?
    assert_match /blank/, booking.errors[:daily_deal_purchase]
  end

  should "validate presence of a book_transaction_id" do
    booking = Factory.build(:travelsavers_booking, :book_transaction_id => nil)
    assert !booking.valid?
    assert_match /blank/, booking.errors[:book_transaction_id]
  end

  should "validate uniqueness of daily_deal_purchase_id (i.e. not allow more than one booking per purchase)" do
    booking = Factory(:travelsavers_booking)
    booking2 = Factory.build(:travelsavers_booking, :daily_deal_purchase => booking.daily_deal_purchase)
    assert !booking2.valid?
    assert_match /has already been taken/, booking2.errors[:daily_deal_purchase_id]
  end

  context "delegate" do
    setup do
      @booking = Factory.build(:travelsavers_booking)
      @mock_book_transaction = mock("book_transaction")
      @booking.stubs(:book_transaction).returns(@mock_book_transaction)
    end

    should "#has_errors_that_cant_be_ignored? to book_transaction" do
      @mock_book_transaction.stubs(:has_errors_that_cant_be_ignored?).returns(true)
      assert @booking.has_errors_that_cant_be_ignored?
    end

    should "#fixable_errors to book_transaction" do
      mock_errors = mock("errors")
      @mock_book_transaction.stubs(:fixable_errors).returns(mock_errors)
      assert_equal mock_errors, @booking.fixable_errors
    end

    should "#unfixable_errors to book_transaction" do
      mock_errors = mock("errors")
      @mock_book_transaction.stubs(:unfixable_errors).returns(mock_errors)
      assert_equal mock_errors, @booking.unfixable_errors
    end

    should "#checkout_form_values to book_transaction" do
      form_values = mock("form values")
      @mock_book_transaction.stubs(:checkout_form_values).returns(form_values)
      assert_equal form_values, @booking.checkout_form_values
    end
  end

  context ".unresolved" do
    
    should "be blank when there are no TravelsaversBookings" do
      assert TravelsaversBooking.all.blank?
      assert TravelsaversBooking.unresolved.blank?
    end
    
    should "return only TravelsaversBooking that need to be polled for status changes" do
      b_success_p_success = Factory :travelsavers_booking, :booking_status => "success", :payment_status => "success"
      b_success_p_fail = Factory :travelsavers_booking, :booking_status => "success", :payment_status => "fail"
      b_fail_p_fail = Factory :travelsavers_booking, :booking_status => "fail", :payment_status => "fail"
      b_success_p_pending = Factory :travelsavers_booking, :booking_status => "success", :payment_status => "pending"
      b_pending_p_pending = Factory :travelsavers_booking, :booking_status => "pending", :payment_status => "pending"
      b_canceled_p_unknown = Factory :travelsavers_booking, :booking_status => "canceled", :payment_status => "unknown"
      b_unknown_p_unknown = Factory :travelsavers_booking, :booking_status => "unknown", :payment_status => "unknown"
      
      assert_same_elements [b_success_p_fail, b_success_p_pending, b_pending_p_pending, b_unknown_p_unknown],
                           TravelsaversBooking.unresolved
    end
    
  end

  context ".not_flagged_for_manual_review" do
    
    should "return only bookings that don't need manual review" do
      b1 = Factory :successful_travelsavers_booking_with_failed_payment
      b2 = Factory :pending_travelsavers_booking
      b3 = Factory :pending_travelsavers_booking, :needs_manual_review => true
      b4 = Factory :travelsavers_booking_with_unknown_errors, :needs_manual_review => true

      assert_same_elements [b1, b2], TravelsaversBooking.not_flagged_for_manual_review
    end

  end

  context "#unresolved_for_over_24_hours?" do
    
    should "return false on a booking that is resolved and less than 24 hours old" do
      booking = Factory :successful_travelsavers_booking
      assert booking.resolved?
      assert !booking.unresolved_for_over_24_hours?
    end

    should "return false on a booking that is resolved and more than 24 hours old" do
      booking = Factory :successful_travelsavers_booking
      Timecop.freeze(booking.created_at + 24.hours + 1.second) do
        assert booking.resolved?
        assert !booking.unresolved_for_over_24_hours?
      end
    end

    should "return false on a booking that is unresolved and less than 24 hours old" do
      booking = Factory :pending_travelsavers_booking
      assert booking.unresolved?
      assert !booking.unresolved_for_over_24_hours?
    end

    should "return true on a booking that is unresolved and more than 24 hours old" do
      booking = Factory :pending_travelsavers_booking
      Timecop.freeze(booking.created_at + 24.hours + 1.second) do
        assert booking.unresolved?
        assert booking.unresolved_for_over_24_hours?
      end
    end

  end
  
end
