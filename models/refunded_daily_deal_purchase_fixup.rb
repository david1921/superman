class RefundedDailyDealPurchaseFixup < DailyDealPurchaseFixup
  validates_presence_of :refund_txn_id
  validates_presence_of :refund_count
  validates_numericality_of :refund_count, :only_integer => true, :greater_than => 0
end
