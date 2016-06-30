class PaypalNotificationsController < ApplicationController  
  protect_from_forgery :except => :create

  def create 
    paypal_notification = PaypalNotification.new(request.raw_post)
    PaypalNotification.ipn_url = PaypalConfiguration.production_ipn_url unless PaypalConfiguration.use_sandbox?
    if paypal_notification.acknowledge
      paypal_notification.dispatch!
    else
      raise "Paypal IPN acknowledgement failed for raw post #{request.raw_post} (IPN URL: #{PaypalNotification.ipn_url})"
    end
    render :nothing => true
  end
end
