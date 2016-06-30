module Report::Entertainment
  
  class MerchantReport

    def initialize
      @description = ActiveSupport::OrderedHash.new
      @description["MERCHANT_ID"] = lambda { |deal| deal.advertiser.merchant_id }
      @description["MARKET"] = lambda { |deal| deal.publisher.city }
      @description["DBA_NAME"] = lambda { |deal| deal.advertiser.name }
      @description["CONTACT_NAME"] = lambda { |deal| deal.advertiser.merchant_contact_name }
      @description["CONTACT_PHONE"] = lambda { |deal| "" }
      @description["CONTACT_EMAIL"] = lambda { |deal| "" }
      @description["REP_ID"] = lambda { |deal| deal.advertiser.rep_id }
      @description["BANK_ROUTING_NUMBER"] = lambda { |deal| "" }
      @description["BANK_ACCOUNT_NUMBER"] = lambda { |deal| "" }
      @description["BANK_NAME"] = lambda { |deal| deal.advertiser.bank_name }
      @description["BANK_ACCOUNT_OWNER_NAME"] = lambda { |deal| deal.advertiser.name_on_bank_account }
      @description["PREFERRED_PAYMENT_METHOD"] = lambda { |deal| "ACH" }
      @description["FEDERAL_TAX_ID"] = lambda { |deal| "" }
      @description["OFFER_ID"] = lambda { |deal| deal.id }
      @description["OFFER_DESCIPTION"] = lambda { |deal| deal.value_proposition }
      @description["MERCHANT_REVENUE_SHARE"] = lambda { |deal| deal.advertiser.revenue_share_percentage }
      @description["OFFER_PERCENT_OFF"] = lambda { |deal| deal.savings_as_percentage }
      @description["OFFER_VALUE"] = lambda { |deal| deal.value }
      @description["OFFER_PRICE"] = lambda { |deal| deal.price }
      @description["OFFER_DISCOUNT"] = lambda { |deal| deal.savings }
      @description["REDEMPTION_LOCATIONS"] = lambda { |deal| "" }
      @description["OFFER_COPY"] = lambda { |deal| deal.description }
      @description["TERMS"] = lambda { |deal| deal.terms }
      @description["MINIMUM_PURCHASE_LIMIT"] = lambda { |deal| deal.min_quantity }
      @description["MAXIMUM_PURCHASE_LIMIT"] = lambda { |deal| deal.max_quantity }
      @description["GET_PURCHASE_LIMIT"] = lambda { |deal| deal.max_quantity }
      @description["TOTAL_DEALS_AVAILABLE"] = lambda { |deal| deal.quantity }
      @description["RUN_DATE"] = lambda { |deal| deal.start_at.strftime("%Y%m%d") }
      @description["LOGO_UPLOADED"] = lambda { |deal| deal.advertiser.logo.file? }
      @description["PHOTO_UPLOADED"] = lambda { |deal| deal.photo.file? }
      @description["MERCHANT_NAME"] = lambda { |deal| deal.advertiser.merchant_name }
      @description["CHECK_PAYABLE_TO"] = lambda { |deal| deal.advertiser.check_payable_to }
      @description["CHECK_MAILING_ADDRESS_LINE_1"] = lambda { |deal| deal.advertiser.check_mailing_address_line_1 }
      @description["CHECK_MAILING_ADDRESS_LINE_2"] = lambda { |deal| deal.advertiser.check_mailing_address_line_2 }
      @description["CHECK_MAILING_ADDRESS_CITY"] = lambda { |deal| deal.advertiser.check_mailing_address_city }
      @description["CHECK_MAILING_ADDRESS_STATE"] = lambda { |deal| deal.advertiser.check_mailing_address_state }
      @description["CHECK_MAILING_ADDRESS_ZIP"] = lambda { |deal| deal.advertiser.check_mailing_address_zip }
    end

    def generate(result, publishing_group)
      result << @description.keys
      publishing_group.daily_deals.each do |deal|
        result << @description.keys.collect { |header_name| clean_value(value(header_name, deal)) }
      end
    end
                       
    def value(header_name, deal)
      raise ArgumentError.new("Nil deal") if deal.nil?
      proc = @description[header_name]
      raise ArgumentError.new("No proc for header #{header_name}") unless proc
      proc.call(deal)
    end
    
    def clean_value(value)
      value.to_s.gsub(/(__|\t|\n|\|)/, "")
    end      

  end
  
end
