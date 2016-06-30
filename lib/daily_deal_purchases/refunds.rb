module DailyDealPurchases
  
  module Refunds
    
    class << self
      def update_refund_amounts!
        refunded_txs = ::DailyDealPurchase.refunded(nil).find(:all, :conditions => "refund_amount IS NULL AND paypal_txn_id IS NULL")
        verbose("found #{refunded_txs.count} refund transactions with no refund_amount set")
        
        errors_raised = 0
        refunded_txs.each do |refunded_tx|
          begin
            bt_refund_tx = refunded_tx.find_payment_status_update_transaction!
            refund_amount = bt_refund_tx.amount
            verbose("updating DailyDealPurchase (#{refunded_tx.id}) with refund amount #{refund_amount}...", :newline => false)
          
            if dry_run?
              verbose("(** dry run - not updating **)")
            else
              refunded_tx.refund_amount = refund_amount
              refunded_tx.save!
              verbose("updated successfully")
            end
          rescue Exception => e
            puts "ERROR (DailyDealPurchase: #{refunded_tx.id}): #{e.message}"
            errors_raised += 1
            
            if errors_raised >= 10
              error_msg = "too many errors occurred while processing these refunds (#{errors_raised} errors). aborting!"
              puts "*" * error_msg.length
              puts error_msg
              puts "*" * error_msg.length
              exit!
            end            
          end
        end
      end
      
      def restore_braintree_transaction_amounts!
        refunded_txs = ::DailyDealPurchase.refunded(nil).find(:all, :conditions => "braintree_transaction_amount = 0 AND paypal_txn_id IS NULL")
        verbose("found #{refunded_txs.count} refund transactions with braintree_transaction_amount == 0")
        
        errors_raised = 0
        refunded_txs.each do |refunded_tx|
          begin
            bt_tx = refunded_tx.find_braintree_transaction!
            braintree_transaction_amount = bt_tx.amount
            verbose("updating DailyDealPurchase (#{refunded_tx.id}) with bt tx amount #{braintree_transaction_amount}...", :newline => false)
          
            if dry_run?
              verbose("(** dry run - not updating **)")
            else
              refunded_tx.braintree_transaction_amount = braintree_transaction_amount
              refunded_tx.save!
              verbose("updated successfully")
            end
          rescue Exception => e
            puts "ERROR (DailyDealPurchase: #{refunded_tx.id}): #{e.message}"
            errors_raised += 1
            
            if errors_raised >= 10
              error_msg = "too many errors occurred while processing these refunds (#{errors_raised} errors). aborting!"
              puts "*" * error_msg.length
              puts error_msg
              puts "*" * error_msg.length
              exit!
            end            
          end
        end
      end
      
      def dry_run?
        @dry_run ||= ENV["DRY_RUN"].present?
      end
      
      def verbose(msg, options = {})
        options[:newline] = options[:newline].nil? ? true : options[:newline]

        print msg if verbose?
        print "\n" if options[:newline]
      end
      
      def verbose?
        @verbose ||= ENV["VERBOSE"].present?
      end
    end

  end
  
end