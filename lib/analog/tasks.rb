module Analog
  module Tasks
    def self.send_daily_deal_purchase_summary_report!
      Publisher.currencies_in_use.each do |currency_code|
        AnalogMailer.deliver_daily_purchase_summary_report(
          DailyDeal.publishers_with_purchase_totals_for_24h_and_30d(currency_code), currency_code)
      end
    end
  end
end
