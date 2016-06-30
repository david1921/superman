module DailyDealPurchases::PromotionDiscounts

  def earned_discount
    ::Discount.find_by_daily_deal_purchase_id(id)
  end

  def create_promotion_discount
    if eligible_for_promotion_discount?
      publisher.publishing_group.promotions.active.first.create_discount_for_purchase(self)
    end
  rescue => e
    Exceptional.handle(e, "error in promotion discount generation")
  end

  def eligible_for_promotion_discount?
    if publisher.publishing_group.present?
      pg = publisher.publishing_group
      if pg.promotions.active.present?
        promotion = pg.promotions.active.first
        unless promotion.discounts.first(:conditions => ["daily_deal_purchases.consumer_id = ?", self.consumer_id], :joins => :daily_deal_purchase)
          return true
        end
      end
    end
    false
  end

end