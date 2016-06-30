module Smoke
  class Messages

    SMOKE_WARNING = "WARNING"
    SMOKE_ERROR = "ERROR"
    SMOKE_INFO = "INFO"

    class Message

      attr_reader :publisher_label

      def initialize(label, publisher_label, path, msg)
        @label = label
        @publisher_label = publisher_label
        @path = path
        @msg = msg.to_s
      end

      def to_s
        colorized_label + ": #{@publisher_label}: #{@path} : #{@msg}"
      end

      def colorized_label
        case @label
          when Smoke::Messages::SMOKE_WARNING
            @label.yellow
          when Smoke::Messages::SMOKE_ERROR
            @label.red
          when Smoke::Messages::SMOKE_INFO
            @label.blue
        end
      end

    end

    attr_reader :warnings, :errors, :info

    def initialize(quiet = false)
      @warnings = []
      @errors = []
      @info = []
      @indent_level = 0
      @quiet = quiet
    end

    def errors_and_warnings
      @errors + @warnings
    end

    def warning(publisher_label, path, msg)
      handle_message(@warnings, Message.new(SMOKE_WARNING, publisher_label, path, msg))
    end

    def error(publisher_label, path, msg)
      handle_message(@errors, Message.new(SMOKE_ERROR, publisher_label, path, msg))
    end

    def info(publisher_label, path, msg)
      handle_message(@info, Message.new(SMOKE_INFO, publisher_label, path, msg))
    end

    def clear
      @errors = []
      @warnings = []
      @info = []
      @indent_level = 0
    end

    def clear_errors
      @errors = []
    end

    def handle_message(collection, msg)
      collection << msg
      log(msg)
    end

    def log(msg)
      indentation = "  " * @indent_level
      unless quiet?
        puts "#{indentation}#{msg}"
      end
    end

    def quiet?
      return @quiet
    end

    def all
      @info + @warnings + @errors
    end

    def banner
      log ("*"*100).blue
      if block_given?
        yield
        log ("*"*100).blue
      end
    end

    def indent
      @indent_level += 1
      if block_given?
        begin
          yield
        ensure
          outdent
        end
      end
    end

    def outdent
      @indent_level -= 1
      @indent_level = 0 if @indent_level < 0
    end

    def clear_publisher(publisher_label)
      clear_collection_for_publisher(@warnings, publisher_label)
      clear_collection_for_publisher(@errors, publisher_label)
      clear_collection_for_publisher(@info, publisher_label)
    end

    def clear_collection_for_publisher(collection_of_messages, label)
      collection_of_messages.delete_if do |message|
        message.publisher_label == label
      end
    end

  end
end
