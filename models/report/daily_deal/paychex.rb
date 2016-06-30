module Report::DailyDeal::Paychex

  PAYCHEX_CC_FEE_PERCENTAGE = {
    0..10.00       => BigDecimal.new("0.04"),
    10.01..15.00   => BigDecimal.new("0.038"),
    15.01..20.00   => BigDecimal.new("0.035"),
    20.01..30.00   => BigDecimal.new("0.033"),
    30.01..40.00   => BigDecimal.new("0.028"),
    40.01..60.00   => BigDecimal.new("0.027"),
    60.01..80.00   => BigDecimal.new("0.026"),
    80.01..100.00  => BigDecimal.new("0.025"),
    100.01..120.00 => BigDecimal.new("0.024"),
    120.01..1.0/0  => BigDecimal.new("0.023")
  }
  
  def paychex_total_payment_due(period_ending_date)
    report_period_end_date = period_ending_date.to_date

    total_due = if report_period_end_date < date_when_initial_paychex_payout_will_be_made
      BigDecimal.new("0")
    elsif report_period_end_date < date_when_full_paychex_payout_will_be_made
      paychex_advertiser_share * (publisher.paychex_initial_payment_percentage / BigDecimal.new("100.0"))
    else
      paychex_advertiser_share
    end
    
    [total_due, paychex_advertiser_share].min
  end
  
  def date_when_initial_paychex_payout_will_be_made
    hide_at.to_date + number_of_days_to_receive_funds_from_payment_processor + 1
  end
  
  def date_when_full_paychex_payout_will_be_made
    hide_at.to_date + publisher.paychex_num_days_after_which_full_payment_released + 1
  end
  
  def number_of_days_to_receive_funds_from_payment_processor
    4
  end

  # = paycheck_advertiser_share
  # 
  # Variables:
  #
  #   GR = gross revenue
  #   RF = refund total
  #   AS = (advertiser share %) / 100
  #   CC = paychex credit card %
  #
  # Formula:
  #
  #   ((GR - RF) * AS) - (CC * (AS * GR))
  #
  def paychex_advertiser_share
    ((BigDecimal.new(gross_revenue_to_date.to_s) - BigDecimal.new(refunds_to_date.to_s)) *
     (BigDecimal.new(advertiser_revenue_share_percentage.to_s) / BigDecimal.new("100.0"))) -
     (paychex_credit_card_percentage *
      (BigDecimal.new(advertiser_revenue_share_percentage.to_s) / BigDecimal.new("100.0")) *
      BigDecimal.new(gross_revenue_to_date.to_s))
  end

  def paychex_credit_card_fee
    BigDecimal.new(gross_revenue_to_date.to_s) * paychex_credit_card_percentage
  end
  
  def paychex_credit_card_percentage
    sales_range = PAYCHEX_CC_FEE_PERCENTAGE.keys.find { |sales_range| sales_range.include?(price) }
    raise "unable to determine paychex credit card fee percentage for deal: #{inspect}" if sales_range.nil?
    PAYCHEX_CC_FEE_PERCENTAGE[sales_range]
  end
  
  def refunds_to_date
    BigDecimal.new(daily_deal_refunds_total_amount.to_s)
  end
end
