require File.dirname(__FILE__) + "/../../models_helper"

class TravelsaversBookings::StatusesTest < Test::Unit::TestCase
  def setup
    @booking = Object.new.extend(TravelsaversBookings::Statuses)
  end

  context "#unresolved?" do
    should "return true if resolved" do
      [
          ["success", "success"],
          ["fail", "fail"]
      ].each do |payment_status, booking_status|
        @booking.stubs(:payment_status).returns(payment_status)
        @booking.stubs(:booking_status).returns(booking_status)
        assert @booking.resolved?
      end
    end

    should "return false if unresolved" do
      TravelsaversBookings::Statuses::UNRESOLVED_STATUSES.each do |status_hash|
        @booking.stubs(:payment_status).returns(status_hash[:payment_status])
        @booking.stubs(:booking_status).returns(status_hash[:booking_status])
        assert !@booking.resolved?
      end
    end
  end

  context "#resolved?" do
    should "return true if not unresolved?" do
      @booking.stubs(:unresolved?).returns(false)
      assert @booking.resolved?
    end

    should "return false if unresolved?" do
      @booking.stubs(:unresolved?).returns(true)
      assert !@booking.resolved?
    end
  end
  
  context "#success?" do
    should "return true if booking and payment were successful" do
      @booking.stubs(:payment_status).returns(TravelsaversBookings::Statuses::PaymentStatus::SUCCESS)
      @booking.stubs(:booking_status).returns(TravelsaversBookings::Statuses::BookingStatus::SUCCESS)
      assert @booking.success?
    end

    should "return false if booking and payment were not both successful" do
      @booking.stubs(:payment_status).returns(TravelsaversBookings::Statuses::PaymentStatus::SUCCESS)
      @booking.stubs(:booking_status).returns(TravelsaversBookings::Statuses::BookingStatus::FAIL)
      assert !@booking.success?
    end
  end

  context "#fail?" do
    should "return true if not success?" do
      @booking.stubs(:success?).returns(false)
      assert @booking.fail?
    end

    should "return false if success?" do
      @booking.stubs(:success?).returns(true)
      assert !@booking.fail?
    end
  end

end
