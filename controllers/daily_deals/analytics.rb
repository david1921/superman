module DailyDeals
  module Analytics
    def set_analytics_tag
      if @daily_deal_order
        flash[:analytics_tag] = {
          :value    => @daily_deal_order.total_price,
          :quantity => @daily_deal_order.quantity,
          :item_id  => @daily_deal_order.daily_deal_purchases.first.daily_deal_id,
          :sale_id  => @daily_deal_order.id
        }
      else
        flash[:analytics_tag] = {
          :value    => @daily_deal_purchase.daily_deal_payment.try(:amount),
          :quantity => @daily_deal_purchase.quantity,
          :item_id  => @daily_deal_purchase.daily_deal_id,
          :sale_id  => @daily_deal_purchase.id
        }
      end
    end
  end
end