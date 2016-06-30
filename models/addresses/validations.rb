=begin
To add support for validation for a new kind of postal_code simply add a method "#{country_code}_regex",
e.g. "def us_regex", that returns an appropriate regex.  See examples below.
=end
module Addresses
  module Validations

    # Uses the model's country code to determine how to validate zip
    def validates_zip_code_according_to_country_code(*config)
      validates_each(:zip_code, *config) do |model, attr, zip|
         if zip.present?
           regex = postal_code_regex(model.country_code)
           if regex.present? && !(regex =~ zip)
             model.errors.add(attr, I18n.t("activerecord.errors.messages.invalid"))
           end
         end
      end
    end

    # Uses model's publisher's country_codes to determine how to validate zip
    def validates_zip_code_according_to_publisher(*config)
      validates_each(:zip_code, *config) do |model, attr, zip|
         if zip.present?
           valid = false
           if model.publisher
             model.publisher.country_codes.each do |country_code|
               regex = postal_code_regex(country_code)
               if regex.present?
                 valid = true if regex =~ zip
               else
                 # valid if there's no validation regex
                 valid = true
               end
             end
           else
             valid = true
           end
           unless valid
             model.errors.add(attr, I18n.t("activerecord.errors.messages.invalid"))
           end
         end
      end
    end

    # If there's no country code at all, pretend us
    # If there is a country code, the regex might still be nil....
    def postal_code_regex(country_code)
      return us_regex if country_code.nil?
      Country.postal_code_regex(country_code)
    end

    def valid_us_zip_code?(zip)
      us_regex =~ zip
    end

    def us_regex
      Country.postal_code_regex("US")
    end
    
    def validates_country(*config)
      validates_each(:country, *config) do |model, attr, country|
        model.errors.add(:country, I18n.t("activerecord.errors.custom.does_not_exist")) unless Country.active.include?(country)
      end
    end
    
    def validates_complete_us_address(*config)
      config ||= []
      config.insert(0, :address_line_1, :city, :state, :zip)
      validates_presence_of *config
    end
    
    def validates_complete_ca_address(*config)
      config ||= []
      config.insert(0, :address_line_1, :city, :state, :zip, :country)
      validates_presence_of *config
    end
    
    def validates_complete_international_address(*config)
      config ||= []
      config.insert(0, :address_line_1, :city, :zip, :country)
      validates_presence_of *config
    end
    
    def validates_state(*config)
      validates_each(:state, *config) do |model, attr, state|
        if model.country.try(:us?)
          model.errors.add(:state, I18n.t("activerecord.errors.messages.invalid")) unless Addresses::Codes::US::STATE_CODES.include?(state)
        elsif model.country.try(:ca?)
          model.errors.add(:state, I18n.t("activerecord.errors.messages.invalid")) unless Addresses::Codes::CA::STATE_CODES.include?(state)
        end
      end
    end
    
    def add_to_config(config, options)
      config ||= []
      config[0] ||= {}
      options.each { |k,v| config[0][k] = v }
      config
    end
    
    # Uses the model''s country code to determine how to validate zip
    def validates_zip_code(*config)
      validates_each(:zip_code, *config) do |model, attr, zip|
         if zip.present?
           regex = postal_code_regex(model.country_code)
           if regex.present?
             unless regex =~ zip
               model.errors.add(attr, I18n.t("activerecord.errors.messages.invalid"))
             end
           end
         end
      end
    end
    
  end
end
