class TxtGatewayMessageResource < ActiveResource::Base
  self.site = AppConfig.txt_gateway_server
  self.element_name = "txt_gateway_message"  
end