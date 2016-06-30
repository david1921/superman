module OffPlatformDailyDealPurchases::Validations

  def recipient_names_match_quantity
    unless quantity_matches_recipient_names?
      errors.add_to_base("There should be #{quantity} recipient names")
    end
  end

  def consumer_is_nil
    unless consumer.nil?
      errors.add(:consumer, '%{attribute} must be nil')
    end

    unless consumer_id.nil?
      errors.add(:consumer_id, '%{attribute} must be nil')
    end
  end

  private

  def quantity_matches_recipient_names?
    recipient_names && quantity_matches_recipients? && recipient_names.all?(&:present?)
  end

  def quantity_matches_recipients?
    quantity == recipient_names.size
  end

end