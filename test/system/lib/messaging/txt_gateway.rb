module Messaging
  class TxtGateway
    # Query the gateway: how many txt message requests have you received?
    def count
      Timeout::timeout(5) do
        loop do
          begin
            return TxtGatewayMessageResource.get(:count).to_i
          rescue Exception => e
            Rails.logger.debug("TxtGatewayMessageResource exception: #{e}")
            sleep(0.5)
          end
        end
      end
    end

    def delete_all_messages
      Timeout::timeout(10) do
        loop do
          begin 
            return TxtGatewayMessageResource.delete(:delete_all) 
          rescue Exception => e
            Rails.logger.debug("TxtGatewayMessageResource exception: #{e}")
            sleep(0.5)
          end
        end
      end
    end
  end
end
