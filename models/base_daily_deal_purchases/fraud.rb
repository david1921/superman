module BaseDailyDealPurchases
  module Fraud
    def self.included(base)
      base.named_scope :for_fraud_check, {
        :conditions => "daily_deal_purchases.payment_status = 'captured'", :include => [:consumer, :daily_deal_payment]
      }
      base.named_scope :before_fraud_check_increment, lambda { |last_timestamp|
        { :conditions => ["daily_deal_purchases.created_at < ?", last_timestamp] }
      }
      base.named_scope :within_fraud_check_increment, lambda { |last_timestamp, this_timestamp|
        { :conditions => ["daily_deal_purchases.created_at >= ? AND daily_deal_purchases.created_at < ?", last_timestamp, this_timestamp] }
      }
      base.named_scope :grouped_by_fraud_key, {
        :conditions => "daily_deal_purchases.payment_status = 'captured'",
        :group => "daily_deal_purchases.consumer_id"
      }
      base.named_scope :in_fraud_check_order, { :order => "daily_deal_purchases.id ASC" }
      
      base.send :include, InstanceMethods
    end
    
    module InstanceMethods
      def fraud_key
        consumer_id.to_s
      end
      
      def fraud_signature
        elements = [
          consumer.name,
          consumer.email,
          consumer.created_at.to_s(:iso8601),
          ip_address.if_present,
          daily_deal_payment.try(:credit_card_last_4).if_present
        ].compact
        "$" + elements.join('$').split(' ').join('$').downcase + "$"
      end
    end
  end
end
