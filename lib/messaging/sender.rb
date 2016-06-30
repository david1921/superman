module Messaging
  class Sender
    MESSAGE_CLASSES = [ Txt, VoiceMessage ].freeze
    MAX_WINDOW = 4

    attr_accessor :curl_multi

    def self.run
      self.new.run
    end

    def initialize
      @curl_multi = Curl::Multi.new
      @class_index = 0
    end

    def run
      logger.info "Daemon::Sender run"
      should_exit = false
      until should_exit do
        begin
          # Try all message classes before sleeping
          MESSAGE_CLASSES.length.times { enqueue_some }
          if curl_multi.size > 0 then curl_multi.select([], []) else sleep(1.0) end
        rescue SystemExit => e
          should_exit = true
          logger.error("SystemExit: #{e.message}\n")
          exit(0)
        rescue Exception => e
          handle_exception(e)
        end
      end
    end

    def enqueue_some
      number_added = 0
      while MAX_WINDOW > curl_multi.size
        @class_index = @class_index.next
        @class_index = 0 if @class_index == MESSAGE_CLASSES.length
        message = MESSAGE_CLASSES[@class_index].find_first_message_to_send
        return unless message
        
        # Setting up curl completion callbacks in a separate method
        # avoids binding name +message+ to the local variable
        # in this method, which will be modified next loop iteration.
        enqueue_one(message)
        number_added += 1
      end
      logger.debug "Daemon::Sender enqueue_some: #{number_added} added" if number_added > 0
      number_added
    end

    def enqueue_one(message)
      on_sent = lambda do |body|
        message.sent(body)
      end

      on_send_failed = lambda do |ex|
        logger.error("Send failed: #{ex} for #{message.class.name} id #{message.id} #{message.inspect if logger.debug?}")
        message.send_failed(ex)
      end

      logger.info("Enqueue #{message.inspect}") if logger.info?
      message.enqueued

      case message.http_method.to_s
      when /get/i
        logger.debug "Enqueue GET #{message.gateway_uri}"
        curl_multi.get message.gateway_uri, on_sent, on_send_failed
      when /post/i
        logger.debug "Enqueue POST #{message.gateway_uri}, #{message.to_gateway_format.inspect}"
        curl_multi.post message.gateway_uri, message.to_gateway_format, on_sent, on_send_failed
      end
    end

    def handle_exception(e)
      trace = [e.message]
      trace = e.backtrace.join("\n") if e.backtrace
      logger.error("#{self.class.name} Error: #{e.message}\n#{trace}")
      Exceptional.handle(e)
    end
    
    def logger
      unless @logger
        @logger = Logger.new(AppConfig.sender_log_path)
        @logger.level = AppConfig.sender_log_level || Logger::DEBUG
        ActiveRecord::Base.logger = @logger
      end
      @logger
    end
  end
end
