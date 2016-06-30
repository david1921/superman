module DailyDeals
  class SearchResponse
    
    attr_reader :daily_deals
    
    def initialize(daily_deals = [])
      @daily_deals = daily_deals
    end
        
  end
end