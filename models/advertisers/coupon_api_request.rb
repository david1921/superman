module Advertisers::CouponApiRequest
  def self.included( base )
    base.send :include, InstanceMethods
    base.class_eval do
      attr_writer :advertiser_name
      attr_writer :advertiser_client_id
      attr_writer :advertiser_location_id
      attr_writer :advertiser_coupon_clipping_modes
      attr_writer :advertiser_website_url
      attr_writer :advertiser_logo
      attr_writer :advertiser_industry_codes
      attr_writer :advertiser_store_address_line_1
      attr_writer :advertiser_store_address_line_2
      attr_writer :advertiser_store_city
      attr_writer :advertiser_store_state
      attr_writer :advertiser_store_zip
      attr_writer :advertiser_store_phone_number 
      attr_reader :error           
    end
  end
  
  module InstanceMethods
    def find_or_initialize_advertiser
      returning publisher.advertisers.find_or_initialize_by_listing_parts(@advertiser_client_id, @advertiser_location_id) do |advertiser|
        advertiser_attributes = returning({}) do |hash|
          %w{ name website_url logo }.each do |attr|
            hash[attr] = instance_eval("@advertiser_#{attr}") unless instance_eval("@advertiser_#{attr}").nil?
          end
        end
        unless @advertiser_coupon_clipping_modes.nil?
          coupon_clipping_modes = @advertiser_coupon_clipping_modes.to_s.split(",").map(&:strip).reject { |mode| "call" == mode }
          advertiser_attributes['coupon_clipping_modes'] = coupon_clipping_modes
        end
        advertiser.reload unless advertiser.new_record?
        advertiser.attributes = advertiser_attributes

        store_attributes = returning({}) do |hash|
          %w{ address_line_1 address_line_2 city state zip phone_number }.each do |attr|
            hash[attr] = instance_eval("@advertiser_store_#{attr}") unless instance_eval("@advertiser_store_#{attr}").nil?
          end
        end
        if store_attributes.present?
          default_country = Country::US
          if advertiser.store
            advertiser.store.country = default_country
            advertiser.store.update_attributes store_attributes
          else
            store = advertiser.stores.build store_attributes
            store.advertiser = advertiser
            store.country = default_country
          end
        end
      end
    end
    
    def find_advertiser
      publisher.advertisers.find_by_listing_parts(@advertiser_client_id, @advertiser_location_id)
    end
    
    def error_from_advertiser(advertiser)
      case
      when messages = advertiser_error(advertiser, :website_url)
        ApiRequest::ParameterValidationError.new(:advertiser_website_url, messages)
      when messages = store_error(advertiser, :address_line_1)
        ApiRequest::ParameterValidationError.new(:advertiser_store_address_line_1, messages)
      when messages = store_error(advertiser, :city)
        ApiRequest::ParameterValidationError.new(:advertiser_store_city, messages)
      when messages = store_error(advertiser, :state)
        ApiRequest::ParameterValidationError.new(:advertiser_store_state, messages)
      when messages = store_error(advertiser, :zip), messages = store_error(advertiser, :zip_code)
        ApiRequest::ParameterValidationError.new(:advertiser_store_zip, messages)
      when messages = store_error(advertiser, :phone_number)
        ApiRequest::ParameterValidationError.new(:advertiser_store_phone_number, messages)
      else
        message   = advertiser.errors.full_messages.first
        message ||= advertiser.store.errors.full_messages.first
        message ||= "Unknown error"
        ApiRequest::UnattributedError.new(message)
      end
    end

    # advertiser_error and store_error are error message sanitizing helpers for
    # switch statements like above in error_from_advertiser
    def advertiser_error(advertiser, attr)
      sanitize_error_messages(advertiser.errors.on(attr), attr)
    end

    def store_error(advertiser, attr)
      sanitize_error_messages(advertiser.store.errors.on(attr), attr)
    end
    
    # This method sanitizes an error message or a collection of error messages.
    def sanitize_error_messages(errors = nil, attr = nil)
      if errors && errors.is_a?(Array) && errors.size > 1
        errors.map do |m|
          sanitize_message(m, attr)
        end
      else
        sanitize_message(errors, attr)
      end
    end

    # Sanitizing a message means removing the interpolated attribute from the
    # error message. Errors such as :invalid have "%{attribute} is invalid"
    # so the resulting errors.on(:attr) returns "Attr is invalid". With this
    # method we can remove "Attr" from the message so error messages stay
    # consistent with how the API has been defined. 
    def sanitize_message(messages, attr)
      unless messages.blank?
        if messages.include?(attr.to_s.humanize)
          messages.split(attr.to_s.humanize).join("").strip
        else
          messages
        end
      end
    end
  end
end
