class OptimalNotificationsController < ApplicationController

  if ssl_rails_environment?
    ssl_required :create
  else
    ssl_allowed  :create
  end

  protect_from_forgery :except => :create

  def create
    encoded_message = params['encodedMessage']
    decoded_message = Base64.decode64(encoded_message)
    
    Rails.logger.info("[OPTIMAL] -- start of message --")
    Rails.logger.info(decoded_message)
    Rails.logger.info("[OPTIMAL] -- end of message --")    
    
    profile_checkout_response = OptimalPayments::ProfileCheckoutResponse.new(
      :encoded_message => params[:encodedMessage], :signature => params[:signature])
    profile_checkout_response.process!
    render :nothing => true, :status => 204
  end
  
end
