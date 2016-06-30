module Accounting
  module PlatformRevenueSharingAgreementValidation
    
    include Analog::ModelValidation
    
    def self.included(base)
      base.send :include, PlatformValidationMethods
    end
    
    module PlatformValidationMethods
      
      def validate_platform_fee_values
        validate_platform_fee_percentages
        case agreement_type
          when 'PublishingGroup'
            validate_blank(:platform_flat_fee, Accounting::RevenueSharingAgreementConstants::PLATFORM_FEE_FLAT_FEE_MESSAGE)
          when 'Publisher'
            validate_blank(:platform_flat_fee, Accounting::RevenueSharingAgreementConstants::PLATFORM_FEE_FLAT_FEE_MESSAGE)
          when 'Deal'
            validate_amount(:platform_flat_fee)
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
        validate_false(:credit_card_fee_gross_pro_rata, message) if validate_pro_rata
        validate_blank(:credit_card_fee_gross_publisher_percentage, message)
        validate_blank(:credit_card_fee_gross_merchant_percentage, message)
        validate_blank(:credit_card_fee_gross_aa_percentage, message)
      end
      
      def validate_credit_card_fee_net_values_not_present(message, validate_pro_rata = true)
        validate_false(:credit_card_fee_net_pro_rata, message) if validate_pro_rata
        validate_blank(:credit_card_fee_net_publisher_percentage, message)
        validate_blank(:credit_card_fee_net_merchant_percentage, message)
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
          validate_sum(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PLATFORM_GROSS_ATTRIBUTES, 
                       100,
                       Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PLATFORM_GROSS_SUM_MESSAGE)
        end
      end
      
      def validate_credit_card_fee_net_values
        if credit_card_fee_net_pro_rata
          validate_credit_card_fee_net_values_not_present(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PRO_RATA_MESSAGE, false)
        else
          validate_sum(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PLATFORM_NET_ATTRIBUTES, 
                       100,
                       Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PLATFORM_NET_SUM_MESSAGE)
        end
      end
      
      def validate_platform_fee_percentages
        gross_value = value_of(:platform_fee_gross_percentage)
        net_value = value_of(:platform_fee_net_percentage)
        if gross_value.present? && net_value.present?
          errors.add(:base, Accounting::RevenueSharingAgreementConstants::PLATFORM_FEE_MUTUALLY_EXCLUSIVE_MESSAGE)
        elsif gross_value.blank? && net_value.blank?
          errors.add(:base, Accounting::RevenueSharingAgreementConstants::PLATFORM_FEE_MISSING_MESSAGE)
        else
          validate_percentage(:platform_fee_gross_percentage) if gross_value.present?
          validate_percentage(:platform_fee_net_percentage) if net_value.present?
        end
      end
    end
    
  end
end