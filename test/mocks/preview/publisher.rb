class Publisher < Preview::Model
  attr_accessor :label
  attr_accessor :name
  attr_accessor :publishing_group_id
  attr_accessor :theme
  
  def self.all(options = {})
    Preview::Model.all[:publishers].values
  end
  
  def self.find(id)
    publisher = Preview::Model.all[:publishers][id.to_i]
    raise("Cannot find Publisher with id: #{id}") unless publisher
    publisher
  end
  
  def self.find_by_label!(label)
    publisher = Preview::Model.all[:publishers].values.detect { |p| p.label == label }
    raise("ActiveRecord::RecordNotFound") unless publisher
    publisher
  end
  
  def self.find_by_label(label)
    publisher = Preview::Model.all[:publishers].values.detect { |p| p.label == label }
  end
  
  def self.find_by_label_or_id(id)
    Preview::Model.all[:publishers].values.detect { |p| p.label == id } || Publisher.find(id)  
  end
  
  def self.find_by_label_or_id!(id)
    publisher = Publisher.find_by_label_or_id(id)
    raise("ActiveRecord::RecordNotFound") unless publisher
    publisher
  end

  def self.find_by_production_host(host)
    nil
  end
  
  def advertisers_with_web_offers(search_request)
    [Advertiser.new]
  end
  
  def signup_discount_amount
    @signup_discount ||= [0, 5, 15][rand(3)]
  end
  
  def initialize(label)
    self.label = label
  end
  
  def find_braintree_credentials!
    true
  end
  
  def pay_using?(pay_meth)
    payment_method == pay_meth.to_s
  end

  def payment_method
    "credit"
  end
  
  def brand_name_or_name
    name
  end
  
  def brand_name
    name
  end

  def market_name
    city
  end

  def market_name_or_city
    city
  end
  
  def find_market_by_zip_code(zip_code)
    nil
  end
  
  def deals_without_market
    DailyDealsAssociation.new(self)
  end
  
  def name_for_daily_deals
    name
  end
  
  def address_line_1
    @address_line_1 ||= Faker::Address.street_address
  end

  def address_line_2
    @address_line_2 ||= (rand < 0.1) ? Faker::Address.street_address : nil
  end

  def city
    @city ||= Faker::Address.city
  end
  
  def checkout_discount_codes?
    false
  end
  
  def formatted_phone_number
    @phone_number ||= Faker::PhoneNumber.phone_number
  end

  def support_phone_number
    @support_phone_number ||= Faker::PhoneNumber.phone_number
  end
  
  def google_map_url(name)
    query_params = "%s, %s, %s %s (%s)" % [ address_line_1, city, state, zip, name ]
    "http://maps.google.com/maps?li=d&hl=en&f=d&iwstate1=dir:to&daddr=#{CGI.escape(query_params)}"    
  end

  def state
    @state ||= Faker::Address.us_state
  end

  def zip
    @zip ||= Faker::Address.zip_code
  end
  
  def active_placed_offers_count(city = nil, state = nil)
    10
  end
  
  def default_offer_search_distance
    10
  end
  
  def default_offer_search_postal_code
    zip
  end
  
  def link_to_website?
    true
  end
  
  def random_coupon_order?
    false
  end
  
  def search_box?
    true
  end
  
  def show_zip_code_search_box?
    true
  end
  
  def subcategories?
    true
  end
  
  def show_bottom_pagination?
    true
  end
  
  def page_preference
    10
  end

  def sales_email_address
    @sales_email_address ||= Faker::Internet.email
  end

  def support_email_address
    @support_email_address ||= Faker::Internet.email
  end
  
  def allow_daily_deals?
    true
  end
  
  def current_user_belongs_to?
    true
  end
  
  def enable_daily_deal_referral?
    true
  end
  
  def currency_symbol
    "USD"
  end
  
  def host
    "localhost:3000"
  end

  def daily_deal_host
    "localhost:3000"
  end
  
  def daily_deal_brand_name
    brand_name_or_name
  end

  def how_it_works
    ""
  end

  def daily_deal_name
    "Deal of the Day"
  end
  
  def daily_deals
    @daily_deals = DailyDealsAssociation.new(self)
  end
  
  def offers
    @offers ||= OfferAssociation.new(self)
  end

  def gift_certificates
    @gift_certificates ||= GiftCertificateAssociation.new(self)
  end

  def launched?
    true
  end
  
  def coupons_home_link?
    false
  end

  
  def advanced_search_link_target
    "_top"
  end
  
  def show_gift_certificate_button?
    true
  end
  
  def publishing_group
    @publishing_group ||= Preview::Model.all[:publishing_groups][publishing_group_id]
  end
  
  def publishers_in_publishing_group
    publishing_group.publishers
  end
  
  def show_special_deal?
    true
  end
  
  def unique_subscribers_count
    0
  end
  
  def using_analytics_provider?
    false
  end   
  
  def find_usable_discount_by_code(code)
    nil
  end
  
  def consumers
    @consumers = ConsumersAssociation.new(self)
  end
  
  def subscribers
    @subscribers = SubscribersAssociation.new(self)
  end
  
  def allow_discount_codes?
    false
  end
  
  def enable_daily_deal_referral
    true
  end   
  
  def daily_deal_referral_credit_amount
    10.00
  end

  def theme
    @theme || "withtheme"
  end
  
  def to_liquid
    ::Drop::Publisher.new(self)
  end
end
