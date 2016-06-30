module DailyDealPurchases::VoucherShipping
  def require_mailing_address?
    fulfillment_method == 'ship'
  end

  def validate_mailing_address?
    require_mailing_address? && mailing_address.present? && pending?
  end

  def validate_mailing_address
    unless mailing_address.valid?
      errors.add(:mailing_address, translate_with_theme("activerecord.errors.messages.invalid"))
    end
  end
end