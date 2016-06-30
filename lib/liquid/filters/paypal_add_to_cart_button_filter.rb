module Liquid
  module Filters
    module PaypalAddToCartButtonFilter
      def paypal_add_to_cart_button_fields(gift_certificate, custom_image = nil)
        paypal_add_to_cart_button(gift_certificate, custom_image)
      end
      
      def paypal_add_to_cart_button(gift_certificate, custom_image)
        image_src = custom_image ? custom_image : "https://www.paypal.com/en_US/i/btn/btn_cart_LG.gif"
        pp_fields = action_view.paypal_setup(gift_certificate.id, gift_certificate.price, controller.send(:paypal_business), gift_certificate.paypal_add_to_cart_parameters)
        pp_fields << %Q{<input type="image" src="#{ image_src }" border="0" name="submit" alt="PayPal - The safer, easier way to pay online!">}
        pp_fields << %Q{<img alt="" border="0" src="https://www.sandbox.paypal.com/en_US/i/scr/pixel.gif" width="1" height="1">}

        pp_fields
      end
      
      def controller
        @context.registers[:controller]
      end

      def action_view
        @context.registers[:action_view]
      end
    end
  end
end
