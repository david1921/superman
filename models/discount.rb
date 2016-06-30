class Discount < ActiveRecord::Base
  include HasUuid

  belongs_to :publisher
  belongs_to :daily_deal_purchase

  uuid_type :random
  
  validates_presence_of :publisher
  validates_presence_of :code
  validates_format_of :code, :with => /\A[A-Z\d_-]*\z/, :message => "%{attribute} has an invalid format"
  validates_numericality_of :amount, :allow_nil => false
  validate :uniqueness_of_code_for_publisher
  
  before_validation :normalize_code
  
  named_scope :not_deleted, {
    :conditions => "deleted_at IS NULL"
  }
  named_scope :usable, lambda {{
    :conditions => [
      "deleted_at IS NULL 
        AND (first_usable_at IS NULL OR first_usable_at <= :now) 
        AND (last_usable_at IS NULL OR :now <= last_usable_at)
        AND used_at IS NULL", 
      { :now => Time.zone.now }
    ]
  }}
  named_scope :at_checkout, {
    :conditions => "usable_at_checkout"
  }
  
  named_scope :by_publisher_label, lambda { |label| {:include => [:publisher], 
    :conditions => {:publisher_id => Publisher.find_by_label(label)} }
  }
  
  delegate :currency_symbol, :to => :publisher

  def use!
    touch(:used_at)
  end
  
  def used?
    used_at.present?
  end

  def deleted?
    deleted_at.present?
  end

  def set_deleted!
    self.deleted_at = Time.zone.now if deleted_at.blank?
    save_with_validation false
  end
  
  def usable?
    !deleted? && (now = Time.zone.now) && used_at.nil? &&
      (first_usable_at.nil? || first_usable_at <= now) && 
      (last_usable_at.nil? || now <= last_usable_at)
  end
  
  def self.normalize_code(code)
    code.to_s.gsub(/\s+/, '').upcase
  end
  
  private
  
  def normalize_code
    self.code = self.class.normalize_code(code)
  end
  
  def uniqueness_of_code_for_publisher
    if !deleted? && publisher_id.present? && code.present?
      conditions_sql = "publisher_id = ? AND deleted_at IS NULL AND code = ?"
      conditions_params = [publisher_id, code]
      unless new_record?
        conditions_sql << " AND id <> ?"
        conditions_params << id
      end
      errors.add(:code, "%{attribute} is already in use for this publisher") if self.class.exists?([conditions_sql, *conditions_params])
    end
  end
end
