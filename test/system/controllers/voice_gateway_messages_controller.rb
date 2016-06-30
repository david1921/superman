class VoiceGatewayMessagesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # Pretend to be Ifbyphone gateway. Receive voice message request.
  # Naming a little shaky, but consistent with txt msg test controller.
  #
  # {  "app" => "CTS",
  #   "key" => "e319fcab70ecdd48749bc97eb2d3abc6390ca675",
  #   "acct" => "6313",
  #   "first_callerid" => "8005209405",
  #   "survo_id" => "6",
  #   "phone_to_call" => voice_message.mobile_number[1..-1],
  #   "p_t" => voice_message.to_param
  # }
  def create
    if params["app"] != "CTS"
      logger.error("Missing or incorrect 'app'")
      render :text => "error: missing 'app'", :status => 200
      return
    end

    if params["key"] != "e319fcab70ecdd48749bc97eb2d3abc6390ca675"
      logger.error("Missing or incorrect 'key'")
      render :text => "error: missing 'key'", :status => 200
      return
    end

    if params["acct"] != "6313"
      logger.error("Missing or incorrect 'acct'")
      render :text => "error: missing 'acct'", :status => 200
      return
    end

    if params["first_callerid"] !~ /\A\d{10}\Z/
      logger.error("Missing or incorrect 'first_callerid'")
      render :text => "error: missing 'first_callerid'", :status => 200
      return
    end

    if params["survo_id"] !~ /\A\d+\Z/
      logger.error("Missing or incorrect 'survo_id'")
      render :text => "error: missing 'survo_id'", :status => 200
      return
    end

    if params["phone_to_call"] !~ /\A\d{10}\Z/
      logger.error("Missing or incorrect 'phone_to_call'")
      render :text => "error: missing 'phone_to_call'", :status => 200
      return
    end

    if params["p_t"] !~ /\A\d+\Z/
      logger.error("Missing or incorrect 'p_t'")
      render :text => "error: missing 'p_t'", :status => 200
      return
    end

    if params["user_parameters"].present? && params["user_parameters"] !~ /\Acenter_phone_number\|\d{10}\Z/
      logger.error("Missing or incorrect 'user_parameters'")
      render :text => "error: incorrect 'user_parameters'", :status => 200
      return
    end

    VoiceGatewayMessage.create! params
    render :text => "connected"
  end

  # How many outbound voice message requests have you received from our voice sender?
  def count
    render :xml => "<count>#{VoiceGatewayMessage.count}</count>"
  end

  def delete_all
    render :xml => "<result>#{VoiceGatewayMessage.delete_all}</result>"
  end
  
  def voice_messages
    render :xml => VoiceGatewayMessage.find(:all).to_xml
  end
end

