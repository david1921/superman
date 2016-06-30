module ThirdPartyDealsApi
  module XML

    class InvalidSerialNumberResponse < Exception
    end
    
    class SerialNumberResponse
      
      attr_reader :error_messages
      
      def initialize(daily_deal_purchase, serial_number_response_xml)
        @daily_deal_purchase = daily_deal_purchase
        @serial_number_response_xml = serial_number_response_xml
        @error_messages = []
        @xml_doc = Nokogiri::XML(@serial_number_response_xml) 
      end
      
      def serial_numbers
        @serial_numbers ||= @xml_doc.css("serial_number").map(&:text)
      end
      
      def valid?
        @error_messages = []
        validate_serial_number_response
        @error_messages.blank?
      end
      
      def error_messages_with_xml
        return if valid?
        "#{@error_messages.join(', ')}. XML: #{@serial_number_response_xml}"
      end
      
      def sold_out_status_present?
        @deal_sold_out ||= @xml_doc.css("errors error[code='2']").present?
      end
      
      def deal_force_closed_status_present?
        @deal_force_closed_status_present ||= @xml_doc.css("errors error[code='4']").present?
      end
      
      def validate_serial_number_response
        return unless @xml_doc.present?

        validate_presence_of_serial_numbers_root_element
        unless deal_force_closed_status_present?
          validate_presence_of_one_or_more_serial_number_elements
          validate_number_of_serials_returned_matches_purchase_quantity
        end
      end
      
      def validate_presence_of_serial_numbers_root_element
        unless @xml_doc.try(:root).try(:name) == "serial_numbers"
          @error_messages << "Missing required root element serial_numbers."
        end
      end
      
      def validate_presence_of_one_or_more_serial_number_elements
        unless @xml_doc.css("serial_numbers serial_number").present?
          @error_messages << "Missing required element serial_number."
        end
      end
      
      def validate_number_of_serials_returned_matches_purchase_quantity
        expected_quantity = @daily_deal_purchase.quantity
        actual_quantity = @xml_doc.css("serial_numbers serial_number").length
        unless actual_quantity == expected_quantity
          @error_messages << "Wrong number of serial numbers returned by api call. Expected #{expected_quantity}, got #{actual_quantity}."
        end
      end
      
    end
    
  end
end