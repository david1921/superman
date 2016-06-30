module CyberSourceHelper
  def cyber_source_order_signature(daily_deal_purchase, order, transaction_type = "sale")
    order_number = daily_deal_purchase.cyber_source_order_number
    order_amount = daily_deal_purchase.cyber_source_order_amount
    order_currency = daily_deal_purchase.cyber_source_order_currency
    order_timestamp = "%d" % (order.created_at.to_f * 1000)
    
    credentials = daily_deal_purchase.cyber_source_credentials

    signature_data = [credentials.merchant_id, order_amount, order_currency, order_timestamp, transaction_type].map(&:strip).join
    signature_hash = credentials.signature(signature_data)
    url_options = { :protocol => https_unless_development, :host => daily_deal_purchase.publisher.daily_deal_host }
    
    {
      "merchantID" => credentials.merchant_id,
      "orderNumber" => order_number,
      "amount" => order_amount,
      "currency" => order_currency,
      "orderPage_version" => "7",
      "orderPage_transactionType" => transaction_type,
      "orderPage_serialNumber" => credentials.serial_number,
      "orderPage_timestamp" => order_timestamp,
      "orderPage_signaturePublic" => signature_hash,
      "orderPage_receiptResponseURL" => receipt_cybersource_url(url_options),
      "orderPage_declineResponseURL" => decline_cybersource_url(url_options)
    }.map { |name, value| hidden_field_tag(name, value) }.join.html_safe
  end
  
  def cyber_source_error_messages(daily_deal_purchase, order)
    if (messages = order.error_messages).present?
      header_message = I18n.t("cyber_source.error.unable_to_process")
      footer_message = cyber_source_error_footer_message(daily_deal_purchase, order)
      items = messages.map { |message| "<li>#{message}</li>" }
      
      content = "<h3 class='header'>#{header_message}</h3><ul>#{items}</ul><h3 class='footer'>#{footer_message}</h3>".html_safe
      content_tag("div", content, :class => "daily_deal_payment_errors clear")
    end
  end
    
  def cyber_source_billing_country_options(daily_deal_purchase)
    %w{ US CA }.map { |code| [Country.find_by_code(code).name, code.downcase] }
  end
    
  def cyber_source_card_type_options(daily_deal_purchase)
    keys = daily_deal_purchase.cyber_source_card_types
    [["Select Card Type", ""]] +
      CyberSource::Order::CARD_CODE_FROM_TYPE.slice(*keys).to_a.sort_by(&:last).map { |name, type| [I18n.t("cyber_source.order.card.#{name}"), type] }
  end
  
  private
  
  def cyber_source_error_footer_message(daily_deal_purchase, order)
    email = daily_deal_purchase.publisher.support_email_address
    phone = daily_deal_purchase.publisher.support_phone_number
    I18n.t("cyber_source.error.#{order.retry_type}", :email_address => email, :phone_number => phone)
  end
end
