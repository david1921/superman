module CyberSource
  module Context
    class Base
      class << self
        def call(request)
          new(request).call
        end

        def transaction_signature(assignments, credentials)
          data = assignments[:signedFields].to_s.split(',').map { |key| "#{key}=#{assignments[key]}" }
          data << "signedFieldsPublicSignature=#{credentials.signature(assignments[:signedFields])}"
          credentials.signature(data.join(","))
        end
      end
      
      alias_method :to_s, :inspect
      
      def initialize(request)
        set_verified_daily_deal_purchase request
        verify_transaction_signature request
        @cyber_source_order = CyberSource::Order.new(request.params)
      end
      
      private
      
      def set_verified_daily_deal_purchase(request)
        @daily_deal_purchase = DailyDealPurchase.find(request.params[:orderNumber], :include => { :daily_deal => :publisher })
        @cyber_source_credentials = @daily_deal_purchase.cyber_source_credentials
        verify_signature request, :orderNumber
      end
        
      def verify_signature(request, param)
        if (signature = request.params["#{param}_publicSignature"]).blank?
          raise "Blank signature for parameter '#{param}' in request #{request.inspect}"
        elsif signature != @cyber_source_credentials.signature(request.params[param])
          raise "Parameter '#{param}' failed verification in request #{request.inspect}"
        end
      end
      
      def verify_transaction_signature(request)
        if (signature = request.params[:signedDataPublicSignature]).blank?
          raise "Blank parameter signedDataPublicSignature in request #{request.inspect}"
        elsif signature != self.class.transaction_signature(request.params, @cyber_source_credentials)
          raise "Transaction signature verification failed in request #{request.inspect}"
        end
      end
    end
  end
end
