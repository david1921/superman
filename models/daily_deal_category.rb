# Publisher and PublishingGroup categories are not used yet. Need to add a new belongs_to to DailyDeal for them.
# Currently, only the default set of categories are used for analytics. They have no publisher_ids
# FIXME Move to daily_deals folder
class DailyDealCategory < ActiveRecord::Base
  belongs_to :publisher
  belongs_to :publishing_group

  has_many :publishers_category_daily_deals, :class_name => "DailyDeal", :foreign_key => :publishers_category_id
  
  validates_presence_of :name
  validates_presence_of :abbreviation, :if => :analytics?
  validates_uniqueness_of :name, :scope => :publisher_id

  named_scope :analytics, :conditions => { :publisher_id => nil, :publishing_group_id => nil }, :order => :name
  named_scope :with_names, lambda { |names|
    {:conditions => ["daily_deal_categories.name IN (?)", names]}
  }
  
  named_scope :for_publisher, lambda { |publisher|
    publishing_group = publisher.try(:publishing_group)
    if publishing_group && publishing_group.daily_deal_categories.exists?
      {:conditions => ["daily_deal_categories.publishing_group_id = ?", publishing_group.id]}
    elsif publisher.daily_deal_categories.exists?
      {:conditions => ["daily_deal_categories.publisher_id = ?", publisher.id]}
    else
      {:conditions => {:publisher_id => nil, :publishing_group_id => nil}, :order => :name}
    end
  }
  
  named_scope :with_deals_in_zip_radius, lambda { |zip_code, zip_radius|
    if zip_code
      zip_codes = ZipCode.zips_near_zip_and_radius(zip_code, zip_radius) if zip_radius > 0
    end

    if zip_codes.present?
      {:conditions =>
        ["EXISTS(SELECT daily_deals.id FROM daily_deals
                 LEFT JOIN stores ON stores.advertiser_id = daily_deals.advertiser_id
                 WHERE daily_deals.publishers_category_id = daily_deal_categories.id
                   AND SUBSTR(stores.zip, 1, 5) IN (:zips))",
          {:zips => zip_codes}]}
    else
      {}
    end
  }

  named_scope :with_active_deals_for_publisher, lambda { |publisher|
    {:conditions => [
      "EXISTS(SELECT id FROM daily_deals
              WHERE daily_deals.publishers_category_id = daily_deal_categories.id
                AND publisher_id = :publisher_id
                AND daily_deals.deleted_at IS NULL
                AND start_at <= :now
                AND hide_at > :now)",
      {:now => Time.zone.now,
       :publisher_id => publisher.id}]}
  }

  named_scope :ordered_by_name_ascending, :order => "name ASC"
  
  def self.unassigned
    find(:first, :conditions => {:name => "Unassigned"})
  end
  
  def name_with_abbreviation
    if abbreviation.present?
      "#{name} (#{abbreviation})"
    else
      name
    end
  end
  
  def to_liquid
    Drop::DailyDealCategory.new(self)
  end

  def analytics?
    self.publisher_id.nil? && self.publishing_group_id.nil?
  end
  
end
