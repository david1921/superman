module Api::ThirdPartyPurchases::SerialNumberRequests::Xml
  module Validations

    def validate_xml_root(doc)
      if doc.root.nil? || (doc.root.name != 'daily_deal_purchase')
        errors.add(:xml, "document root is not <daily_deal_purchase>")
      end
    end

    def validate_xml_uuid(doc)
      if doc.root && doc.root.attr('uuid').blank?
        errors.add(:xml, "document root is missing 'uuid' attribute")
      end
    end

    def validate_xml_purchase_elements(doc)
      if node = doc.root
        validate_xml_presence(:daily_deal_listing, node)
        validate_xml_presence(:executed_at, node)
        validate_xml_presence(:gross_price, node)
        validate_xml_presence(:actual_purchase_price, node)
        validate_xml_presence(:voucher_requests, node)
        validate_xml_voucher_requests(node)
      end
    end

    def validate_xml_voucher_requests(node)
      vouchers_requests = node.search('voucher_request')
      if vouchers_requests.empty?
        errors.add(:xml, [:voucher_request, :missing])
      else
        vouchers = vouchers_requests.each do |v|
          validate_voucher(v)
        end
      end
    end

    def validate_voucher(node)
      validate_xml_presence(:redeemer_name, node)
      validate_xml_sequence(node)
    end

    def validate_xml_presence(attr, node)
      matches = node.search(attr.to_s)
      if matches.empty?
        errors.add(:xml, "#{attr} is missing")
      elsif matches.first.content.blank?
        errors.add(:xml, "#{attr} cannot be blank")
      end
    end

    def validate_xml_redeemer_name(node)
      name = node.search('redeemer_name')
      if name.empty?
        errors.add(:xml, [:redeemer_name, :missing])
      elsif name.first.content.blank?
        errors.add(:xml, [:redeemer_name, :blank])
      end
    end

    def validate_xml_sequence(node)
      sequence = node.attr('sequence')
      if sequence.nil?
        errors.add(:xml, [:sequence, :missing])
      elsif sequence == ''
        errors.add(:xml, [:sequence, :blank])
      elsif sequence !~ /^\d+$/
        errors.add(:xml, [:sequence, :invalid])
      end
    end

  end
end