module PaypalHelper
  # record = Any ActiveRecord that responds to :publisher
  def paypal_checkout_header_image_url(record)
    #
    # Paypal doesn't like query strings in the checkout header URL.
    #
    path, query = record.publisher.paypal_checkout_header_image.url.split("?")
    path.gsub(/^http:/, "https:")
  end

  def paypal_cancel_return_url(daily_deal_purchase)
    publisher = daily_deal_purchase.publisher
    if url = publisher.try(:custom_paypal_cancel_return_url)
     url
    else
     public_deal_of_day_url(publisher.label, :host => publisher.host)
    end
  end

  def paypal_return_url(daily_deal_purchase)
    daily_deal = daily_deal_purchase.daily_deal(:include => :publisher)
    thank_you_daily_deal_purchase_url(daily_deal_purchase, :host => daily_deal.publisher.host, :protocol => https_unless_development)
  end
end
