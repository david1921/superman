module TravelsaversBookingMailerHelper
  
  def purchase_error_url(booking)
    error_daily_deal_purchase_url(booking.daily_deal_purchase, :host => booking.publisher.production_host, :protocol => "https")
  end
end
