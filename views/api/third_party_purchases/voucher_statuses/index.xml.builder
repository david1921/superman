xml.instruct!(:xml, :version => '1.0')

xml.voucher_statuses do
  @certificates.each do |cert|
    xml.voucher_status cert.status, :serial_number => cert.serial_number
  end
end
