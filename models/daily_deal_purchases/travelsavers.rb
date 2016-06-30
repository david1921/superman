module DailyDealPurchases

  module Travelsavers
    
    def self.included(base)
      base.delegate :confirmation_number, :to => :travelsavers_booking, :allow_nil => true
    end

    def ts_booking_status
      travelsavers_booking.try(:booking_status)
    end

    def ts_payment_status
      travelsavers_booking.try(:payment_status)
    end

  end
  
end
