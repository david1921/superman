module Report
  
  class MerchantReport

    def initialize
      @description = ActiveSupport::OrderedHash.new
      @description["MERCHANT_ID"] = lambda { |deal| deal.advertiser.id }
      @description["MERCHANT_NAME"] = lambda { |deal| deal.advertiser.name }
      @description["MARKET"] = lambda { |deal| deal.publisher.city }
      @description["RUN_DATE"] = lambda { |deal| deal.start_at.strftime("%Y%m%d") }
      @description["OFFER_ID"] = lambda { |deal| deal.id }
      @description["OFFER_DESCIPTION"] = lambda { |deal| deal.value_proposition }
      @description["OFFER_PRICE"] = lambda { |deal| deal.price }
      @description["MERCHANT_REVENUE_SHARE"] = lambda { |deal| deal.advertiser.revenue_share_percentage }
      @description["ACCOUNT_EXECUTIVE"] = lambda { |deal| deal.account_executive }
      @description["CONTACT_PHONE"] = lambda { |deal| deal.advertiser.merchant_contact_phone }
      @description["CONTACT_EMAIL"] = lambda { |deal| deal.advertiser.merchant_contact_email }
      @description["ADDRESS_LINE_1"] = lambda { |deal| deal.advertiser.store.address_line_1 || "" if deal.advertiser.store.present? }
      @description["ADDRESS_LINE_2"] = lambda { |deal| deal.advertiser.store.address_line_2 || "" if deal.advertiser.store.present? }
      @description["ADDRESS_CITY"] = lambda { |deal| deal.advertiser.store.city || "" if deal.advertiser.store.present? }
      @description["ADDRESS_STATE"] = lambda { |deal| deal.advertiser.store.state || "" if deal.advertiser.store.present? }
      @description["ADDRESS_ZIP"] = lambda { |deal| deal.advertiser.store.zip || "" if deal.advertiser.store.present? }
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
