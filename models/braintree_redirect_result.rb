class BraintreeRedirectResult < ActiveRecord::Base
  belongs_to :daily_deal_order
  belongs_to :daily_deal_purchase
  
  def self.latest_for_distinct_consumers(consumers_count=20)
    sql = <<-EOF
     SELECT daily_deal_purchases.consumer_id AS consumer_id,
            MAX(braintree_redirect_results.id) AS braintree_redirect_result_id
     FROM braintree_redirect_results
       INNER JOIN daily_deal_purchases ON braintree_redirect_results.daily_deal_purchase_id = daily_deal_purchases.id
     GROUP BY consumer_id
     ORDER BY braintree_redirect_result_id DESC
     LIMIT :consumers_count
    EOF
    find(find_by_sql([sql, { :consumers_count => consumers_count }]).map(&:braintree_redirect_result_id),
         :include => { :daily_deal_purchase => [{ :daily_deal => :publisher }, :consumer] })
  end
end
