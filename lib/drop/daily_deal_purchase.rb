module Drop
  class DailyDealPurchase < Liquid::Drop

    def initialize(daily_deal_purchase)
      @daily_deal_purchase = daily_deal_purchase
    end

    def store
      Drop::Store.new(@daily_deal_purchase.store) if @daily_deal_purchase.store
    end

  end
end
