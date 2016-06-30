module ActiveRecord
  module Validations

    module ClassMethods

      def validates_immutability_of(*attr_names)
        configuration = attr_names.extract_options!
        validates_each(attr_names, configuration) do |record, attr_name, value|
          if !record.new_record? && record.send("#{attr_name}_was") != value
            record.errors.add(attr_name, "%{attribute} cannot be changed")
          end
        end
      end

      def validates_email(*attr_names)
        configuration = attr_names.extract_options!

        validates_each(attr_names, configuration) do |record, attr_name, value|
          if (configuration[:allow_nil] && value == nil) || (configuration[:allow_blank] && value.blank?)
            return
          elsif !(valid_email?(value))
            record.errors.add(attr_name, configuration[:message] || I18n.translate(:invalid_email_message))
          end
        end

      end

      def valid_email?(email)
        Analog::Util::EmailValidator.new.valid_email?(email)
      end

    end
  end
end
