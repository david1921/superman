module Accounting
  module RevenueSharingAgreementConstants

    # OrderedHash here to keep MESSAGE below consistent (regular {}.keys would be unordered)
    CREDIT_CARD_FEE_SOURCES = ::ActiveSupport::OrderedHash.new
    CREDIT_CARD_FEE_SOURCES['Actual Fees'] = 'actual_fees'
    CREDIT_CARD_FEE_SOURCES['Estimated'] = 'estimated'
    CREDIT_CARD_FEE_SOURCES['Fixed Fee ($/Transaction)'] = 'fixed_amount'
    CREDIT_CARD_FEE_SOURCES['Fixed Fee (%)'] = 'fixed_percentage'

    CREDIT_CARD_FEE_SOURCES_INCLUSION_MESSAGE = "%{attribute} must be #{CREDIT_CARD_FEE_SOURCES.keys.to_sentence(:last_word_connector => ' or ', :two_words_connector => ' or ')}."
    
    CREDIT_CARD_FEE_SOURCE_FEES_MESSAGE = "should not be set when credit card fee source is Actual Fees"
    CREDIT_CARD_FEE_SOURCE_ESTIMATED_MESSAGE = "should not be set when credit card fee source is Estimated"
    CREDIT_CARD_FEE_SOURCE_FIXED_AMOUNT_MESSAGE = "should not be set when credit card fee source is Fixed Fee ($/Transaction)"
    CREDIT_CARD_FEE_SOURCE_FIXED_PERCENTAGE_MESSAGE = "should not be set when credit card fee source is Fixed Fee (%)"
    
    CREDIT_CARD_FEE_SOURCE_FEES_PRO_RATA_MESSAGE = "should not be set when actual credit card fees are present."
    
    CREDIT_CARD_FEE_SOURCE_FEES_PLATFORM_GROSS_ATTRIBUTES = [:credit_card_fee_gross_publisher_percentage,
                                                             :credit_card_fee_gross_merchant_percentage,
                                                             :credit_card_fee_gross_aa_percentage]
    CREDIT_CARD_FEE_SOURCE_FEES_PLATFORM_GROSS_SUM_MESSAGE = "The sum of the 'Actual Fees Gross Share' should be 100%."
    
    CREDIT_CARD_FEE_SOURCE_FEES_PLATFORM_NET_ATTRIBUTES = [:credit_card_fee_net_publisher_percentage,
                                                           :credit_card_fee_net_merchant_percentage,
                                                           :credit_card_fee_net_aa_percentage]
    CREDIT_CARD_FEE_SOURCE_FEES_PLATFORM_NET_SUM_MESSAGE = "The sum of the 'Actual Fees Net Share' should be 100%."
    
    CREDIT_CARD_FEE_SOURCE_FEES_SYNDICATION_GROSS_ATTRIBUTES = [:credit_card_fee_gross_source_percentage,
                                                                :credit_card_fee_gross_merchant_percentage,
                                                                :credit_card_fee_gross_distributor_percentage,
                                                                :credit_card_fee_gross_aa_percentage]
    CREDIT_CARD_FEE_SOURCE_FEES_SYNDICATION_GROSS_SUM_MESSAGE = "The sum of the 'Actual Fees Gross Share' should be 100%."
    
    CREDIT_CARD_FEE_SOURCE_FEES_SYNDICATION_NET_ATTRIBUTES = [:credit_card_fee_net_source_percentage,
                                                              :credit_card_fee_net_merchant_percentage,
                                                              :credit_card_fee_net_distributor_percentage,
                                                              :credit_card_fee_net_aa_percentage]
    CREDIT_CARD_FEE_SOURCE_FEES_SYNDICATION_NET_SUM_MESSAGE = "The sum of the 'Actual Fees Net Share' should be 100%."
    
    CREDIT_CARD_FEE_VALUES = {'0%' => 0, 
                              '100%' => 100}
                              
    PLATFORM_FEE_FLAT_FEE_MESSAGE = "should not be set when agreement type is not Deal."
    SYNDICATION_FEE_FLAT_FEE_MESSAGE = "should not be set when agreement type is not Deal."
    
    PLATFORM_FEE_MUTUALLY_EXCLUSIVE_MESSAGE = "Only gross or net platform fee can be entered, not both."
    
    PLATFORM_FEE_MISSING_MESSAGE = "Either the gross or net platform fee must be entered."
    
    def self.credit_card_fee_source_description(credit_card_fee_source_value)
      CREDIT_CARD_FEE_SOURCES.find{|key,value| value == credit_card_fee_source_value}.first
    end
  end
end