class NonVoucherDailyDealPurchase < DailyDealPurchase

  def non_voucher_purchase?
    true
  end

  def should_send_email?
    false
  end

end
