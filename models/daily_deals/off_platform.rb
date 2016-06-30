module DailyDeals
  module OffPlatform
    
    TRUE_VALUES	=	[true, 1, '1', 't', 'T', 'true', 'TRUE'].to_set
   
    def self.included(base)
      base.send :include, InstanceMethods
      base.class_eval do
        
        # accessors
        attr_accessor :off_platform
        
        # callbacks
        before_save  :convert_type_if_neccessary
        
      end
    end
    
    module InstanceMethods
      
      def off_platform?
        self.class == OffPlatformDailyDeal
      end
      
      def convert_type_if_neccessary
        value_to_boolean(@off_platform) ? convert_to_off_platform_if_necessary : convert_from_off_platform_if_necessary
      end

      def convert_to_off_platform_if_necessary
        unless off_platform?
          self.type = OffPlatformDailyDeal.to_s
          self.listing = listing.present? ? listing.gsub(/^BBD/, 'OP') : item_code
        end
      end

      def convert_from_off_platform_if_necessary    
        if off_platform?
          self.type = DailyDeal.to_s
          self.listing = listing.present? ? listing.gsub(/^OP/, 'BBD') : item_code
        end
      end
      
      def value_to_boolean(value)
        TRUE_VALUES.include?(value)
      end
      
    end
    
  end
end