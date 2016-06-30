module Travelsavers
  class BookingRequestForm
    KEY_FILENAME = File.join(Rails.root, "config/travelsavers/encryption.key")

    def initialize(daily_deal_purchase, redirect_url)
      @daily_deal_purchase = daily_deal_purchase
      @redirect_url = redirect_url
    end

    def transaction_data
      key, data = self.class.key, secure_parameters.to_query
      hmac_signature = Travelsavers::BookingRequest.hmac_signature(key, data)
      [hmac_signature, data].join('|')
    end

    class << self
      def key
        @@key ||= File.read(KEY_FILENAME)
      end
    end

    private

    def secure_parameters
      {
          :ts_product_id => ts_product_id,
          :redirect_url => @redirect_url,
          :purchase_price => purchase_price.to_s,
          :aa_purchase_id => @daily_deal_purchase.uuid
      }
    end

    def purchase_price
      @daily_deal_purchase.actual_purchase_price
    end

    def ts_product_id
      @daily_deal_purchase.travelsavers_product_code
    end

  end
end