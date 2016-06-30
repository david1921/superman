class Promotion < ActiveRecord::Base
  belongs_to :publishing_group
  has_many :discounts

  validates_presence_of     :publishing_group, :start_at, :end_at, :amount, :codes_expire_at
  validates_numericality_of :amount, :greater_than => 0
  validate :end_at_after_start_at
  validate :codes_expire_at_after_end_at

  named_scope :active, lambda { 
    { :conditions => ["start_at <= :now AND end_at > :now", { :now => Time.zone.now } ] }
  }

  def create_discount_for_purchase(purchase)
    Discount.create(:daily_deal_purchase_id => purchase.id,
                    :amount => self.amount,
                    :code => generate_discount_code,
                    :publisher_id => purchase.publisher.id,
                    :usable_only_once => true,
                    :first_usable_at => Time.zone.now,
                    :last_usable_at => self.codes_expire_at,
                    :promotion_id => self.id)
  end

  def generate_discount_code
    begin
      code = random_code
    end while discounts.find_by_code(code)
    code
  end

  private

  def random_code
    charset = %w{2 3 4 6 7 9 A C D E F G H J K L M N P Q R T V W X Y Z}
    code = Array.new(7) { charset.sample }.join
    self.code_prefix + code
  end

  def end_at_after_start_at
    unless self.start_at.blank? || self.end_at.blank?
      if self.end_at < self.start_at
        errors.add(:end_at, "%{attribute} must be after start at")
      end
    end
  end

  def codes_expire_at_after_end_at
    if self.codes_expire_at && self.end_at && self.codes_expire_at < self.end_at
      errors.add(:codes_expire_at, "%{attribute} must be after end at")
    end
  end
  
end
