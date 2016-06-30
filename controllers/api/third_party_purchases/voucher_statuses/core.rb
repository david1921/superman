module Api::ThirdPartyPurchases::VoucherStatuses::Core

  def update_certificate_statuses(certificates)
    statuses = voucher_statuses_from_xml(request_body)

    certificates.each do |certificate|
      begin
        certificate.set_status!(statuses[certificate.serial_number])
      rescue
        log_status_change_error(certificate, statuses[certificate.serial_number])
      end
    end
  end

  # Returns Hash: { serial number => status, ... }
  def voucher_statuses_from_xml(xml)
    doc = Nokogiri::XML(xml)
    {}.tap do |hash|
      doc.search('voucher_status').each do |vs|
        hash[vs.attr('serial_number')] = vs.content.strip
      end
    end
  end

  def find_certificates_by_serial_number(serial_numbers)
    DailyDealCertificate.find_all_by_serial_number(serial_numbers)
  end

  def serial_numbers_from_request
    if request.post?
      voucher_statuses_from_xml(request_body).keys
    else
      params[:serial_numbers]
    end
  end

  def request_body
    @request_body ||= request.body.read # can only be read once
  end

  private

  def log_status_change_error(certificate, status)
    Rails.logger.error "Couldn't change status of #{certificate.serial_number} to #{status}: #{$!.message}"
  end


end