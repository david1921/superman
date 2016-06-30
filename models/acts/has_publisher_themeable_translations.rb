module HasPublisherThemeableTranslations
  def self.included(base)
    base.send :include, InstanceMethods
  end

  module InstanceMethods

    def translate_with_theme(key, options = {})
      if is_a?(Publisher) | is_a?(PublishingGroup)
        publisher_or_group = self
      elsif respond_to?(:publisher)
        publisher_or_group = publisher
      elsif respond_to?(:publishing_group)
        publisher_or_group = publishing_group
      end

      Analog::Themes::I18n.translate(publisher_or_group, key, options)
    end

  end
end
