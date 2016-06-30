module DailyDealPurchases::Discount

  def clear_discount_if_discount_used_by_another_item_in_cart!
    return unless in_shopping_cart? && discount.present?
    self.discount = self.discount_id = nil if discount_code_used_by_other_items_in_shopping_cart?
  end

  def discount_amount
    [0.0, discount.try(:amount).try(:to_f) || 0.0].max
  end

  def discount_uuid
    discount.try(:uuid)
  end

  def discount_uuid=(value)
    self.discount = ::Discount.find_by_uuid(value)
  end

  def discount_code_unique_within_shopping_cart
    return unless in_shopping_cart? && discount.present?
    daily_deal_order.reload

    if discount_code_used_by_other_items_in_shopping_cart?
      errors.add_to_base("discount '#{discount.code}' has already been applied to another item in this cart")
    end
  end

  def discount_code_used_by_other_items_in_shopping_cart?
    return unless in_shopping_cart? && discount.present?
    daily_deal_order.daily_deal_purchases.
      reject { |ddp| ddp == self }.
      any? { |ddp| ddp.discount == discount }
  end

  def assign_signup_discount_if_usable
    self.discount = consumer.try(:signup_discount_if_usable)
  end


  private

  def assign_discount_from_code
    if publisher.present? && @discount_code.present?
      discount = publisher.discounts.usable.at_checkout.find_by_code(@discount_code)
      if discount && discount_code
        self.discount = discount
      end
    end
  end

  def discount_assignment_from_code
    if @discount_code.present? && discount.blank?
      errors.add_to_base I18n.t("activerecord.errors.custom.invalid_discount_code", :discount_code => @discount_code)
    end
  end

  def discount_belongs_to_publisher
    if discount.present? && daily_deal.try(:publisher).try(:id) != discount.publisher_id
      errors.add_to_base I18n.t("activerecord.errors.custom.invalid_discount_code", :discount_code => @discount_code)
      self.discount = nil
    end
  end

  def consumer_has_not_executed_with_discount
    if consumer.present? && discount.present?
      conditions_sql = %Q{(payment_status ='authorized' OR payment_status = 'captured') AND consumer_id = ? AND discount_id = ?}
      conditions_params = [consumer.id, discount.id]
      unless new_record?
        conditions_sql << " AND id <> ?"
        conditions_params << id
      end
      if self.class.exists?([conditions_sql, *conditions_params])
        errors.add_to_base I18n.t("activerecord.errors.custom.already_used_discount_code", :discount_code => discount.code)
      end
    end
  end

  def mark_discount_as_used_if_necessary
    return unless discount.present?
    return unless captured? || authorized?
    return if discount.used?
    discount.use! if discount.usable_only_once?
  end

end