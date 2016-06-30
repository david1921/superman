module Drop
    
  class GiftCertificate < Liquid::Drop
    include PaypalHelper
    include ActionView::Helpers::NumberHelper
    include ActionController::UrlWriter
    include CouponsHelper
    
    delegate :id,
             :advertiser_name,
             :value,
             :address,
             :item_name,
             :price,
             :active?,
             :available?,
             :handling_fee?,
             :handling_fee,
             :address_required?,
             :description,
             :terms,
             :available_count,
             :message,
             :facebook_description,
             :featured_gift_certificate_enabled?,
             :to => :gift_certificate
                
    def initialize(gift_certificate)
      @gift_certificate = gift_certificate
    end
    
    def advertiser
      Drop::Advertiser.new(gift_certificate.advertiser)
    end
     
    def paypal_url
      Paypal::Notification.ipn_url
    end
    
    def paypal_return_url
      controller.request.headers['HTTP_REFERER']
    end
    
    def medium_logo_url
      gift_certificate.logo(:medium)
    end
    
    def advertiser_facebook_logo_url
      gift_certificate.advertiser.logo(:facebook)
    end
     
    def paypal_add_to_cart_parameters
       parameters = {
        :currency_code => publisher.currency_code,
        :cmd => "_cart",
        :add => "1",
        :custom => "PURCHASED_GIFT_CERTIFICATE",
        :rm => "2",
        :charset => "utf-8",
        :currency_code => "USD",
        :redirect_cmd => "_cart",
        :no_note => "1",
        :quantity => "1",
        :no_shipping => address_required? ? 2 : 1,
        :invoice => "#{id}-#{Time.now.to_i}",
        :cpp_header_image => paypal_checkout_header_image_url(@gift_certificate).to_s,
        :business => controller.send(:paypal_business),
        :return => paypal_return_url,
        :cancel_return => paypal_return_url,
        :item_name => item_name,
      }
      parameters.merge!(%w{ development test }.include?(Rails.env) ? {} : {
          :business_key => controller.send(:paypal_business_key),
          :business_cert => controller.send(:paypal_business_crt),
          :business_certid => controller.send(:paypal_business_crtid)
        })   
      parameters.merge!(:handling => number_with_precision( handling_fee, :precision => 2)) if handling_fee?
      parameters.merge!(:notify_url => AppConfig.paypal_notify_url ) if AppConfig.respond_to?( :paypal_notify_url )
      parameters
    end
    
    def paypal_add_to_cart_parameter_names
      paypal_add_to_cart_parameters.keys
    end

    def multi_loc_map_image_url
      map_image_url_for gift_certificate, "199x169", true
    end
    
    def facebook_path
      facebook_gift_certificate_path :id => id
    end
    
    
    def twitter_path
      twitter_gift_certificate_path :id => id
    end
    
    protected
    
    def controller
      @context.registers[:controller]
    end
    
    def action_view
      @context.registers[:action_view]
    end
    
    attr_reader :gift_certificate
    
  end
  
end
