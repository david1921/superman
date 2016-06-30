module BaseDailyDealPurchases::Totals

  def total_value
    quantity * value
  end

  def total_price_without_discount
    [0.0, quantity * price].max
  end

  def total_price_with_discount
    [0.0, quantity * price - discount_amount].max
  end

  def credit_usable
    [total_price_with_discount, credit_available || 0.0].min
  end

  def total_price
    [0.0, total_price_with_discount - credit_used + (voucher_shipping_amount || 0.0)].max
  end

  def total_paid
    if travelsavers?
      (actual_purchase_price.present? && (captured? || refunded?)) ? actual_purchase_price : 0.0
    else
      daily_deal_payment.present? ? daily_deal_payment.amount : 0.0
    end
  end

end
