module Travelsavers
  
  class UpdateUnresolvedTravelsaversBookingStatuses
  
    @queue = :update_travelsavers_bookings
  
    class << self

      def perform
        TravelsaversBooking.unresolved.not_flagged_for_manual_review.each do |booking|
          begin
            sync_with_travelsavers(booking)
          rescue Exception => e
            Exceptional.handle(e)
          ensure
            flag_for_manual_review_and_send_internal_notification!(booking) if booking.unresolved_for_over_24_hours?
          end
        end
      end

      private

      def sync_with_travelsavers(booking)
        booking.sync_with_travelsavers!
      end

      def flag_for_manual_review_and_send_internal_notification!(booking)
        booking.flag_for_manual_review_and_send_internal_notification!
      end

    end
  
  end
  
end
