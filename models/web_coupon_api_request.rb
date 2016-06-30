class WebCouponApiRequest < ApiRequest
  include Advertisers::CouponApiRequest

  belongs_to :offer

  attr_writer :web_coupon_label
  attr_writer :web_coupon_message
  attr_writer :web_coupon_terms
  attr_writer :web_coupon_txt_message
  attr_writer :web_coupon_image
  attr_writer :web_coupon_show_on
  attr_writer :web_coupon_expires_on
  attr_writer :web_coupon_featured
  attr_writer :_method
  
  before_validation_on_create :find_or_create_associated_advertiser_and_offer
  before_validation_on_create :delete_associated_offer
  
  private
  
  def find_or_create_associated_advertiser_and_offer
    unless "delete" == @_method
      if attr = %w{ advertiser_client_id advertiser_location_id web_coupon_label }.detect { |attr| instance_eval("@#{attr}").blank? }
        @error = ApiRequest::ParameterValidationError.new(attr, "must be present")
      else
        #
        # Ensuing saves will be rolled back if this method returns false.
        #
        advertiser = find_or_initialize_advertiser
        if advertiser.new_record? && !advertiser.save
          @error = error_from_advertiser(advertiser)
        end
        if @error.nil?
          offer = find_or_build_offer_for_advertiser(advertiser)
          if offer.save
            self.offer = offer
          else
            @error = error_from_offer(offer)
          end
        end
        if @error.nil? && !advertiser.save
          @error = error_from_advertiser(advertiser)
        end
      end
    end
    @error.nil?
  end

  def delete_associated_offer
    if "delete" == @_method
      #
      # Ensuing saves will be rolled back if this method returns false.
      #
      if attr = %w{ advertiser_client_id advertiser_location_id web_coupon_label }.detect { |attr| instance_eval("@#{attr}").blank? }
        @error = ApiRequest::ParameterValidationError.new(attr, "must be present")
      elsif (advertiser = find_advertiser).nil?
        @error = ApiRequest::ParameterValidationError.new(:advertiser_client_id, "doesn't exist")
      elsif (offer = advertiser.offers.find_by_label(@web_coupon_label)).nil?
        @error = ApiRequest::ParameterValidationError.new(:web_coupon_label, "doesn't exist")
      else
        offer.delete!
        self.offer = offer
      end
    end
    @error.nil?
  end

  def error_from_offer(offer)
    case
    when messages = offer.errors.on(:message)
      ApiRequest::ParameterValidationError.new(:web_coupon_message, messages)
    when messages = offer.errors.on(:txt_message)
      ApiRequest::ParameterValidationError.new(:web_coupon_txt_message, messages)
    when messages = offer.errors.on(:show_on)
      ApiRequest::ParameterValidationError.new(:web_coupon_show_on, messages)
    when messages = offer.errors.on(:featured)
      ApiRequest::ParameterValidationError.new(:web_coupon_featured, messages)
    else
      message   = offer.errors.full_messages.first
      message ||= offer.store.errors.full_messages.first
      message ||= "Unknown error"
      ApiRequest::UnattributedError.new(message)
    end
  end
  
  def find_or_build_offer_for_advertiser(advertiser)
    returning advertiser.offers.find_or_initialize_by_label(@web_coupon_label) do |offer|
      offer.reload unless offer.new_record?
      offer.attributes = returning({}) do |hash|
        %w{ message terms txt_message show_on expires_on featured }.each do |attr|
          hash[attr] = instance_eval("@web_coupon_#{attr}") unless instance_eval("@web_coupon_#{attr}").nil?
        end
      end 
      offer.value_proposition = offer.message
      offer.photo = @web_coupon_image unless @web_coupon_image.nil?
      offer.category_names = @advertiser_industry_codes unless @advertiser_industry_codes.nil?
      offer.deleted_at = nil
    end
  end
end
