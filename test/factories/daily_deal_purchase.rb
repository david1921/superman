module Factories
  module DailyDealPurchase
    def authorized_purchase_factory_after_create
      self.payment_status = "authorized" if pending?
      self.payment_status_updated_at ||= Time.zone.now
      self.executed_at ||= Time.zone.now
      save!
      self
    end
  end
end