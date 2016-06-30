require File.dirname(__FILE__) + "/voice_gateway_message_resource"

module Messaging
  class VoiceGateway
    # Query the gateway: how many voice message requests have you received?
    def count
      Timeout::timeout(5) do
        loop do
          begin
            return VoiceGatewayMessageResource.get(:count).to_i
          rescue Exception => e
            Rails.logger.debug("VoiceGatewayMessageResource exception: #{e}")
            sleep(0.5)
          end
        end
      end
    end

    def delete_all_messages
      Timeout::timeout(10) do
        loop do
          begin 
            return VoiceGatewayMessageResource.delete(:delete_all) 
          rescue Exception => e
            Rails.logger.debug("VoiceGatewayMessageResource exception: #{e}")
            sleep(0.5)
          end
        end
      end
    end
    
    def all_messages
      Timeout::timeout(10) do
        loop do
          begin 
            return VoiceGatewayMessageResource.get(:voice_messages).collect do |params|
              VoiceGatewayMessage.new(params.except(:id))
            end
          rescue Exception => e
            Rails.logger.debug("VoiceGatewayMessageResource exception: #{e}")
            sleep(0.5)
          end
        end
      end
    end
  end
end
