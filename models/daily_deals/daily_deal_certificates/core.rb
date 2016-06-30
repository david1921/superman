module DailyDealCertificates
  module Core

    def hide_serial_number?
      hide_serial_number_if_bar_code_is_present? && bar_code.present?
    end

    def as_json(options={})
      cert_hash = {
        :serial_number => hide_serial_number? ? "" : serial_number,
        :status => status
      }
      
      cert_hash[:redeemed_at] = redeemed_at.to_s(:iso8601) if redeemed?

      cert_hash[:connections] = {
        :bar_code =>
        daily_deal_purchase_bar_code_url(
          :daily_deal_purchase_id => daily_deal_purchase.to_param,
          :id => serial_number, :host => AppConfig.api_host,
          :format => "jpg")
      }

      if store.present?
        cert_hash[:location] = {
          "name" => advertiser.name,
          "address_line_1" => store.address_line_1,
          "address_line_2" => store.address_line_2,
          "city" => store.city,
          "state" => store.state,
          "zip" => store.zip,
          "country" => store.country.try(:code),
          "phone_number" => store.phone_number,
          "latitude" => store.latitude,
          "longitude" => store.longitude
        }
      end

      cert_hash
    end

  end
end
