module Analog
  module Themes
    module I18n

      class << self
        def translate(publisher_or_group, key, options = {})
          translation = themed_translation(publisher_or_group, key, options)
          if publisher_or_group.respond_to?(:publishing_group)
            translation ||= themed_translation(publisher_or_group.try(:publishing_group), key, options)
          end


          translation || ::I18n.translate(key, options)
        end

        alias :t :translate

        private

        def themed_translation(publisher_or_group, key, options)
          return if publisher_or_group.try(:label).blank?

          options = options.dup
          options.delete(:default)

          if options[:scope].is_a?(String) || options[:scope].is_a?(Symbol)
            options[:scope] = "#{publisher_or_group.label}.#{options[:scope]}"
          else
            options[:scope] = [publisher_or_group.label] + (options[:scope] || [])
          end

          options[:raise] = true

          ::I18n.translate(key, options) rescue nil
        end
      end

    end
  end
end
