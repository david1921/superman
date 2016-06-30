module DailyDealPurchases::Validations

  def recipient_names_match_quantity_times_voucher_multiple
    if gift? && !quantity_times_voucher_multiple_matches_recipient_names?
      errors.add_to_base(I18n.t("activerecord.errors.custom.should_be_multiple_recipient", :quantity => expected_number_of_recipients))
    end
  end

  def recipients_match_quantity_times_voucher_multiple
    return unless requires_shipping_address?

    if gift?
      unless recipients.size == expected_number_of_recipients
        errors.add(:recipients, I18n.t("activerecord.errors.custom.should_be_multiple_recipient", :quantity => expected_number_of_recipients))
      end
    else
      errors.add(:recipients, I18n.t("activerecord.errors.custom.should_be_one_recipient")) if recipients.size != 1
    end
  end

  def quantity_must_be_one_for_travelsavers_purchases
    return unless travelsavers?
    
    unless quantity == 1
      errors.add(:quantity, I18n.t("activerecord.errors.custom.must_be_one_for_travelsavers_purchases"))
    end
  end
  
  def travelsavers_purchases_cannot_be_gifted
    return unless travelsavers?
    
    if gift?
      errors.add(:gift, I18n.t("activerecord.errors.custom.travelsavers_purchases_cannot_be_gifted"))
    end
  end
  private

  def quantity_times_voucher_multiple_matches_recipient_names?
    recipient_names && quantity_times_voucher_multiple_matches_recipients? && recipient_names.all?(&:present?)
  end

  def quantity_times_voucher_multiple_matches_recipients?
    expected_number_of_recipients == recipient_names.size
  end
  
  def requires_shipping_address?
    daily_deal.try(:requires_shipping_address?)
  end
end
