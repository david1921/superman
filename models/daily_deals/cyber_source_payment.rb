class CyberSourcePayment < DailyDealPayment
  with_options :if => Proc.new { |record| record.payment_gateway_id.present? } do |this|
    this.validates_presence_of :credit_card_last_4
    this.validates_length_of :credit_card_last_4, :is => 4
  end

  def void_or_full_refund!(admin)
    daily_deal_purchase.cyber_source_void_or_full_refund!(admin)
  end

  def partial_refund!(admin, partial_amount)
    daily_deal_purchase.cyber_source_partial_refund!(admin, partial_amount)
  end
  
  def refundable?
    daily_deal_purchase.cyber_source_refundable?
  end

  def submit_for_settlement!
    raise "CyberSource sales cannot be submitted for settlement"
  end

  def from_order?(cyber_source_order)
    cyber_source_order.request_id == payment_gateway_id
  end
end
