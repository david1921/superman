module ThirdPartyDealsApi
  module XML
    module Helper
      def purchase_root_node_attributes
        {
          :listing => @daily_deal_purchase.daily_deal.listing,
          :purchase_id => @daily_deal_purchase.uuid,
          :xmlns => "http://analoganalytics.com/api/third_party_deals/purchases"
        }
      end
    end
  end
end