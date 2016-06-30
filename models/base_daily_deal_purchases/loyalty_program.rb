module BaseDailyDealPurchases
  
  module LoyaltyProgram
    
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.extend(ClassMethods)
    end

    module ClassMethods
      
      def eligible_for_loyalty_program_credit(publisher = nil)
        publisher_filter = publisher.present? ? (" AND dd.publisher_id = %d" % publisher.id) : ""

        loyalty_referral_counts = connection.execute(%Q{
          SELECT ddp.daily_deal_id, ddp.loyalty_program_referral_code, ddp.daily_deal_variation_id, dd.referrals_required_for_loyalty_credit, COUNT(DISTINCT(CONCAT(ddp.consumer_id, ddp.loyalty_program_referral_code, IFNULL(ddp.daily_deal_variation_id, '')))) AS num_referrals
          FROM daily_deal_purchases ddp
            INNER JOIN daily_deals dd ON ddp.daily_deal_id = dd.id
          WHERE ddp.payment_status = 'captured'
            AND dd.enable_loyalty_program IS TRUE
            #{publisher_filter}
          GROUP BY ddp.daily_deal_id, ddp.loyalty_program_referral_code, ddp.daily_deal_variation_id, dd.referrals_required_for_loyalty_credit
          HAVING COUNT(DISTINCT(CONCAT(ddp.consumer_id, ddp.loyalty_program_referral_code, IFNULL(ddp.daily_deal_variation_id, '')))) >= dd.referrals_required_for_loyalty_credit
        })

        deals_with_loyalty_referrals = []
        loyalty_referral_counts.all_hashes.each do |lrc|
          max_eligible_purchases_for_this_referrer_on_this_deal = lrc["num_referrals"].to_i / lrc["referrals_required_for_loyalty_credit"].to_i
          eligible_purchases = DailyDealPurchase.find(
            :all,
            :conditions => [%Q{
              users.referrer_code = ? AND
              daily_deal_id = ? AND
              daily_deal_purchases.payment_status = 'captured' AND
              (daily_deal_purchases.loyalty_refund_amount = 0 OR
               daily_deal_purchases.loyalty_refund_amount IS NULL)
            }, lrc["loyalty_program_referral_code"], lrc["daily_deal_id"]],
            :include => { :daily_deal => :publisher }, 
            :joins => "INNER JOIN users ON daily_deal_purchases.consumer_id = users.id",
            :limit => max_eligible_purchases_for_this_referrer_on_this_deal)
          deals_with_loyalty_referrals += eligible_purchases.to_a if eligible_purchases.present?
        end

        deals_with_loyalty_referrals.sort_by(&:id)
      end
      
      def with_loyalty_program_referrals(dates, publisher)
        publisher_filter = publisher.present? ? (" AND dd.publisher_id = %d" % publisher.id) : ""
        date_filter = if dates.present?
          " daily_deal_purchases.executed_at BETWEEN '%s' AND '%s' AND " % [
              Time.zone.parse(dates.begin.to_s).beginning_of_day.utc.to_formatted_s(:db),
              Time.zone.parse(dates.end.to_s).end_of_day.utc.to_formatted_s(:db)]
        else
          ""
        end
        
        loyalty_referral_counts = connection.execute(%Q{
          SELECT ddp.daily_deal_id, ddp.loyalty_program_referral_code, dd.referrals_required_for_loyalty_credit, ddp.daily_deal_variation_id, COUNT(DISTINCT(CONCAT(ddp.consumer_id, ddp.loyalty_program_referral_code, IFNULL(ddp.daily_deal_variation_id, '')))) AS num_referrals
          FROM daily_deal_purchases ddp
            INNER JOIN daily_deals dd ON ddp.daily_deal_id = dd.id
          WHERE ddp.payment_status = 'captured'
            AND dd.enable_loyalty_program IS TRUE
            #{publisher_filter}
          GROUP BY ddp.daily_deal_id, ddp.loyalty_program_referral_code, dd.referrals_required_for_loyalty_credit
        })

        deals_with_loyalty_referrals = loyalty_referral_counts.all_hashes.map do |lrc|
          DailyDealPurchase.find(
            :first,
            :select => %Q{daily_deal_purchases.id, daily_deal_purchases.quantity,
                          daily_deal_purchases.executed_at, users.email AS purchaser_name,
                          daily_deal_translations.value_proposition AS deal_value_proposition,
                          daily_deal_purchases.payment_status, daily_deal_purchases.refunded_at,
                          #{lrc["num_referrals"]} AS loyalty_referrals_count}, 
            :conditions => [%Q{
              #{date_filter}
              users.referrer_code = ? AND
              daily_deal_purchases.daily_deal_id = ? AND
              ((daily_deal_purchases.payment_status = 'captured') OR
               (daily_deal_purchases.payment_status = 'refunded' AND
                daily_deal_purchases.loyalty_refund_amount IS NOT NULL AND
                daily_deal_purchases.loyalty_refund_amount > 0))
            }, lrc["loyalty_program_referral_code"], lrc["daily_deal_id"]],
            :joins => %Q{INNER JOIN users ON daily_deal_purchases.consumer_id = users.id
                         INNER JOIN daily_deals on daily_deal_purchases.daily_deal_id = daily_deals.id
                         INNER JOIN daily_deal_translations ON daily_deal_translations.daily_deal_id = daily_deals.id
                         INNER JOIN publishers ON daily_deals.publisher_id = publishers.id},
            :order => "daily_deal_purchases.executed_at DESC")
        end.compact
        
        deals_with_loyalty_referrals.sort { |a, b| b.executed_at <=> a.executed_at }
      end
      
    end
    
    module InstanceMethods
      
      def received_loyalty_refund?
        loyalty_refund_amount.present?
      end
      
      def eligible_for_loyalty_refund?
        eligible_purchases_for_my_publisher = self.class.eligible_for_loyalty_program_credit(publisher)
        eligible_purchases_for_my_publisher.any? { |ddp| ddp.id == id }
      end
      
      def loyalty_refund!(user_that_executed_refund)
        ensure_eligible_for_loyalty_refund!
      
        BaseDailyDealPurchase.transaction do
          with_after_refunded_callback_disabled do
            daily_deal_payment.partial_refund!(user_that_executed_refund, amount_to_refund_for_loyalty_program)
          end
          reload_to_avoid_stale_object_error
          self.loyalty_refund_amount = amount_to_refund_for_loyalty_program
          save!
        end
      end
      
      def amount_to_refund_for_loyalty_program
        price
      end
    
      def with_after_refunded_callback_disabled
        after_refunded_method = method(:after_refunded)
        eigenclass = class << self; self; end
      
        eigenclass.class_eval { define_method(:after_refunded) { } }

        yield
      ensure
        if defined?(after_refunded_method)
          eigenclass.class_eval { define_method(:after_refunded) { after_refunded_method.call } }
        end
      end
      
      private
      
      def ensure_eligible_for_loyalty_refund!
        unless captured?
          raise ::LoyaltyProgram::NotEligibleForRefundError,
                "purchase must be in state 'captured' to apply loyalty refund, but " +
                "is in state '#{payment_status}'"
        end
      
        unless daily_deal.enable_loyalty_program?
          raise ::LoyaltyProgram::NotEligibleForRefundError,
                "cannot apply loyalty refund to this purchase. the loyalty program " +
                "is disabled for this deal"
        end
      
        unless actual_purchase_price >= price
          raise ::LoyaltyProgram::NotEligibleForRefundError,
                "actual purchase price must be >= deal price in order to apply a " +
                "loyalty refund to this purchase"
        end
        
        unless eligible_for_loyalty_refund?
          raise ::LoyaltyProgram::NotEligibleForRefundError, "this purchase is not eligible for a loyalty refund"
        end
      end
      
      def reload_to_avoid_stale_object_error
        reload
      end
  
    end
    
  end
  
end
