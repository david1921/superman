module HasBitLyUrl
  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do
      after_save :initialize_bit_ly_url!
    end
  end

  module InstanceMethods
    def shorten_url_with_bit_ly(url)
      BitLyGateway.instance.shorten(url, bit_ly_login, bit_ly_api_key)
    end

    private

    def bit_ly_login
      bit_ly_api_credential_source.try(:bit_ly_login).if_present.try(:strip)
    end

    def bit_ly_api_key
      bit_ly_api_credential_source.try(:bit_ly_api_key).if_present.try(:strip)
    end

    def bit_ly_api_credential_source
      respond_to?(:advertiser) ? advertiser.try(:publisher) : publisher
    end

    def set_bit_ly_url
      #
      # Synchronous call to remote server. Should be a background batch job.
      #
      self.bit_ly_url = shorten_url_with_bit_ly(url_for_bit_ly)
    rescue Exception => e
      # This will never work in development and its very confusing to see the error message
      unless Rails.env.development?
        logger.warn "#{e}: Could not set bit.ly URL for #{self.class.name} #{id} #{url_for_bit_ly}"
      end
    end

    def initialize_bit_ly_url!
      return unless respond_to?(:url_for_bit_ly, true)

      #
      # Save only if bit_ly_url was set, to avoid infinite recursion via after_save if bit.ly gateway is unavailable.
      #
      if CREATE_BIT_LY_URLS && bit_ly_url.blank?
        set_bit_ly_url
        save false if bit_ly_url.present?
      end
      true
    end

  end
end
