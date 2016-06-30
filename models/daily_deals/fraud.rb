module DailyDeals
  module Fraud
    def self.included(base)
      base.send :include, InstanceMethods
    end
    
    module InstanceMethods
      def regenerate_suspected_frauds(threshold = 0.6, capacity = 500)
        SuspectedFraud.for_deal(self).destroy_all
      
        bi_gram_scoring = BiGramScoring.new(capacity)
        with_daily_deal_purchases_for_fraud_review(capacity) do |ddp|
          score, matching_key, matching_arg = bi_gram_scoring.add_entry(ddp.fraud_key, ddp.fraud_signature, ddp.id)
          if id == ddp.daily_deal_id && threshold <= score
            SuspectedFraud.create!(:score => score, :suspect_daily_deal_purchase_id => ddp.id, :matched_daily_deal_purchase_id => matching_arg)
          end
        end
      end
    end
    
    private
    
    def with_daily_deal_purchases_for_fraud_review(capacity, &block)
      #
      # Feed a list of daily-deal purchases into the similarity-detection pipe, in ascending ID order.
      #
      # We need this to ensure that each purchase is compared only to earlier purchases, so there are
      # no loops in the suspect-purchase -> matching-purchase graph.  That is, there will always be a
      # first purchase that's not rejected as fraudulent.
      #
      # First, send in some purchases prior to the first purchase for this deal, to prime the bi-gram
      # scoring weights.
      #
      find_options = { :conditions => { :payment_status => "captured" }, :order => "daily_deal_purchases.id ASC" }
      first_captured_purchase = daily_deal_purchases.first(find_options)
      with_captured_purchases_for_publisher_before(first_captured_purchase.id, capacity - 1, &block)
      #
      # Once the weights are primed, send in the captured purchases for this deal.
      #
      with_captured_purchases &block
    end
    
    def with_captured_purchases_for_publisher_before(end_id, limit, &block)
      find_options = {
        :conditions => ["daily_deal_purchases.payment_status = 'captured' AND daily_deal_purchases.id < :id", { :id => end_id }],
        :order => "daily_deal_purchases.id DESC",
        :limit => limit,
        :include => [:consumer, :daily_deal_payment]
      }
      publisher.daily_deal_purchases.all(find_options).reverse.each { |ddp| block.call(ddp) }
    end
    
    def with_captured_purchases(&block)
      find_options = {
        :conditions => "daily_deal_purchases.payment_status = 'captured'",
        :include => [:consumer, :daily_deal_payment]
      }
      #
      # Note: find_each returns instances in ascending ID order.
      #
      daily_deal_purchases.find_each(find_options, &block)
    end
  end
end
