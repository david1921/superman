module ThirdPartyDealsApi
  module XML
    
    class InvalidVoucherStatusResponse < Exception; end

    class VoucherStatusResponse
      
      attr_reader :error_messages

      def initialize(purchase, response_xml)
        @purchase = purchase
        @response_xml = response_xml
        @xml_doc = Nokogiri::XML(@response_xml) 
        @error_messages = []
      end

      def to_voucher_status_response_hash(validate = true)
        return @response_hash if @response_hash
        @response_hash = create_response_hash
        validate_status_response if validate
        @response_hash
      end

      def status_from_response!(cert)
        new_status = to_voucher_status_response_hash["statuses"][cert.serial_number]
        raise InvalidVoucherStatusResponse, "third party deal voucher status missing serial number #{cert.serial_number}" if new_status.nil?
        new_status = new_status.downcase
        new_status
      end
      
      def valid?
        @error_messages = []
        validate_status_response
        @error_messages.blank?
      end
      
      def valid_and_internal_statuses_match_external_statuses?
        return false unless valid?
        validate_internal_statuses_match_external_statuses
        @error_messages.blank?
      end
      
      def error_messages_with_xml
        return if @error_messages.blank?
        "#{@error_messages.join(', ')}. XML: #{@response_xml}"
      end

      private
      
      def response_listing
        @response_listing ||= @xml_doc.css("voucher_status_response").attr('listing').text rescue ''
      end
      
      def response_purchase_id
        @response_purchase_id ||= @xml_doc.css('voucher_status_response').attr('purchase_id').text rescue ''
      end
      
      def create_response_hash
        response_hash = {}
        doc = Nokogiri::XML(@response_xml).remove_namespaces!
        doc.root.attributes.each_pair do |key, value|
          response_hash[key] = value.content
        end
        response_hash['statuses'] = Hash.new
        doc.root.xpath('status').each do |status|
          response_hash['statuses'][status['serial_number']] = status.content
        end
        response_hash
      end
      
      def validate_status_response_for_refund
        validate_status_response
        validate_all_serial_numbers_refunded
      end
      
      def validate_internal_statuses_match_external_statuses
        expected_statuses = @purchase.daily_deal_certificates.map do |c|
          if c.voided?
            [c.serial_number, "refunded"]
          else
            [c.serial_number, c.status.downcase]
          end
        end.sort
        got_statuses = @xml_doc.css("status").map do |s|
          [s.attr('serial_number'), s.text.downcase]
        end.sort
        
        expected_statuses = [] if expected_statuses.blank?
        got_statuses = [] if got_statuses.blank?
        
        unless expected_statuses == got_statuses
          @error_messages << "unexpected serial number <-> status mappings in response. expected: #{expected_statuses.inspect}. got: #{got_statuses.inspect}"
        end
      end

      def validate_status_response
        validate_voucher_status_response_root_node_present
        return if @error_messages.present?
        
        validate_response_listing_matches_deal_listing
        validate_purchase_id_matches_internal_purchase_id
        validate_contains_serial_numbers
      end
      
      def validate_voucher_status_response_root_node_present
        unless @xml_doc.try(:root).try(:name) == "voucher_status_response"
          @error_messages << "missing required root element <voucher_status_response>"
        end
      end
      
      def validate_response_listing_matches_deal_listing
        expected_listing = @purchase.daily_deal.listing
        if response_listing != expected_listing
          @error_messages << "third party voucher status response has listing (#{response_listing}) that does not match daily_deal (#{expected_listing})"
        end
      end

      def validate_purchase_id_matches_internal_purchase_id
        expected_response_purchase_id = @purchase.uuid
        if response_purchase_id != expected_response_purchase_id
          @error_messages << "third party voucher status response has purchase_id (#{response_purchase_id}) that does not match daily_deal_purchase (#{expected_response_purchase_id})"
        end
      end
      
      def validate_contains_serial_numbers
        unless @xml_doc.css('status').present?
          @error_messages << "third party voucher response contains no serial numbers"
          return
        end        
      end
      
    end
  end
end
