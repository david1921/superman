module Analog
  module Say
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def say(text)
        if text.present?
          if Rails.env.test?
            Rails.logger.info text
          else
            puts text
          end
        end
      end

      def dot
        if !Rails.env.test?
          putc "."
        end
      end
    end

    module InstanceMethods
      def dot
        self.class.dot
      end

      def say(text)
        self.class.say(text)
      end
    end
  end
end
