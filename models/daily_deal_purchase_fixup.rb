class DailyDealPurchaseFixup < ActiveRecord::Base

  validates_presence_of :daily_deal_purchase_id
  validates_uniqueness_of :daily_deal_purchase_id
  validates_numericality_of :new_gross_price, :greater_than => 0, :allow_nil => true
  
  def self.daily_deal_purchases_needing_fixup(start, count)
    DailyDealPurchase.find_by_sql(%Q{
      SELECT ddps.*
      , IF(ISNULL(ddps.discount_id), NULL, IFNULL(discounts.code, "X")) AS current_discount_code
      , IF(ISNULL(ddps.discount_id), NULL, IFNULL(discounts.amount, "X")) AS current_discount_value
      , (ddps.actual_purchase_price + ddps.credit_used + IFNULL(discounts.amount, 0.0)) AS calculated_gross_price
      , daily_deal_purchase_fixups.type AS fixup_type
      , daily_deal_purchase_fixups.new_gross_price AS new_gross_price
      , daily_deal_purchase_fixups.refund_txn_id AS refund_txn_id
      , daily_deal_purchase_fixups.refund_count AS refund_count
      FROM daily_deal_purchases AS ddps LEFT JOIN discounts ON ddps.discount_id = discounts.id LEFT JOIN daily_deal_purchase_fixups ON ddps.id = daily_deal_purchase_fixups.daily_deal_purchase_id
      WHERE (ddps.actual_purchase_price + ddps.credit_used + IFNULL(discounts.amount, 0.0)) <> ddps.gross_price AND ddps.actual_purchase_price <> 0 AND executed_at IS NOT NULL
      ORDER BY ddps.daily_deal_id DESC, ddps.executed_at DESC
      LIMIT #{count} OFFSET #{start}
    })
  end

  def self.daily_deal_purchases_needing_fixup_count
    DailyDealPurchase.count_by_sql(%Q{
      SELECT COUNT(*)
      FROM daily_deal_purchases AS ddps LEFT JOIN discounts ON ddps.discount_id = discounts.id
      WHERE (ddps.actual_purchase_price + ddps.credit_used + IFNULL(discounts.amount, 0.0)) <> ddps.gross_price AND ddps.actual_purchase_price <> 0 AND executed_at IS NOT NULL
    })
  end
end
