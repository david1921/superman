# TODO Just make this a superclass?
module Messaging
  module Acts
    module Message
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_message
          class_eval {
            cattr_accessor :gateway
            include Messaging::Acts::Message::InstanceMethods

            def gateway_uri
              unless @gateway_uri
                app_config_prefix = self.class.name.demodulize.underscore

                server = AppConfig.send("#{app_config_prefix}_gateway_server")
                raise "Could not find '#{app_config_prefix}_gateway_server' in AppConfig" unless server

                path = AppConfig.send("#{app_config_prefix}_gateway_path")
                raise "Could not find '#{app_config_prefix}_gateway_path' in AppConfig" unless path

                @gateway_uri = "#{server}#{path}"
                logger.debug("#{self.class.name} gateway_uri: #{@gateway_uri}") if logger.debug?
                # cURL accepts a plain String, but parse URI as a sanity check.
                URI.parse(@gateway_uri)
              end
              @gateway_uri
            end
          }
        end

        def find_first_message_to_send
          self.find(:first, :conditions => ["(status = 'created' or status = 'retry') and (send_at is null or send_at <= ?)", Time.zone.now])
        end
      end

      module InstanceMethods
        def enqueued
          self.status = "enqueued"
          save!
        end

        def sent(response)
          update_from_gateway(response)
          self.sent_at = Time.now

          case self.status
          when "sent"
            logger.info "Send succeeded for #{self.class.name} id #{id}"
          when "error"
            logger.info "Send error for #{self.class.name} id #{id}"
          when "retry"
            try_retry
          else
            logger.debug "Send status set to #{self.status} for #{self.class.name} id #{id}" if logger.debug?
          end

          save!
        end

        def send_failed(ex=nil)
          try_retry
          save!
        end

        def try_retry
          if self.retries < 3
            self.status = "retry"
            self.retries = self.retries + 1
            # 1, 2, 4 minutes
            self.send_at = Time.now + (2 ** (self.retries - 1)).minute
            logger.debug "Send retry for #{self.class.name} id #{id} at #{self.send_at}"
          else
            self.status = "error"
            self.retries = 3
            logger.warn "Send retried 3 times and failed for #{self.class.name} id #{id}"
          end
        end

        def http_method
          :post
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval { include Messaging::Acts::Message }
