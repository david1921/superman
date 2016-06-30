module DailyDealPayments
  
  module Travelsavers
    
    def self.included(base)
      base.validate :daily_deal_purchase_not_through_travelsavers_payment_method
    end

    def daily_deal_purchase_not_through_travelsavers_payment_method
      if daily_deal_purchase.present? && daily_deal_purchase.travelsavers?
        errors.add_to_base "cannot create a payment for a Travelsavers purchase: funds from these purchases are not captured by Analog"
      end
    end

  end

end
