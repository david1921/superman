require 'net/http'
require 'net/https'

module OptimalPayments
  
  module WebService
    
    # since OptimalPayment doesn't have a way to look up via transaction id,
    # Jordan at optimal payments say anything that happened before 12am EST
    # for the current day can still be voided.
    # 
    # This isn't ideal, but OP API is lacking in many ways.
    def self.voidable?( parameters = {} )
      payment_at = parameters[:payment_at]
      return false unless payment_at.present?
      now_eastern = Time.now.in_time_zone('Eastern Time (US & Canada)')  # need eastern time
      happened_on?(now_eastern, payment_at)
    end

    def self.refundable?( parameters = {} )
      return !voidable?(parameters)
    end

    def self.happened_on?(now, whenever)
       (now.beginning_of_day <= whenever) && (whenever <= now.end_of_day)
    end
    
    def self.void( parameters )
      VoidRequest.new( parameters ).perform
    end 
    
    def self.refund( parameters )
      RefundRequest.new( parameters ).perform
    end  

    # Represent a base WebService request.
    #
    # see: http://support.optimalpayments.com/REPOSITORY/WebServices_API_1.0.pdf
    class BaseRequest

      def singleton_class
        class << self; self; end
      end
           
      def initialize(parameters = {})
        singleton_class.class_eval do
           parameters.each_pair do |key, value|
            define_method key.to_sym do
               value
            end
          end
        end
      end

      def perform
        verify_credentials!
        Response.new( post_request_and_return_xml_body )
      end
      
      def url
        @url ||= "#{Configuration.webservice_url}"
      end

      private

      def verify_credentials!
        raise ArgumentError, "missing accountNum" unless Configuration.accountNum
        raise ArgumentError, "missing storeID"    unless Configuration.storeID
        raise ArgumentError, "missing storePwd"   unless Configuration.storePwd
      end   
     
      def verify_required!(*required)
        missing = []
        (required||[]).each do |attr|
          missing << attr unless respond_to?( attr.to_sym ) && send( attr.to_sym )
        end
        raise ArgumentError, "missing required fields: #{missing.join(", ")}" unless missing.empty?
      end      
      
      def xml
        raise ArgumentError, "block is required" unless block_given?
        message = ""
        xml = Builder::XmlMarkup.new(:target => message)
        xml.instruct! :xml, :version => '1.0', :encoding => 'ISO-8859-1'
        xml.tag!( action.to_sym, 
          "xmlns" => "http://www.optimalpayments.com/creditcard/xmlschema/v1" ) do |action|
          action.merchantAccount do |merchant_account|
            merchant_account.accountNum    Configuration.accountNum
            merchant_account.storeID       Configuration.storeID
            merchant_account.storePwd      Configuration.storePwd
          end
          yield action
        end
        message
      end

      def post_request_and_return_xml_body
        post({:webservice_url => url, :txn_mode => mode, :txn_request => request}).body
      end

      def post( options )
        url         = URI.parse( options[:webservice_url] )
        connection  = Net::HTTP.new(url.host, url.port)
        connection.use_ssl = true
        connection.start do |http|
          request = Net::HTTP::Post.new( url.to_s )
          request.set_form_data({'txnMode' => options[:txn_mode], 'txnRequest' => options[:txn_request]}, '&')
          response = http.request(request)
          response
        end        
      end

    end       
    
    class VoidRequest < BaseRequest
      
      def action
        @action ||= "ccCancelRequestV1"
      end
                
      def mode
        @mode ||= "ccCancelSettle"
      end
      
      # responsible for building up the xml request document
      # for a void (cancel request).
      def request
        verify_required! :confirmation_number
        xml do |xml|
          xml.confirmationNumber confirmation_number
        end
      end

    end
    
    class RefundRequest < BaseRequest

      def action
        @action ||= "ccPostAuthRequestV1"
      end
      
      def mode
        @mode ||= "ccCredit"
      end 
      
      def request
        verify_required! :confirmation_number, :merchant_ref_num
        xml do |xml|
          xml.confirmationNumber confirmation_number
          xml.merchantRefNum     merchant_ref_num
          xml.amount             amount if respond_to?( :amount ) && amount.present?
        end
      end

    end
    
    class Response

      attr_accessor :code, :action_code, :description, :errors

      def initialize(xml_from_post = "")
        xml = Nokogiri::XML(xml_from_post.strip)
        @errors = parse_errors(xml)
        raise ArgumentError, @errors unless @errors.empty?
        @code = parse_code(xml)
        @action_code = parse_action_code(xml)
        @description = parse_description(xml)
      end

      def success?
        @code == 0
      end

      def error_message
        "Response Code: #{code}; Action Code: #{action_code}; Errors: #{errors}"
      end

      private

      def parse_errors(xml)
        xml.errors.empty? ? [] : xml.errors.collect(&:message).join(",")
      end

      def parse_action_code(xml)
        xml.at_xpath("//xmlns:actionCode").try(:text)
      end

      def parse_code(xml)
        raw_code = xml.at_xpath("//xmlns:code")
        raw_code = raw_code.present? ? raw_code.text : -1
        raw_code.to_i
      end

      def parse_description(xml)
        xml.at_xpath("//xmlns:description").try(:text)
      end

    end

  end

end