require 'base64'
require 'optimal_payments/configuration' 
require 'optimal_payments/web_service'

module OptimalPayments
  
  class InvalidCallbackMessage < ArgumentError; end
  
  def self.ensure_valid_callback_message!(options)
    raise ArgumentError, "missing required argument :encoded_message" unless options.has_key?(:encoded_message)
    raise ArgumentError, "missing required argument :signature" unless options.has_key?(:signature)
    
    encoded_message = options[:encoded_message]
    signature = options[:signature]
    
    decoded_message = Base64.decode64(encoded_message)
    expected_signature = hmac_sha1_signature(decoded_message, OptimalPayments::Configuration.private_key)
    
    raise InvalidCallbackMessage, options.inspect unless signature == expected_signature
  end
  
  def self.hmac_sha1_signature(message, key)
    Base64.encode64s(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), key, message))
  end 
    
  
  # Represents a base checkout request, this is using the
  # Checkout API.
  #
  # see:  http://www.support.optimalpayments.com/REPOSITORY/Checkout_API.pdf
  class BaseCheckoutRequest
  
    def self.verify_credentials!
      raise ArgumentError, "missing shop id" unless Configuration.shop_id
      raise ArgumentError, "missing private key" unless Configuration.private_key
    end
    
    def self.verify_required!( parameters, *required )
      return true if (required||[]).empty?
      missing = []
      required.each do |attr|
        unless parameters.include?( attr ) && parameters[attr].present?
          missing << attr
        end
      end
      raise ArgumentError, "missing required fields: #{missing.join(", ")}" unless missing.empty?
    end
    
    def self.verify_locale!( parameters = {} )
      locale = parameters[:locale]
      missing = []
      %w( language country ).each do |attr|
        unless locale.include?( attr )
          missing << attr
        end
      end
      raise ArgumentError, "missing locale fields: #{missing.join(", ")}" unless missing.empty?
    end
    
    def self.verify_customer_profile!( parameters = {} )
      customer_profile = parameters[:customer_profile]
      missing = []
      %w( merchant_customer_id is_new_customer ).each do |attr|
        unless customer_profile.include?( attr )
          missing << attr
        end
      end
      raise ArgumentError, "missing customer profile fields: #{missing.join(", ")}" unless missing.empty?      
    end
              
  end
  
  # ProfileCheckoutRequest
  #
  # Aids in the building of the profile checkout request.
  class ProfileCheckoutRequest < BaseCheckoutRequest
    
    @@default_values = {
      :payment_method => "CC",
      :currency_code  => "USD",
      :locale => {
        :language => "en",
        :country  => "US"
      } 
    }
    
    def self.url
      "#{Configuration.base_url}/profileCheckoutRequest.htm"
    end
    
    # Returns an array that contains the encoded_message and signature
    # for the given parameters.
    #
    # Parameters can be:
    # {
    #   :merchant_ref_num => "hell0", 
    #   :return_url => "the url to return must be secure",
    #   :cancel_url => "the url to return the customer if they cancel", 
    #   :payment_method => "CC",                                            # default is CC
    #   :currency_code => "GBP",                                            # default is USD
    #   :shopping_cart => [                                                 # is optional
    #     {
    #       :description => "item description",
    #       :amount      => "line item total",
    #       :quantity    => "item quantity"      
    #     }
    #   ]
    #   :total_amount => "100.00", 
    #   :customer_profile => {
    #     :merchant_customer_id => "123", 
    #     :is_new_customer => false
    #   },
    #   :locale => {                                                        # default is en-US
    #     :language => "en",
    #     :country  => "US"
    #   }  
    # }    
    def self.encoded_message_and_signature( parameters = {} )
      verify_credentials!
      
      xml             = xml( parameters )
      encoded_message = Base64.encode64( xml )
      signature       = signature( xml, Configuration.private_key )
      
      [encoded_message, signature]
    end
    
    def self.signature( xml, private_key )           
      ::OptimalPayments.hmac_sha1_signature(xml, private_key)
    end
     
    # Responsible for generating the XML for the signature.
    def self.xml( parameters = {} )
     
            
      parameters = @@default_values.merge( parameters ).with_indifferent_access
      verify_required!          parameters, :merchant_ref_num, :return_url, :cancel_url, :currency_code, :total_amount
      verify_locale!            parameters 
      verify_customer_profile!  parameters
      
      message = ""
      xml = Builder::XmlMarkup.new(:target => message)
      xml.instruct! :xml, :version => '1.0', :encoding => 'ISO-8859-1'
      xml.profileCheckoutRequest :xmlns => 'www.optimalpayments.com/checkout' do |profile|
        
        profile.merchantRefNum parameters[:merchant_ref_num]
        profile.returnUrl :page => parameters[:return_url]
        profile.cancelUrl :page => parameters[:cancel_url]
        profile.paymentMethod parameters[:payment_method]
        profile.currencyCode parameters[:currency_code]
        
        if parameters[:shopping_cart]
          profile.shoppingCart do |cart|
            parameters[:shopping_cart].each do |item|
              cart.description item[:description]
              cart.quantity    item[:quantity] if item[:quantity]
              cart.amount      item[:amount].to_s              
            end
          end
        end 
         
        profile.totalAmount parameters[:total_amount].to_s
        
        customer_profile = parameters[:customer_profile]
        profile.customerProfile do |customer|
          customer.merchantCustomerId customer_profile[:merchant_customer_id]
          customer.isNewCustomer      customer_profile[:is_new_customer] ? "true" : "false"
        end
        
        locale = parameters[:locale]
        profile.locale do |l|
          l.language locale[:language]
          l.country  locale[:country]
        end 
        
        
      end 
      message      
    end
    
  end
  
  class ProfileCheckoutResponse
    
    def initialize(options)
      OptimalPayments.ensure_valid_callback_message! options

      @encoded_message = options[:encoded_message]
      @signature = options[:signature]
      @decoded_message = Base64.decode64(@encoded_message)
      @parsed_xml = Nokogiri.parse(@decoded_message)
    end
    
    def process!
      ddp = DailyDealPurchase.find_by_uuid(merchant_ref_num)
      raise "couldn't find DailyDealPurchase with UUID #{merchant_ref_num}" unless ddp.present?

      if payment_accepted?
        ddp.capture_optimal_payment_and_send_certificates! self
      elsif payment_declined?
        # currently just a noop
      end
    end
    
    def txn_time
      get_value_for "txnTime"
    end

    def confirmation_number
      get_value_for "confirmationNumber"
    end
    
    def last_four_digits
      get_value_for "lastFourDigits"
    end
    
    def merchant_ref_num
      get_value_for "merchantRefNum"
    end
    
    def decision
      get_value_for("decision")
    end
    
    def payment_accepted?
      decision.upcase == "ACCEPTED"
    end
    
    def payment_declined?
      decision.upcase == "DECLINED"
    end
    
    def to_s
      "#<ProfileCheckoutResponse id: #{id}, decision: #{decision}, confirmation_number: #{confirmation_number}, merchant_ref_num: #{merchant_ref_num}>"
    end
    
    private
    
    def get_value_for(field)
      @parsed_xml.css(field).first.content
    rescue
      nil
    end
    
  end
    
end