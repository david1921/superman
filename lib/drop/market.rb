module Drop
  class Market < Liquid::Drop
    include ActionController::UrlWriter

    delegate :id, :name, :google_analytics_account_ids, :to => :market

    attr_reader :market

    def initialize(market)
      @market = market
    end

    def todays_daily_deal_path
      public_deal_of_day_for_market_path(@market.publisher.label, @market.label)
    end
  end
end
