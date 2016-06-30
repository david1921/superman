module DailyDealPurchases::Callbacks

  # In the purchase controller, we always set a mailing address, even when we don't need one, and since
  # accepts_nested_attributes_for adds autosave validation for the mailing address, we have to clear it to prevent
  # a validation error.
  def clear_mailing_address_unless_required
    unless require_mailing_address?
      self.mailing_address = nil
    end
  end

end