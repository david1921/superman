class Messaging::VoiceGatewayMessageResource < ActiveResource::Base
  self.site = AppConfig.voice_message_gateway_server
  self.element_name = "voice_gateway_message"  
end