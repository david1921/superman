class DailyDealPurchaseMailer < ApplicationMailer

  def confirmation(daily_deal_purchase)
    from support_sending_email_address(daily_deal_purchase.publisher)
    recipients daily_deal_purchase.consumer.email
    subject Analog::Themes::I18n.t(daily_deal_purchase.publisher, "daily_deal_purchase_mailer.confirmation.subject")
    body :daily_deal_purchase => daily_deal_purchase
  end
end
