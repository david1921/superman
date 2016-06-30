class OptimalPayment < DailyDealPayment  
  
  def void_or_full_refund!(admin)
    daily_deal_purchase.optimal_payment_void_or_full_refund!(admin)
  end

  def partial_refund!(admin, partial_refund_amount)
    daily_deal_purchase.optimal_partial_refund!(admin, partial_refund_amount)
  end

  def refundable?
    daily_deal_purchase.optimal_refundable?
  end

  def submit_for_settlement!
    # do nothing as settle is automatic
  end

end