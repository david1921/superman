require 'CyberSourceTransactionWSDriver.rb'

module CyberSource
  class Gateway
    class Error < RuntimeError; end
    
    class Credit
      attr_reader :request_id, :created_at, :reconciliation_id
      
      def initialize(response)
        @request_id = response.requestID
        @reconciliation_id = response.ccCreditReply.reconciliationID
        @created_at = DateTime.strptime(response.ccCreditReply.requestDateTime, "%Y-%m-%dT%H:%M:%SZ") rescue Time.zone.now
      end
    end
    
    class << self
      def void(credentials, request_id, merchant_reference, processor = nil)
        void_service = ::CyberSource::Soap::VoidService.new
        void_service.xmlattr_run = "true"
        void_service.voidRequestID = request_id
        
        response = run_transaction(credentials, processor) do |request|
          request.merchantReferenceCode = merchant_reference
          request.voidService = void_service
        end
        unless "ACCEPT" == response.decision
          Rails.logger.warn "CyberSource::Gateway.void #{merchant_reference} failed: #{response.inspect}"
          reason_code = (
            response.voidReply.reasonCode rescue
            response.reasonCode rescue
            "??? (could not determine reason code)")
          raise Error, "CyberSource::Gateway.void #{merchant_reference} failed: reason code #{reason_code}"
        end
      end

      def credit(credentials, request_id, amount, currency, merchant_reference, options = {}, processor = nil)
        credit_service = ::CyberSource::Soap::CCCreditService.new
        credit_service.xmlattr_run = "true"
        credit_service.captureRequestID = request_id

        purchase_totals = Soap::PurchaseTotals.new
        purchase_totals.grandTotalAmount = "%.2f" % amount
        purchase_totals.currency = currency
        
        bill_to = bill_to_parameters(options)
        merchant_defined_data = merchant_defined_data_parameters(options)
        
        response = run_transaction(credentials, processor) do |request|
          request.merchantReferenceCode = merchant_reference
          request.ccCreditService = credit_service
          request.purchaseTotals = purchase_totals
          
          request.billTo = bill_to if bill_to
          request.merchantDefinedData = merchant_defined_data if merchant_defined_data
        end
        if "ACCEPT" == response.decision
          Credit.new(response)
        else
          Rails.logger.warn "CyberSource::Gateway.credit #{merchant_reference} failed: #{response.inspect}"
          raise Error, "CyberSource::Gateway.credit #{merchant_reference} failed: reason code #{response.ccCreditReply.reasonCode}"
        end
      end
      
      private
      
      def bill_to_parameters(options)
        if options[:billing].present?
          billing = options[:billing].to_options
          
          Soap::BillTo.new.tap do |bill_to|
            { :first_name => "firstName",
              :last_name => "lastName",
              :address_line_1 => "street1",
              :address_line_2 => "street2",
              :city => "city",
              :state => "state",
              :postal_code => "postalCode",
              :country => "country",
              :email => "email"
            }.each_pair do |attr, param|
              bill_to.send "#{param}=", billing[attr] if billing.has_key?(attr)
            end
          end
        end
      end
      
      def merchant_defined_data_parameters(options)
        if options[:merchant_defined].present?
          merchant_defined = options[:merchant_defined].to_options
          
          Soap::MerchantDefinedData.new.tap do |merchant_defined_data|
            { :field_1 => "field1",
              :field_2 => "field2",
              :field_3 => "field3",
              :field_4 => "field4"
            }.each_pair do |attr, param|
              merchant_defined_data.send "#{param}=", merchant_defined[attr] if merchant_defined.has_key?(attr)
            end
          end
        end
      end
      
      def run_transaction(credentials, processor)
        request = Soap::RequestMessage.new
        request.merchantID = credentials.merchant_id
        yield request if block_given?
        
        processor ||= Soap::ITransactionProcessor.new(credentials.soap_username, credentials.soap_password, AppConfig.cyber_source_soap_url)
        processor.runTransaction(request)
      end
    end
  end
end
