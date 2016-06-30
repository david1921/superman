# THE RULES:
#
# 1) start_at and price will lock if it has at least one deal sold 
# or has at least on syndicated deal.
# 
# 2) hide_at will lock if the hide_at date was at least 24 hours ago.
#
module DailyDeals
  module Locks

    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      
      def ensure_locks
        ensure_hide_at_lock
        ensure_price_lock
      end
      
      private
      
      def ensure_start_at_lock
        if start_at_changed?
          errors.add(:start_at, "%{attribute} can not be changed, because at least one deal has been sold.") if number_sold > 0
        end
      end
      
      def ensure_hide_at_lock
        if hide_at_changed?
          if hide_at_lockable?
            errors.add(:hide_at, "%{attribute} can not be changed, because at least one deal has been sold and the deal has already ended.") if number_sold > 0
          end
        end        
      end
      
      def ensure_price_lock
        if price_changed?
          errors.add(:price, "%{attribute} can not be changed, because at least one deal has been sold.") if number_sold > 0
          errors.add(:price, "%{attribute} can not be changed, because deal has been syndicated.") if source?
        end
      end

      def has_ended_over_24_hours_ago?
        ended_at = hide_at_was.present? ? hide_at_was : hide_at
        ended_at.present? && ((ended_at + 24.hours) <= Time.zone.now)
      end            
          
      
      def hide_at_lockable?
        return false if new_record?
        return false unless publisher && publisher.uses_paychex?
        has_ended_over_24_hours_ago?
      end
            
    end

  end  
end
