module Locales
  module Enabled
    BASE_LOCALES_DIR = "config/locales"
    THEMED_LOCALES_DIR = "config/locales/themes"
    FULL_NAMES = { :en => "English", :es => "Español", :"es-MX" => "Español (México)", :el => "ελληνικά", :zh => "汉语/漢語" }.with_indifferent_access

    def enabled_locales_to_display
      base_locales_path = File.join(Rails.root, BASE_LOCALES_DIR)
      themed_locales_path = File.join(Rails.root, THEMED_LOCALES_DIR, label)
      locales = []
      [base_locales_path, themed_locales_path].each do |path|
        if File.exists? path
          locales += Dir.open(path).collect { |x| /^(.*)\.yml$/.match(x).try(:values_at, 1) }.flatten.compact
        end
      end
      locales.uniq.sort
    end

    private

    def locale_exists?(label, locale)
      I18n.available_locales.include?(locale.to_sym) || themed_locale_exists?(label, locale)
    end

    def themed_locale_exists?(label, locale)
      label && File.exists?(File.join(Rails.root, THEMED_LOCALES_DIR, label, "#{locale}.yml"))
    end

    def enabled_locales_exist
      invalid_locales = []
      if enabled_locales
        enabled_locales.each do |locale|
          invalid_locales << locale unless locale_exists?(label, locale)
        end
        errors.add(:enabled_locales, "locale not available: #{invalid_locales.join(", ")}") unless invalid_locales.blank?
      end
    end
  end
end