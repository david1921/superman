module Travelsavers
  
  class BookTransaction
    
    attr_reader :checkout_form_values, :validation_errors, :vendor_booking_errors,
                :ts_tx_retrieval_errors, :vendor_booking_retrieval_errors,
                :fixable_errors, :unfixable_errors, :xml_source,
                :service_start_date, :service_end_date
    
    TS_BOOK_TRANSACTION_URL_TEMPLATE = "https://bookingservices.travelsavers.com/productservice.svc/REST/BookingTransaction?TransactionID=%s"
    TS_BASIC_AUTH_USERNAME = "psclient"
    TS_BASIC_AUTH_PASSWORD = "TSvH78#L$"

    TS_SOLD_OUT_ERROR = '137'
    
    class TransactionError < Exception
      
      attr_reader :code, :message

      def initialize(options)
        options.assert_valid_keys :code, :message
        @code = options[:code]
        @message = options[:message]
      end

      alias_method :consumer_message, :message

    end
    
    class ValidationError < TransactionError
      
      ErrorSourceId = "1"
      
    end
    
    class BookingError < TransactionError

      ErrorSourceId = "2"
      UnhandledErrorCode = "132"
      PriceMismatchErrorRegexp = /actual quoted price is/i

      def self.create(options)
        if options[:code] == UnhandledErrorCode && options[:message] =~ PriceMismatchErrorRegexp
          PriceMismatchError.new(options)
        else
          new(options)
        end
      end

    end

    class PriceMismatchError < BookingError
      def consumer_message
        "There was a system error. We will notify you when it has been resolved so you can complete your purchase."
      end
    end

    class TsTxRetrievalError < TransactionError
      
      ErrorSourceId = "3"
      
    end
    
    class VendorBookingRetrievalError < TransactionError
      
      ErrorSourceId = "4"
      
    end
    
    class UnknownStatusError < Exception
    end
    
    class UnknownBookingStatusError < UnknownStatusError
    end
    
    class UnknownPaymentStatusError < UnknownStatusError
    end
    
    class UnexpectedHTTPResponseError < Exception
    end
    
    class << self
      
      def get(booking_id, purchase)
        url = book_transaction_url(booking_id)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, 443)
        req = Net::HTTP::Get.new(uri.request_uri)
        req.basic_auth TS_BASIC_AUTH_USERNAME, TS_BASIC_AUTH_PASSWORD
        http.use_ssl = true
        response = http.request(req)
        unless response.kind_of?(Net::HTTPSuccess)
          raise UnexpectedHTTPResponseError, 
            "Travelsavers purchases might be broken! The booking status URL " +
            "for DailyDealPurchase #{purchase.id} (#{url}) should have returned a " +
            "2xx status, but returned #{response.code}. This means we don't know whether " +
            "the booking succeeded or failed. Please contact Daniel or Brad for " +
            "further assistance."
        end
        
        xml = response.body
        
        if Rails.env.development? || Rails.env.staging?
          Rails.logger.info "[Travelsavers] BookTransaction XML response from #{url}:\n"
          Rails.logger.info xml
        end
        
        new(xml, booking_id, purchase)
      end
      
      def book_transaction_url(booking_id)
        TS_BOOK_TRANSACTION_URL_TEMPLATE % URI.escape(booking_id)
      end
      
    end
    
    def initialize(xml, booking_id, purchase)
      @xml_source = xml
      @url = BookTransaction.book_transaction_url(booking_id)
      @purchase = purchase
      @parsed_xml = nil
      @parsed = false
      parse!
    end
    
    def parse!
      parse_booking_xml
      set_booking_status
      set_payment_status
      set_service_dates
      set_validation_errors
      set_vendor_booking_errors
      set_ts_tx_retrieval_errors
      set_vendor_booking_retrieval_errors
      set_fixable_errors
      set_unfixable_errors
      set_checkout_form_values
    end

    def success?
      if booking_success? && has_booking_id_element? && has_no_transaction_error_elements?
        return true 
      else
        return false
      end
    end
    
    def booking_status
      ensure_parsed!
      @booking_status ||= @parsed_xml.css("BookingStatus").text.downcase
    end
    
    def payment_status
      ensure_parsed!
      @payment_status ||= @parsed_xml.css("PaymentStatus").text.downcase
    end
    
    def validation_errors?
      @validation_errors.present?
    end
    
    def ts_tx_retrieval_errors?
      @ts_tx_retrieval_errors.present?
    end
    
    def vendor_booking_retrieval_errors?
      @vendor_booking_retrieval_errors.present?
    end
    
    def vendor_booking_errors?
      @vendor_booking_errors.present?
    end
    
    def has_errors_that_cant_be_ignored?
      validation_errors? || ts_tx_retrieval_errors? || vendor_booking_errors?
    end

    def price_mismatch_error
      @vendor_booking_errors.find { |error| error.is_a?(PriceMismatchError)  }
    end

    def has_sold_out_error?
      error_codes = self.unfixable_errors.map(&:code)
      error_codes.include? TS_SOLD_OUT_ERROR
    end

    def has_user_fixable_cc_errors?
      fixable_errors.present? &&
      fixable_errors.any? { |e| e.is_a?(Travelsavers::BookTransaction::BookingError) }
    end

    private

    def booking_success?
      if booking_status == TravelsaversBooking::BookingStatus::UNKNOWN
        raise UnknownBookingStatusError,
          "Travelsavers purchases might be broken! The booking status of DailyDealPurchase #{@purchase.id} " +
          "(#{@url}) is Unknown. This means we don't know whether the booking " +
          "succeeded or failed. Please contact Daniel or Brad for further assistance."
      end
      
      booking_status == TravelsaversBooking::BookingStatus::SUCCESS
    end
    
    def payment_success?
      if payment_status == TravelsaversBooking::PaymentStatus::UNKNOWN
        raise UnknownPaymentStatusError,
          "Travelsavers purchases might be broken! The payment status of DailyDealPurchase #{@purchase.id} " +
          "(#{@url}) is Unknown. This means we don't know whether the payment " +
          "succeeded or failed. Please contact Daniel or Brad for further assistance."
      end
      
      payment_status == TravelsaversBooking::PaymentStatus::SUCCESS
    end
    
    def ensure_parsed!
      raise "can't call #{caller[0][/`.*'/][1..-2]} before parsing response. try calling parse! first." unless parsed?
    end
    
    def set_booking_status
      ensure_parsed!
      @booking_status = @parsed_xml.css("BookingStatus").text.downcase
    end

    def set_payment_status
      ensure_parsed!
      @payment_status = @parsed_xml.css("PaymentStatus").text.downcase
    end

    def set_service_dates
      ensure_parsed!
      parse_date_from_element = lambda do |element_name|
        ssd = @parsed_xml.css(element_name).try(:text)
        ssd.present? ? Time.zone.parse(ssd) : nil
      end
      @service_start_date = parse_date_from_element.call("ServiceStartDate")
      @service_end_date = parse_date_from_element.call("ServiceEndDate")
    end
    
    def set_validation_errors
      ensure_parsed!
      @validation_errors = errors_matching_error_type(@parsed_xml, Travelsavers::BookTransaction::ValidationError::ErrorSourceId)
    end
    
    def set_vendor_booking_errors
      ensure_parsed!
      @vendor_booking_errors = errors_matching_error_type(@parsed_xml, Travelsavers::BookTransaction::BookingError::ErrorSourceId)
    end
    
    def set_fixable_errors
      ensure_parsed!
      @fixable_errors = []
      all_errors.select do |e|
        user_can_fix = e.css("UserCanFix").text rescue nil
        error_type = e.css("ErrorSourceID").text rescue nil
        next unless user_can_fix.try(:downcase) == "true" && error_type.present?
        @fixable_errors << BookTransaction.create_error_for_type(e, error_type)
      end
    end
    
    def set_unfixable_errors
      ensure_parsed!
      @unfixable_errors = []
      all_errors.select do |e|
        user_can_fix = e.css("UserCanFix").text rescue nil
        error_type = e.css("ErrorSourceID").text rescue nil
        next unless user_can_fix.try(:downcase) == "false" && error_type.present?
        @unfixable_errors << BookTransaction.create_error_for_type(e, error_type)
      end
    end
    
    def all_errors
      ensure_parsed!
      @parsed_xml.css("Error") || []
    end
    
    def has_booking_id_element?
      ensure_parsed!
      @parsed_xml.css("Booking BookingID").present?
    end
    
    def set_checkout_form_values
      ensure_parsed!
      @checkout_form_values = {}
      begin
        @parsed_xml.css("FormValues SubmittedForm").each do |sf|
          @checkout_form_values[sf.css("Field").text] = sf.css("Value").text
        end
      rescue Exception => e
        logger.warn("Error parsing submitted form values: #{e.message}")
      end
    end
    
    def has_no_transaction_error_elements?
      ensure_parsed!
      @parsed_xml.css("Errors Error").blank?
    end
    
    def set_ts_tx_retrieval_errors
      ensure_parsed!
      @ts_tx_retrieval_errors = errors_matching_error_type(@parsed_xml, Travelsavers::BookTransaction::TsTxRetrievalError::ErrorSourceId)
    end
    
    def set_vendor_booking_retrieval_errors
      ensure_parsed!
      @vendor_booking_retrieval_errors = errors_matching_error_type(@parsed_xml, Travelsavers::BookTransaction::VendorBookingRetrievalError::ErrorSourceId)
    end
    
    def errors_matching_error_type(parsed_xml, error_type)
      errors = []
      parsed_xml.css("Error").each do |error|
        next unless error_matches_error_type?(error, error_type)
        errors << BookTransaction.create_error_for_type(error, error_type)
      end
      errors
    end
    
    def self.create_error_for_type(error, error_type)
      code = error.css("ErrorCode").text rescue nil
      message = error.css("ErrorText").text rescue nil

      case error_type
        when Travelsavers::BookTransaction::ValidationError::ErrorSourceId
          Travelsavers::BookTransaction::ValidationError.new :code => code, :message => message
        when Travelsavers::BookTransaction::BookingError::ErrorSourceId
          Travelsavers::BookTransaction::BookingError.create :code => code, :message => message
        when Travelsavers::BookTransaction::TsTxRetrievalError::ErrorSourceId
          Travelsavers::BookTransaction::TsTxRetrievalError.new :code => code, :message => message
        when Travelsavers::BookTransaction::VendorBookingRetrievalError::ErrorSourceId
          Travelsavers::BookTransaction::VendorBookingRetrievalError.new :code => code, :message => message
      end
    end
    
    def error_matches_error_type?(error, error_type)
      error.present? &&
      error.css("ErrorSourceID").present? &&
      error.css("ErrorSourceID").text == error_type
    end
    
    def parse_booking_xml
      @parsed_xml = Nokogiri::XML(@xml_source)
      @parsed = true
      raise "invalid BookTransaction XML:\n\n#{@xml_source}" unless valid_xml?
    end
    
    def valid_xml?
      has_expected_root_element? && has_booking_status_element?
    end
    
    def has_booking_status_element?
      ensure_parsed!
      @parsed_xml.css("BookingStatus").present?
    end
    
    def parsed?
      @parsed
    end
    
    def has_expected_root_element?
      ensure_parsed!
      @parsed_xml.root.try(:name) == "BookTransaction" rescue false
    end
        
    def received_booking_information?
      @parsed_xml.css("Booking BookingID").present?
    end

  end
  
end
