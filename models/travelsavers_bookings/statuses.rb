module TravelsaversBookings
  
  module Statuses
    
    module BookingStatus

      VALID_STATUSES = [
        PENDING = "pending",
        SUCCESS = "success",
        FAIL = "fail",
        CANCELED = "canceled",
        UNKNOWN = "unknown"
      ]

    end

    module PaymentStatus

      VALID_STATUSES = [
        PENDING = "pending",
        SUCCESS = "success",
        FAIL = "fail",
        UNKNOWN = "unknown"
      ]

    end

    UNRESOLVED_STATUSES = [
      { :booking_status => BookingStatus::SUCCESS, :payment_status => PaymentStatus::FAIL },
      { :booking_status => BookingStatus::SUCCESS, :payment_status => PaymentStatus::PENDING },
      { :booking_status => BookingStatus::SUCCESS, :payment_status => PaymentStatus::UNKNOWN },
      { :booking_status => BookingStatus::PENDING, :payment_status => PaymentStatus::PENDING },
      { :booking_status => BookingStatus::UNKNOWN, :payment_status => PaymentStatus::UNKNOWN },
      { :booking_status => nil, :payment_status => nil },
    ]

    def unresolved?
      UNRESOLVED_STATUSES.include?({ :booking_status => booking_status, :payment_status => payment_status })
    end

    def resolved?
      !unresolved?
    end

    def unresolved_for_over_24_hours?
      unresolved? && created_at.present? && created_at < 24.hours.ago
    end

    def success?
      booking_succeeded? && payment_succeeded?
    end

    def fail?
      !success?
    end

    def booking_succeeded?
      booking_status == BookingStatus::SUCCESS
    end

    def payment_succeeded?
      payment_status == PaymentStatus::SUCCESS
    end

  end
  
end
