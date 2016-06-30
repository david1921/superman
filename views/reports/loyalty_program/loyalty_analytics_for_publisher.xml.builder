xml.instruct!(:xml, :version => '1.0')

xml.purchases do
  
  @purchases_with_loyalty_referrals.each do |p|
    xml.purchase do
      xml.value_proposition(p.deal_value_proposition)
      xml.quantity(p.quantity)
      xml.purchaser_name(p.purchaser_name)
      xml.executed_at(p.executed_at.to_date)
      xml.payment_status(p.payment_status.capitalize)
      xml.loyalty_referrals_count(p.loyalty_referrals_count)
      xml.refunded_at(p.refunded_at.try(:to_formatted_s, :db_date))
    end
  end
  
end
