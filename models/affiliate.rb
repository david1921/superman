class Affiliate < User
  belongs_to :publisher
  has_many :daily_deals, :foreign_key => :publisher_id, :primary_key => :publisher_id, :conditions => "affiliate_revenue_share_percentage > 0"

  validates_presence_of :publisher
  validate :is_not_admin

  before_save :assign_affiliate_code

  ADMIN_ATTRIBUTES = %w{ company admin_privilege }

  #
  # Don't assign User attributes only applicable to administrators
  #
  ADMIN_ATTRIBUTES.each { |attr| class_eval "def #{attr}=(value); end" }
  
  def url_for_daily_deal(daily_deal)
    "http://#{daily_deal.publisher.daily_deal_host}/daily_deals/#{daily_deal.id}?affiliate_code=#{affiliate_code}"
  end

  private

  def assign_affiliate_code
    if affiliate_code.blank?
      self.affiliate_code = UUIDTools::UUID.random_create.to_s 
    end
  end

  def is_not_admin
    ADMIN_ATTRIBUTES.each do |attr|
      unless self.send(attr.to_sym).blank?
        errors.add(attr.to_sym, "%{attribute} must remain blank")
      end
    end
  end

end
