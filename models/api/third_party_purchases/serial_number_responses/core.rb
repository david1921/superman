module Api::ThirdPartyPurchases::SerialNumberResponses::Core

  def to_xml
    Nokogiri::XML::Builder.new do |xml|
      if @request.success?
        success_xml(xml)
      else
        error_xml(xml)
      end
    end.to_xml
  end


  private

  def success_xml(xml)
    xml.voucher_responses {
      xml.qty_remaining @request.deal_qty_remaining

      @request.vouchers.each do |v|
        xml.voucher_response(:sequence => v.sequence) {
          xml.serial_number v.serial_number
          xml.bar_code {
            xml.value v.bar_code
            xml.format v.bar_code_symbology
          }
        }
      end
    }
  end

  def error_xml(xml)
    xml.errors {
      sold_out_error(xml)
      validation_errors(xml)
    }
  end

  def sold_out_error(xml)
    if @request.deal_sold_out? || @request.errors[:availability]
      xml.error {
        xml.code "2"
        xml.text_ "The deal is sold out"
      }
    end
  end

  def validation_errors(xml)
    unless @request.valid?
      xml.error {
        xml.code 3
        xml.text_ 'invalid request'
      }

      @request.errors.each do |k, v|
        xml.error {
          xml.code k
          xml.text_ v
        }
      end
    end
  end

end