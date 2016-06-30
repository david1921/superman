module GiftCertificatesHelper
  def render_sale_opens_at( gift_certificate )
    unless gift_certificate.nil? || gift_certificate.show_on.nil?
      gift_certificate.show_on.to_s(:sale_opens_at)      
    else
      ""
    end
  end
end
