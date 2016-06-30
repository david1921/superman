module DailyDeals
  module Orders
    def current_daily_deal_order(publisher)
      if @daily_deal_order.nil?
        @daily_deal_order = ::DailyDealOrder.find_by_uuid( session[:daily_deal_order] )
        
        if !@daily_deal_order || @daily_deal_order.executed? || @daily_deal_order.consumer.try(:publisher) != publisher
          @daily_deal_order = (current_consumer_for_publisher?(publisher) && current_user.daily_deal_orders.pending.first) || ::DailyDealOrder.new
        end
      end
      session[:daily_deal_order] = @daily_deal_order.uuid
      @daily_deal_order.cleanse!
    end
  end
end
