class Accounting::SyndicationRevenueSharingAgreement < ActiveRecord::Base
  
  include Accounting::SyndicationRevenueSharingAgreementValidation
  include Accounting::RevenueSharingAgreementConstants
  
  belongs_to :agreement, :polymorphic => true
  
  validates_presence_of   :effective_date
  
  validate                :validate_syndication_fee_values
  validates_inclusion_of  :credit_card_fee_source, :in => CREDIT_CARD_FEE_SOURCES.values, :message => CREDIT_CARD_FEE_SOURCES_INCLUSION_MESSAGE, :allow_blank => false
  validate                :validate_credit_card_fees
  
  def self.current
    find(:first, :conditions => "approved = true", :order => "effective_date DESC")
  end
  
  def revenue_split_details
    return "[Gross: #{syndication_fee_gross_percentage}%] [Net: #{syndication_fee_net_percentage}%]"
  end
  
  def credit_card_fee_split_description
    Accounting::RevenueSharingAgreementConstants.credit_card_fee_source_description(credit_card_fee_source)
  end
  
  def credit_card_fee_split_details
    case credit_card_fee_source
      when 'actual_fees'
        return credit_card_fees_gross_percentages_detail << " " << credit_card_fees_net_percentages_detail
      when 'estimated'
        return credit_card_fees_gross_percentages_detail << " " << credit_card_fees_net_percentages_detail
      when 'fixed_amount'
        return "$#{credit_card_fee_fixed_amount}"
      when 'fixed_percentage'
        return "#{credit_card_fee_fixed_percentage}%"
    else
      raise "Invalid credit card fee source: " << credit_card_fee_source
    end
  end
  
  private
  
  def credit_card_fees_gross_percentages_detail
    detail = "[Gross: "
    if credit_card_fee_gross_pro_rata?
      detail << "Pro Rata"
    else
      detail << "Source #{credit_card_fee_gross_source_percentage}% " if credit_card_fee_gross_source_percentage > 0
      detail << "Merchant #{credit_card_fee_gross_merchant_percentage}% " if credit_card_fee_gross_merchant_percentage > 0
      detail << "Distributor #{credit_card_fee_gross_distributor_percentage}% " if credit_card_fee_gross_distributor_percentage > 0
      detail << "AA #{credit_card_fee_gross_aa_percentage}%" if credit_card_fee_gross_aa_percentage > 0
    end
    detail << "]"
  end
  
  def credit_card_fees_net_percentages_detail
    detail = "[Net: "
    if credit_card_fee_net_pro_rata?
      detail << "Pro Rata"
    else
      detail << "Source #{credit_card_fee_net_source_percentage}% " if credit_card_fee_net_source_percentage > 0
      detail << "Merchant #{credit_card_fee_net_merchant_percentage}% " if credit_card_fee_net_merchant_percentage > 0
      detail << "Distributor #{credit_card_fee_net_distributor_percentage}% " if credit_card_fee_net_distributor_percentage > 0
      detail << "AA #{credit_card_fee_net_aa_percentage}%" if credit_card_fee_net_aa_percentage > 0
    end
    detail << "]"
  end
  
end