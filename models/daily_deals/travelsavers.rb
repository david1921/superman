module DailyDeals
  
  module Travelsavers
    
    def self.included(base)
      base.validate :travelsavers_product_code_must_be_present_only_for_travelsavers_deals
      base.validate :travelsavers_product_code_cant_be_changed_on_a_deal_with_associated_purchases
      base.validate :travelsavers_product_code_must_be_unique_across_source_deals_and_variations
    end
    
    def travelsavers_product_code_is_editable?
      pay_using?(:travelsavers) && !syndicated? && daily_deal_purchases.blank?
    end

    def travelsavers?
      pay_using?(:travelsavers)
    end
    
    private
    
    def travelsavers_product_code_must_be_unique_across_source_deals_and_variations
      invalid_if_publisher_not_present
      
      return if syndicated? || travelsavers_product_code.blank?
      
      source_deals_with_my_ts_product_code = DailyDeal.not_syndicated.find_all_by_travelsavers_product_code(travelsavers_product_code) + 
                                             DailyDealVariation.find_all_by_travelsavers_product_code(travelsavers_product_code)
      
      if (new_record? && source_deals_with_my_ts_product_code.present?) ||
         (!new_record? && (source_deals_with_my_ts_product_code - [self]).any?)
        errors.add(:travelsavers_product_code, translate_with_theme("activerecord.errors.custom.must_be_unique_across_source_deals"))
      end
    end
    
    def travelsavers_product_code_cant_be_changed_on_a_deal_with_associated_purchases
      invalid_if_publisher_not_present
      
      if travelsavers_product_code_changed? && pay_using?(:travelsavers) && daily_deal_purchases.present?
        errors.add(:travelsavers_product_code, translate_with_theme("activerecord.errors.custom.cannot_be_changed"))
      end
    end
    
    def travelsavers_product_code_must_be_present_only_for_travelsavers_deals
      invalid_if_publisher_not_present
      
      if pay_using?(:travelsavers)
        errors.add(:travelsavers_product_code, translate_with_theme("activerecord.errors.messages.blank")) unless travelsavers_product_code.present?
      else
        errors.add(:travelsavers_product_code, translate_with_theme("activerecord.errors.custom.must_be_blank_for_non_ts_deal")) unless travelsavers_product_code.blank?
      end
    end
    
    def invalid_if_publisher_not_present
      unless publisher.present?
        errors.add_to_base("error validating travelsavers_product_code; publisher must not be nil")
      end
    end
    
  end
  
end
