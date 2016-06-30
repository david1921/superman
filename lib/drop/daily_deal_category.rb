module Drop
  class DailyDealCategory < Liquid::Drop
    delegate :id,
             :name,
             :to => :daily_deal_category

    def initialize(daily_deal_category)
      @daily_deal_category = daily_deal_category
    end

    private

    def daily_deal_category
      @daily_deal_category
    end
  end
end

