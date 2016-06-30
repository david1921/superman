module DailyDealPurchases::PDF

  def daily_deal_certificates_pdf(certificates = daily_deal_certificates.active)
    if custom_voucher_template_exists?
      render_all_vouchers_in_one_pdf_with_custom_lay_out(certificates)
    else
      render_all_vouchers_in_one_pdf_with_standard_lay_out(certificates)
    end
  end


  private

  def render_all_vouchers_in_one_pdf_with_custom_lay_out(certificates)
    certificate_bodies = ""
    certificates.each_with_index do |cert, i|
      certificate_bodies << cert.custom_lay_out_as_html_snippet(:page_break => i != 0)
    end
    PDFKit.new(ERB.new(custom_voucher_template_layout).result(binding), :page_size => 'Letter').to_pdf
  ensure
    certificates.each do |cert|
      File.unlink(cert.barcode_jpg_file_path) if File.exists?(cert.barcode_jpg_file_path)
    end
  end

  def render_all_vouchers_in_one_pdf_with_standard_lay_out(certificates)
    Prawn::Document.new(:page_size => "LETTER") do |pdf|
      certificates.each_with_index do |daily_deal_certificate, i|
        pdf.start_new_page if i > 0
        daily_deal_certificate.standard_lay_out_with_prawn pdf
      end
    end.render
  end

end
