module Accounting
  module SyndicationRevenueSharingAgreementValidation
    
    include Analog::ModelValidation
    
    def self.included(base)
      base.send :include, SyndicationValidationMethods
    end
    
    module SyndicationValidationMethods

      def validate_syndication_fee_values
        validate_syndication_fee_percentages
        case agreement_type
          when 'PublishingGroup'
            validate_blank(:syndication_flat_fee, Accounting::RevenueSharingAgreementConstants::SYNDICATION_FEE_FLAT_FEE_MESSAGE)
          when 'Publisher'
            validate_blank(:syndication_flat_fee, Accounting::RevenueSharingAgreementConstants::SYNDICATION_FEE_FLAT_FEE_MESSAGE)
          when 'Deal'
            validate_amount(:syndication_flat_fee)
        end
      end
      
      def validate_credit_card_fees
        case credit_card_fee_source
          when 'actual_fees'
            validate_fixed_credit_card_fee_values_not_present(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_MESSAGE)
            validate_credit_card_fee_gross_values
            validate_credit_card_fee_net_values
          when 'fixed_amount'
            validate_credit_card_fee_gross_values_not_present(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FIXED_AMOUNT_MESSAGE)
            validate_credit_card_fee_net_values_not_present(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FIXED_AMOUNT_MESSAGE)
            validate_blank(:credit_card_fee_fixed_percentage, Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FIXED_AMOUNT_MESSAGE)
            validate_amount(:credit_card_fee_fixed_amount)
          when 'fixed_percentage'
            validate_credit_card_fee_gross_values_not_present(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FIXED_PERCENTAGE_MESSAGE)
            validate_credit_card_fee_net_values_not_present(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FIXED_PERCENTAGE_MESSAGE)
            validate_blank(:credit_card_fee_fixed_amount, Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FIXED_PERCENTAGE_MESSAGE)
            validate_percentage(:credit_card_fee_fixed_percentage)
          when 'estimated'
            validate_fixed_credit_card_fee_values_not_present(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_ESTIMATED_MESSAGE)
            validate_credit_card_fee_gross_values
            validate_credit_card_fee_net_values
        end
      end
      
      private
      
      def validate_credit_card_fee_gross_values_not_present(message, validate_pro_rata = true)
        validate_false(:credit_card_fee_gross_pro_rata, message)  if validate_pro_rata
        validate_blank(:credit_card_fee_gross_source_percentage, message)
        validate_blank(:credit_card_fee_gross_merchant_percentage, message)
        validate_blank(:credit_card_fee_gross_distributor_percentage, message)
        validate_blank(:credit_card_fee_gross_aa_percentage, message)
      end
      
      def validate_credit_card_fee_net_values_not_present(message, validate_pro_rata = true)
        validate_false(:credit_card_fee_net_pro_rata, message) if validate_pro_rata
        validate_blank(:credit_card_fee_net_source_percentage, message)
        validate_blank(:credit_card_fee_net_merchant_percentage, message)
        validate_blank(:credit_card_fee_net_distributor_percentage, message)
        validate_blank(:credit_card_fee_net_aa_percentage, message)
      end
      
      def validate_fixed_credit_card_fee_values_not_present(message)
        validate_blank(:credit_card_fee_fixed_amount, message)
        validate_blank(:credit_card_fee_fixed_percentage, message)
      end
      
      def validate_credit_card_fee_gross_values
        if credit_card_fee_gross_pro_rata
          validate_credit_card_fee_gross_values_not_present(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PRO_RATA_MESSAGE, false)
        else
          validate_sum(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_SYNDICATION_GROSS_ATTRIBUTES, 
                       100,
                       Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_SYNDICATION_GROSS_SUM_MESSAGE)
        end
      end
      
      def validate_credit_card_fee_net_values
        if credit_card_fee_net_pro_rata
          validate_credit_card_fee_net_values_not_present(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PRO_RATA_MESSAGE, false)
        else
          validate_sum(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_SYNDICATION_NET_ATTRIBUTES, 
                       100,
                       Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_SYNDICATION_NET_SUM_MESSAGE)
        end
      end
      
      def validate_syndication_fee_percentages
        validate_percentage(:syndication_fee_gross_percentage)
        validate_percentage(:syndication_fee_net_percentage)
      end
      
    end
    
  end
end