
module DailyDeals
  
  module QrCode
    
    def self.included(base)
      base.send :include, ::ActionController::UrlWriter
      base.send :include, ::QrCode
      base.send :include, InstanceMethods
      base.send :delegate, :effective_qr_code_host, :to => :publisher
      base.send :validates_inclusion_of, :voucher_has_qr_code, :in => [ true, false ]
      base.send :before_validation_on_create, :set_voucher_has_qr_code_default
    end
    
    module InstanceMethods
      def qr_code_data
        daily_deal_qr_encoded_url(:host => effective_qr_code_host, :base36 => id.to_s(36).upcase).upcase
      end
            
      def voucher_has_qr_code
        if self[:voucher_has_qr_code].nil?
          publisher.try(:publishing_group).try(:voucher_has_qr_code_default) || false
        else
          self[:voucher_has_qr_code]
        end
      end

      # The AR-generated voucher_has_qr_code? calls self[:voucher_has_qr_code]
      def voucher_has_qr_code?
        voucher_has_qr_code
      end

      def set_voucher_has_qr_code_default
        self.voucher_has_qr_code = voucher_has_qr_code
        true
      end
    end
  end
end
