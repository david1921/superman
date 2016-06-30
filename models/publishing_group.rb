class PublishingGroup < ActiveRecord::Base
  include ActsAsLabelled
  include Analog::Say
  include HasConfigurableProperties
  include HasMerchantAccountID
  include PublishingGroups::Core
  include ReadyMadeThemes
  include Report::PublishingGroup
  include Locales::Enabled
  include PublishingGroups::SilverpopMailingManagement

  acts_as_textiled :how_it_works

  has_many :advertisers, :through => :publishers
  has_many :consumers, :through => :publishers
  has_many :publishers
  #
  # NOTE: publisher_subscribers are all the subscribers that are associated with a publisher (market).  This was
  # originally the subscribers association, and it's now being used the the daily reports.  subscribers_with_no_market are all
  # subscribers not associated with a particular publisher (market).  This change was made to accomodate TWC
  # publishing group landing page and collecting email, name and zip if their market has NOT started offering deals.
  #
  has_many :publisher_subscribers, :through => :publishers, :source => :subscribers
  has_many :subscribers_with_no_market, :foreign_key => "publishing_group_id", :class_name => "Subscriber"
  
  has_many :user_companies, :as => :company, :dependent => :destroy
  has_many :users, :through => :user_companies

  has_many :daily_deals, :through => :publishers
  has_many :daily_deal_categories, :dependent => :destroy
  has_many :platform_revenue_sharing_agreements, :as => :agreement, :class_name => "Accounting::PlatformRevenueSharingAgreement", :dependent => :destroy
  has_many :syndication_revenue_sharing_agreements, :as => :agreement, :class_name => "Accounting::SyndicationRevenueSharingAgreement", :dependent => :destroy
  
  has_and_belongs_to_many :categories

  has_many :publisher_membership_codes, :through => :publishers

  has_many :promotions

  has_many :publisher_zip_codes, :through => :publishers
  
  validates_presence_of :name
  validates_presence_of :unique_email_across_publishing_group, :if => :allow_single_sign_on?, :message => "Consumer/Subscriber email addresses must be unique to enable Single Sign On"
  validates_presence_of :unique_email_across_publishing_group, :if => :allow_publisher_switch_on_login?, :message => "Consumer/Subscriber email addresses must be unique to enable Allow Publisher Switch On Login"
  validates_uniqueness_of :name, :message => "Publishing group name '%{value}' has already been taken"
  validates_format_of :google_analytics_account_ids, :with => /^((UA-\d+-\d{1,2})(, ?UA-\d+-\d{1,2})*)?$/
  validates_inclusion_of :paychex_initial_payment_percentage, :in => 0..100, :allow_blank => true
  validates_numericality_of :paychex_num_days_after_which_full_payment_released, :greater_than_or_equal_to => 4, :allow_blank => true
  validates_presence_of :paychex_initial_payment_percentage, :if => :uses_paychex?
  validates_presence_of :paychex_num_days_after_which_full_payment_released, :if => :uses_paychex?
  validate :advertiser_financial_detail_present_when_federal_tax_id_required
  validate :enabled_locales_exist

  before_validation :set_default_how_it_works
  
  named_scope :manageable_by, lambda { |user| user.manageable_publishing_groups_scope }
  named_scope :with_publishers, :include => :publishers
  
  configurable_property :display_text

  audited :only => :merchant_account_id

  has_attached_file :logo,
                  :bucket => "logos.publishing-groups.analoganalytics.com",
                  :s3_host_alias => "logos.publishing-groups.analoganalytics.com",
                  :default_style => :normal,
                  :styles => {
                    :full_size => { :geometry => "100x100%", :format => :jpg },
                    :normal =>    { :geometry => "240x90>",  :format => :png }
                  }

  serialize :enabled_locales, Array

  def observable_publishers_scope(user = nil)
    if user && user.manageable_publishers.present?
      { :conditions => { :id => user.manageable_publisher_ids }}
    else
      { :conditions => { :publishing_group_id => id }}
    end
  end

  def manageable_publishers_scope(user = nil)
    self_serve ? observable_publishers_scope(user) : User::EMPTY_SCOPE
  end

  def observable_advertisers_scope(user = nil)
    if user && user.manageable_publishers.present?
      { :include => :publisher, :conditions => { 'publishers.id' => user.manageable_publisher_ids }}
    else
      { :include => :publisher, :conditions => { 'publishers.publishing_group_id' => id }}
    end
  end

  def manageable_advertisers_scope(user = nil)
    self_serve ? observable_advertisers_scope(user) : User::EMPTY_SCOPE
  end

  def live_publishers
    publishers.select {|p| p.launched? }
  end
  
  # Chaining :through didn't work
  def daily_deal_purchases
    DailyDealPurchase.for_company(self)
  end

  def all_daily_deal_purchases
    BaseDailyDealPurchase.for_company(self)
  end
    
  def daily_deal_certificates(conditions = [])
    if conditions.empty?
      conditions = [ "daily_deals.publisher_id in (?)", publishers.map(&:id)]
    else
      conditions = ["daily_deals.publisher_id in (?) AND #{conditions[0]}", publishers.map(&:id)] + conditions[1..-1]
    end

    DailyDealCertificate.all :include => { :daily_deal_purchase => :daily_deal }, 
                             :conditions => conditions
  end

  def featured_deals_excluding_publisher(publisher)
    publishers.reject { |p| p == publisher}.map { |p| p.daily_deals.current_or_previous }.compact
  end

  def available_categories
    if categories.present?
      categories
    else
      Category.all
    end
  end

  def <=>(other)
    # return -1 unless other
    name <=> other.try(:name)
  end
  
  def to_s
    "#<PublishingGroup #{id} #{name}>"
  end   
  
  def to_liquid
    Drop::PublishingGroup.new( self )
  end

  def country
    publishers.first.try(:country)
  end

  def default_publisher_for_subscribers
    publishers.find_by_label("entertainment") if label == "entertainment"
  end

  def daily_deal_name
    display_text_for(:daily_deal_name)
  end
  
  def silverpop
    @silverpop ||= Analog::ThirdPartyApi::Silverpop.new(silverpop_api_host,
                                                        silverpop_api_username,
                                                        silverpop_api_password)
  end

  def main_publisher
    publishers.detect(&:main_publisher?)
  end

  private
  
  def advertiser_financial_detail_present_when_federal_tax_id_required
    if require_federal_tax_id && !advertiser_financial_detail
      errors.add(:require_federal_tax_id, "%{attribute} can not be set when advertiser financial detail is not set.")
    end
  end

  def set_default_how_it_works
    unless how_it_works
      self.how_it_works = %Q{h4. Click and Buy

Every day we'll announce a new #{daily_deal_name} that is 50-90% off of regular prices at 
restaurants, spas, events and other local goodies.

h4. Share

When you find an offer you like, share it with your friends using our Facebook, Twitter or email links.

h4. Print

After you make a purchase, you'll receive the Deal of the Day voucher to print out via email.

Take the Deal of the Day to the store or merchant any time before the expiration date to enjoy 
the fruits of your labor.
}
    end
  end

end
