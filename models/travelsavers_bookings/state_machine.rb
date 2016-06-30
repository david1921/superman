module TravelsaversBookings
  
  module StateMachine
    
    def self.included(base)
      base.state_machine :initial => :booking_nil_payment_nil do
        after_transition :booking_success_payment_success => :booking_canceled_payment_unknown,
          :do => :cancel_booking
        after_transition :booking_success_payment_fail => :booking_success_payment_success,
          :do => :capture_successful_payment_that_failed_initially_on_successful_booking
        after_transition :booking_success_payment_fail => :booking_canceled_payment_unknown,
          :do => :cancel_successful_booking_with_failed_payment
        after_transition [:booking_success_payment_pending, :booking_success_payment_unknown] => :booking_success_payment_success,
          :do => :capture_payment_for_successful_booking
        after_transition :booking_success_payment_pending => :booking_canceled_payment_unknown,
          :do => :cancel_successful_booking_with_pending_payment
        after_transition [:booking_pending_payment_pending, :booking_unknown_payment_unknown, :booking_nil_payment_nil] => :booking_success_payment_success,
          :do => :capture_successful_booking_and_successful_payment
        after_transition [:booking_success_payment_pending, :booking_pending_payment_pending, :booking_unknown_payment_unknown, :booking_nil_payment_nil] => :booking_success_payment_fail,
          :do => :capture_successful_booking_and_failed_payment
        after_transition :booking_pending_payment_pending => :booking_success_payment_pending,
          :do => :capture_successful_booking_with_payment_still_pending
        after_transition [:booking_pending_payment_pending, :booking_unknown_payment_unknown, :booking_nil_payment_nil] => :booking_fail_payment_fail,
          :do => :capture_failed_booking_and_failed_payment
        after_transition [:booking_unknown_payment_unknown, :booking_nil_payment_nil] => :booking_success_payment_pending,
          :do => :capture_successful_booking_and_pending_payment
        after_transition [:booking_unknown_payment_unknown, :booking_nil_payment_nil] => :booking_pending_payment_pending,
          :do => :capture_booking_pending_and_payment_pending
        after_transition :booking_unknown_payment_unknown => :booking_canceled_payment_unknown,
          :do => :cancel_booking_with_unknown_booking_and_payment_status
        after_transition :booking_nil_payment_nil => :booking_canceled_payment_unknown,
          :do => :cancel_booking_with_nil_booking_and_payment_status
        after_transition [:booking_nil_payment_nil, :booking_unknown_payment_unknown, :booking_pending_payment_pending] => :booking_success_payment_unknown,
          :do => :capture_successful_booking_and_unknown_payment

        event :booking_nil_and_payment_nil do
          transition [:booking_nil_payment_nil,
                      :booking_fail_payment_fail] => :booking_nil_payment_nil
        end
        
        event :booking_succeeded_and_payment_succeeded do
          transition [
            :booking_nil_payment_nil,
            :booking_success_payment_success,
            :booking_success_payment_fail,
            :booking_success_payment_pending,
            :booking_pending_payment_pending,
            :booking_unknown_payment_unknown,
            :booking_success_payment_unknown] => :booking_success_payment_success
          
        end
        
        event :booking_succeeded_and_payment_failed do
          transition [
            :booking_nil_payment_nil,
            :booking_success_payment_fail,
            :booking_success_payment_pending,
            :booking_pending_payment_pending,
            :booking_unknown_payment_unknown,
            :booking_success_payment_unknown] => :booking_success_payment_fail
        end
        
        event :booking_succeeded_and_payment_unknown do
          transition [
            :booking_unknown_payment_unknown,
            :booking_nil_payment_nil,
            :booking_pending_payment_pending] => :booking_success_payment_unknown
        end
        
        event :booking_unknown_and_payment_unknown do
          transition [
            :booking_nil_payment_nil,
            :booking_pending_payment_pending,
            :booking_unknown_payment_unknown] => :booking_unknown_payment_unknown
        end
        
        event :booking_canceled_and_payment_unknown do
          transition [
            :booking_nil_payment_nil,
            :booking_success_payment_success,
            :booking_success_payment_fail,
            :booking_success_payment_pending,
            :booking_unknown_payment_unknown,
            :booking_success_payment_unknown] => :booking_canceled_payment_unknown
        end
        
        event :booking_failed_and_payment_failed do
          transition [
            :booking_nil_payment_nil,
            :booking_pending_payment_pending,
            :booking_unknown_payment_unknown] => :booking_fail_payment_fail
        end
        
        event :booking_pending_and_payment_pending do
          transition [
            :booking_nil_payment_nil,
            :booking_pending_payment_pending,
            :booking_unknown_payment_unknown] => :booking_pending_payment_pending
        end
        
        event :booking_succeeded_and_payment_pending do
          transition [
            :booking_nil_payment_nil,
            :booking_success_payment_pending,
            :booking_pending_payment_pending,
            :booking_unknown_payment_unknown,
            :booking_success_payment_unknown] => :booking_success_payment_pending
        end
      end
      
      base.send :include, InstanceMethods
      base.extend ClassMethods
    end
    
    module ClassMethods
      
    end
    
    module InstanceMethods
      
      def transition_to(new_state)
        return if state.to_s == new_state.to_s

        begin
          case new_state
          when :booking_success_payment_success
            booking_succeeded_and_payment_succeeded!
          when :booking_success_payment_fail
            booking_succeeded_and_payment_failed!
          when :booking_unknown_payment_unknown
            booking_unknown_and_payment_unknown!
          when :booking_canceled_payment_unknown
            booking_canceled_and_payment_unknown!
          when :booking_fail_payment_fail
            booking_failed_and_payment_failed!
          when :booking_pending_payment_pending
            booking_pending_and_payment_pending!
          when :booking_success_payment_pending
            booking_succeeded_and_payment_pending!
          when :booking_nil_payment_nil
            booking_nil_and_payment_nil!
          when :booking_success_payment_unknown
            booking_succeeded_and_payment_unknown!
          else
            raise ::StateMachine::Error.new(self, "transition failure: no such state :#{new_state} (TravelsaversBooking ID: #{id})")
          end
        rescue ::StateMachine::InvalidTransition => e
          handle_invalid_transition!(e)
          raise e
        end
      end
      
      def state
        booking_status_s = booking_status.present? ? booking_status : "nil"
        payment_status_s = payment_status.present? ? payment_status : "nil"
        "booking_#{booking_status_s.downcase}_payment_#{payment_status_s.downcase}"
      end
    
      def state=(value)
        value = :booking_nil_payment_nil if value.nil?
        
        b_status = value.to_s.match(/booking_([^_]+)/)[1].downcase
        b_status = nil if b_status == "nil"
        p_status = value.to_s.match(/payment_([^_]+)/)[1].downcase
        p_status = nil if p_status == "nil"
        
        write_attribute(:booking_status, b_status)
        write_attribute(:payment_status, p_status)
      end
      
      def booking_status=(value)
        if new_record?
          write_attribute(:booking_status, value)
        else
          raise "can't assign booking_status directly on an existing record. use transition_to instead."
        end
      end
      
      def payment_status=(value)
        if new_record?
          write_attribute(:payment_status, value)
        else
          raise "can't assign payment_status directly on an existing record. use transition_to instead."
        end
      end

      def cancel_if_not_already_canceled!
        transition_to(:booking_canceled_payment_unknown) unless state == "booking_canceled_payment_unknown"
      end
    
      private
      
      def downcase_and_symbolize(value)
        value.try(:downcase).try(:to_sym)
      end
      
      def cancel_booking
      end
      
      def capture_successful_payment_that_failed_initially_on_successful_booking
        set_payment_status_and_executed_at!('captured')
      end
      
      def capture_successful_booking_and_successful_payment
        set_payment_status_and_executed_at!('captured')
      end
      
      def capture_successful_booking_and_failed_payment
        set_payment_status_and_executed_at!('authorized')
        notify_about_payment_failure!
      end
      
      def capture_successful_booking_with_payment_still_pending
        set_payment_status_and_executed_at!('authorized')
      end
      
      def capture_failed_booking_and_failed_payment
        if daily_deal_purchase.authorized?
          daily_deal_purchase.set_payment_status!('voided')
        else
          daily_deal_purchase.set_payment_status!('pending')
        end
        notify_about_booking_failure!
      end
      
      def cancel_successful_booking_with_failed_payment
        noop("Cancelled bookings are manually refunded.")
      end
      
      def cancel_successful_booking_with_pending_payment
        noop("Cancelled bookings are manually refunded.")
      end

      def capture_payment_for_successful_booking
        set_payment_status_and_executed_at!('captured')
      end
      
      def capture_successful_booking_and_pending_payment
        set_payment_status_and_executed_at!('authorized')
      end
      
      def capture_booking_pending_and_payment_pending
        daily_deal_purchase.set_payment_status!('pending')
      end
      
      def cancel_booking_with_unknown_booking_and_payment_status
        noop("Cancelled bookings are manually refunded.")
      end
        
      def cancel_booking_with_nil_booking_and_payment_status
        noop("Cancelled bookings are manually refunded.")
      end
      
      def capture_successful_booking_and_unknown_payment
        set_payment_status_and_executed_at!('authorized')
      end

      def set_payment_status_and_executed_at!(payment_status)
        daily_deal_purchase.set_payment_status!(payment_status)
        daily_deal_purchase.reload
        if daily_deal_purchase.executed_at.nil?
          daily_deal_purchase.executed_at = Time.zone.now
          daily_deal_purchase.save!
        end
      end
    end
    
  end
  
end
