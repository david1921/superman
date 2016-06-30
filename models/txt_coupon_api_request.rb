class TxtCouponApiRequest < ApiRequest
  include Advertisers::CouponApiRequest
  
  belongs_to :txt_offer
  
  attr_writer :txt_coupon_label
  attr_writer :txt_coupon_keyword
  attr_writer :txt_coupon_message
  attr_writer :txt_coupon_appears_on
  attr_writer :txt_coupon_expires_on
  attr_writer :_method
  
  before_validation_on_create :find_or_create_associated_advertiser_and_txt_offer
  before_validation_on_create :delete_associated_txt_offer
  
  private
  
  def find_or_create_associated_advertiser_and_txt_offer
    unless "deleted" == @_method
      if attr = %w{ advertiser_client_id advertiser_location_id txt_coupon_label }.detect { |attr| instance_eval("@#{attr}").blank? }
        @error = ApiRequest::ParameterValidationError.new(attr, "must be present")
      else
        advertiser = find_or_initialize_advertiser    
        if !advertiser.save
          @error = error_from_advertiser(advertiser)
        else
          txt_offer = find_or_build_txt_offer_for_advertiser(advertiser)
          if txt_offer.save
            self.txt_offer = txt_offer
          else      
            @error = error_from_txt_offer(txt_offer)
          end
        end
      end
    end
    @error.nil?    
  end 
  
  def delete_associated_txt_offer
    if "delete" == @_method
      if attr = %w{ advertiser_client_id advertiser_location_id txt_coupon_label }.detect { |attr| instance_eval("@#{attr}").blank? }
        @error = ApiRequest::ParameterValidationError.new(attr, "must be present")
      elsif (advertiser = find_advertiser).nil?
        @error = ApiRequest::ParameterValidationError.new(:advertiser_client_id, "doesn't exist")
      elsif (txt_offer = advertiser.txt_offers.find_by_label(@txt_coupon_label)).nil?
        @error = ApiRequest::ParameterValidationError.new(:txt_coupon_label, "doesn't exist")
      else
        txt_offer.delete!
        self.txt_offer = txt_offer
      end
    end
    @error.nil?
  end
  
  def error_from_txt_offer(txt_offer)
    case
    when messages = txt_offer_error(txt_offer, :message)
      ApiRequest::ParameterValidationError.new(:txt_coupon_message, messages)
    when messages = txt_offer_error(txt_offer, :label)
      ApiRequest::ParameterValidationError.new(:txt_coupon_label, messages)
    when messages = txt_offer_error(txt_offer, :keyword)
      ApiRequest::ParameterValidationError.new(:txt_coupon_keyword, messages)
    else
      message   = txt_offer.errors.full_messages.first
      message ||= "Unknown error"
      ApiRequest::UnattributedError.new(message)
    end
  end

  # txt_offer_error is a sanitizing helper. For more details on sanitizing
  # please look at app/models/advertiser/coupon_api_request.rb
  def txt_offer_error(txt, attr)
    sanitize_error_messages(txt.errors.on(attr), attr)
  end

  def find_or_build_txt_offer_for_advertiser(advertiser)
    returning advertiser.txt_offers.find_or_initialize_by_label(@txt_coupon_label) do |txt_offer|
      txt_offer.reload unless txt_offer.new_record?
      txt_offer.attributes = returning({}) do |hash|
        %w{ keyword message appears_on expires_on }.each do |attr|
          hash[attr] = instance_eval("@txt_coupon_#{attr}") unless instance_eval("@txt_coupon_#{attr}").nil?
        end
      end
      txt_offer.deleted = false
    end
  end
end
