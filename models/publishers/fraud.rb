module Publishers
  module Fraud
    def self.included(base)
      base.send :include, InstanceMethods
    end
    
    module InstanceMethods
      def generate_suspected_frauds(threshold = 0.6, capacity = 500)
        Job.run! suspected_frauds_job_key, :incremental => true do |last_increment_timestamp, this_increment_timestamp, job|
          generate_suspected_frauds_for_increment(last_increment_timestamp, this_increment_timestamp, threshold, capacity, job)
        end
      end
      
      def generate_suspected_frauds_for_increment(last_timestamp, this_timestamp, threshold = 0.6, capacity = 500, job = nil)
        last_timestamp ||= Time.zone.now - 72.hours
        #
        # Feed a list of daily-deal purchases into the similarity-detection pipe, in ascending ID order.
        #
        # We need an ordering to ensure that each purchase is compared only to earlier purchases so there
        # are no loops in the suspect-purchase -> matched-purchase graph. That is, there will always be a
        # first purchase that's not flagged as fraudulent.
        #
        bi_gram_scoring = BiGramScoring.new(capacity)
        #
        # First send in purchases prior to the first purchase for this increment, to prime the pipeline.
        #
        with_daily_deal_purchases_before_increment(last_timestamp, capacity) do |ddp|
          bi_gram_scoring.add_entry(ddp.fraud_key, ddp.fraud_signature, ddp.id)
        end
        #
        # Now send in the purchases for this increment, to be checked for fraud.
        #
        with_daily_deal_purchases_within_increment(last_timestamp, this_timestamp) do |ddp|
          score, matching_key, matching_arg = bi_gram_scoring.add_entry(ddp.fraud_key, ddp.fraud_signature, ddp.id)
          if threshold <= score
            SuspectedFraud.create!(
              :job => job,
              :score => score,
              :suspect_daily_deal_purchase_id => ddp.id,
              :matched_daily_deal_purchase_id => matching_arg
            )
          end
        end
      end
      
      def with_suspected_frauds_from_last_job(&block)
        if (last_job = Job.with_key(suspected_frauds_job_key).processed.latest_incremental_run.first)
          include = {
            :suspect_daily_deal_purchase => [:consumer, :daily_deal_payment],
            :matched_daily_deal_purchase => [:consumer, :daily_deal_payment]
          }
          SuspectedFraud.from_job(last_job).all(:include => include, :order => "suspected_frauds.score DESC").each(&block)
        end
      end
      
      private
      
      def suspected_frauds_job_key
        @job_key ||= "#{self.class.name.underscore}:#{label}:generate_suspected_frauds"
      end
      
      def with_daily_deal_purchases_before_increment(last_timestamp, limit, &block)
        records = daily_deal_purchases.before_fraud_check_increment(last_timestamp).grouped_by_fraud_key.all(
          :select => "MAX(daily_deal_purchases.id) AS max_purchase_id",
          :order => "max_purchase_id DESC",
          :limit => limit
        )
        DailyDealPurchase.for_fraud_check.in_fraud_check_order.all(:conditions => { :id => records.map(&:max_purchase_id) }).each(&block)
      end
      
      def with_daily_deal_purchases_within_increment(last_timestamp, this_timestamp, &block)
        #
        # Note: find_each returns instances in ascending ID order.
        #
        daily_deal_purchases.for_fraud_check.within_fraud_check_increment(last_timestamp, this_timestamp).find_each(&block)
      end
    end
  end
end
