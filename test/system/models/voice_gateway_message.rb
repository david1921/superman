# Voice message received by the voice gateway (Ifbyphone in production, VoiceGatewayMessagesController here in test),
# sent from our system. Used to assert that our system is sending outbound voice messages correctly.
class VoiceGatewayMessage < GatewayMessage
  def initialize(params={})
    if params.has_key?(:p_t) || params.has_key?(:survo_id) || params.has_key?(:user_parameters)
      super :message => YAML.dump(params.slice("p_t", "survo_id", "user_parameters")), :mobile_number => params["phone_to_call"]
    else
      super params
    end
  end
  
  def p_t
    YAML.load(self.message)["p_t"]
  end

  def survo_id
    YAML.load(self.message)["survo_id"]
  end
  
  def user_parameters
    YAML.load(self.message)["user_parameters"]
  end
end
