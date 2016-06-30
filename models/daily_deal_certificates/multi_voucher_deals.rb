module DailyDealCertificates
  
  module MultiVoucherDeals
    
    include ActionView::Helpers::NumberHelper
    
    def value
      (daily_deal_purchase.value / daily_deal_purchase.certificates_to_generate_per_unit_quantity).round(2)
    end
      
    def line_item_name
      if publisher.enable_daily_deal_voucher_headline? && voucher_headline.present?
        voucher_headline
      else
        translate_with_theme(:line_item_name, :value => number_to_currency(value, :unit => publisher.currency_symbol), :advertiser => daily_deal.advertiser_name.strip)
      end
    end

  end
  
end
