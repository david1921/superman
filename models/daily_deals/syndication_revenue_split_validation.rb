module DailyDeals
  module SyndicationRevenueSplitValidation
    
    include Analog::ModelValidation
    
    def self.included(base)
      base.send :include, ValidationMethods
    end
    
    module ValidationMethods
      
      def validate_revenue_split_percentages
        case revenue_split_type
          when 'gross'
            validate_gross_revenue_split_percentages
          when 'net'
            validate_net_revenue_split_percentages
        end
      end
      
      def validate_gross_revenue_split_percentages
        validate_sum(DailyDeals::SyndicationRevenueSplitConstants::GROSS_REVENUE_SPLIT_ATTRIBUTES, 
                     100,
                     DailyDeals::SyndicationRevenueSplitConstants::GROSS_REVENUE_SPLIT_SUM_MESSAGE)
      end
      
      def validate_net_revenue_split_percentages
        validate_percentage(:merchant_net_percentage)
        validate_sum(DailyDeals::SyndicationRevenueSplitConstants::NET_REVENUE_SPLIT_REMAINING_ATTRIBUTES, 
                     100,
                     DailyDeals::SyndicationRevenueSplitConstants::NET_REVENUE_SPLIT_REMAINING_SUM_MESSAGE)
      end
      
    end
    
  end
end