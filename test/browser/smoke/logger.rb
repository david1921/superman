module Smoke
  module Logger

    def messages?
      respond_to?(:messages) && messages.present?
    end

    def log(msg)
      if messages?
        messages.log msg
      else

        puts msg
      end
    end

    def warning(publisher_label, path, msg)
      if messages?
        messages.warning(publisher_label, path, msg)
      else
        puts Messages::Message.new("WARNING", publisher_label, path, msg)
      end
    end

    def error(publisher_label, path, msg)
      if messages?
        messages.error(publisher_label, path, msg)
      else
        puts Messages::Message.new("ERROR", publisher_label, path, msg)
      end
    end

    def info(publisher_label, path, msg)
      if messages?
        messages.info(publisher_label, path, msg)
      else
        puts Messages::Message.new("INFO", publisher_label, path, msg)
      end
    end

    def log_collection(title, collection)
      unless collection.nil? || collection.empty?
        messages.banner do
          log title
          collection.each do |c|
            log c
          end
        end
      end
    end

  end
end

