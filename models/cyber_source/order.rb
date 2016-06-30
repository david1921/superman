module CyberSource
  class Order
    RETRY_TYPE_FROM_REASON_CODE = {
      104 => :duplicate_charge,
      150 => :reenter_old_card,
      151 => :contact_support,
      152 => :contact_support,
      200 => :reenter_old_card,
      201 => :contact_support,
      202 => :request_new_card,
      203 => :request_new_card,
      204 => :request_new_card,
      205 => :request_new_card,
      207 => :reenter_old_card,
      208 => :request_new_card,
      210 => :request_new_card,
      211 => :reenter_old_card,
      220 => :contact_support,
      221 => :contact_support,
      222 => :contact_support,
      230 => :reenter_old_card,
      231 => :reenter_old_card,
      232 => :request_new_card,
      233 => :request_new_card,
      234 => :contact_support,
      236 => :reenter_old_card,
      240 => :reenter_old_card,
      250 => :contact_support,
      520 => :reenter_old_card
    }
    CARD_CODE_FROM_TYPE = {
      :visa => "001",
      :master_card => "002",
      :amex => "003",
      :discover => "004"
    }
    PARAM_FROM_ATTR = {
      :billing_first_name => "billTo_firstName",
      :billing_last_name => "billTo_lastName",
      :billing_address_line_1 => "billTo_street1",
      :billing_address_line_2 => "billTo_street2",
      :billing_city => "billTo_city",
      :billing_state => "billTo_state",
      :billing_postal_code => "billTo_postalCode",
      :billing_country => "billTo_country",
      :billing_email => "billTo_email",
      :card_type => "card_cardType",
      :card_number => "card_accountNumber",
      :card_expiration_month => "card_expirationMonth",
      :card_expiration_year => "card_expirationYear",
      :card_cvv => "card_cvNumber",
      :decision => "decision",
      :amount => "orderAmount",
      :currency => "orderCurrency",
      :type => "orderPage_transactionType",
      :request_id => "requestID",
      :reconciliation_id => "reconciliationID",
      :authorization_timestamp => "ccAuthReply_authorizedDateTime",
      :reason_code => "reasonCode"
    }
    ATTR_FROM_PARAM = PARAM_FROM_ATTR.invert
    
    attr_reader :created_at, :errors, *(PARAM_FROM_ATTR.keys - [:reason_code, :authorization_timestamp])
    
    alias_method :to_s, :inspect
    
    def self.param_name(attr)
      PARAM_FROM_ATTR[attr]
    end
    
    def initialize(attrs_or_params = {})
      @created_at = Time.now
      @errors = HashWithIndifferentAccess.new.tap do |errors|
        attrs_or_params.each_pair do |key, val|
          attr = PARAM_FROM_ATTR[key] ? key : ATTR_FROM_PARAM[key] 
          instance_variable_set :"@#{attr}", val if attr

          if key.to_s =~ /^(Missing|Invalid)Field\d+$/
            attr = ATTR_FROM_PARAM[val.to_s.strip]
            errors[attr] = $1.downcase.to_sym if attr
          end
        end
      end
      class << @errors
        alias_method :on, :[]
      end
    end
    
    def id
      nil
    end
    
    def success?
      ["ACCEPT", "REVIEW"].include?(@decision)
    end
    
    def failure?
      ["ERROR", "REJECT"].include?(@decision)
    end
    
    def authorized_at
      DateTime.strptime(@authorization_timestamp.to_s, "%Y-%m-%dT%H%M%SZ") rescue @created_at
    end
    
    def card_last_4
      @card_number[-4..-1]
    end
    
    def credit_card_bin
      @card_number[0..5]
    end

    def error_messages
      if [101, 102].include?(reason_code)
        @errors.map { |key, val| "#{I18n.t("cyber_source.order.#{key}")} #{I18n.t("cyber_source.error.was_#{val}")}" }
      elsif @reason_code.present?
        [I18n.t("cyber_source.reason_code.code_#{reason}")]
      else
        []
      end
    end
    
    def retry_type
      retry_type = RETRY_TYPE_FROM_REASON_CODE[reason_code] || :reenter_old_card
    end
    
    def clear_card_attributes
      [:card_type, :card_number, :card_expiration_month, :card_expiration_year, :card_cvv].each { |attr| instance_variable_set :"@#{attr}", nil }
    end
    
    private
    
    def reason_code
      @reason_code.to_i
    end
    
    def reason
      RETRY_TYPE_FROM_REASON_CODE.has_key?(reason_code) ? @reason_code : "unrecognized"
    end
  end
end
