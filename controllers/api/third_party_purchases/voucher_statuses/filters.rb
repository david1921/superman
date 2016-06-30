module Api::ThirdPartyPurchases::VoucherStatuses::Filters

  def load_certificates
    @certificates = find_certificates_by_serial_number(serial_numbers_from_request)
  end

end