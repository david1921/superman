class Store < ActiveRecord::Base
  include ActsAsLocation
  include Stores::Core

  acts_as_list
  acts_as_location
  belongs_to :advertiser

  attr_accessor :_delete

  #
  # === Version
  #
  audited

  before_validation :assign_country_from_state
  
  validate :country_included_in_publisher_countries, :if => proc { |rec| rec.require_address_or_phone? && rec.address? && !rec.phone_number?}
  validates_immutability_of :advertiser_id
  validates_uniqueness_of :listing, :scope => :advertiser_id, :allow_blank => true
  # we don't valid presence of advertiser or advertiser_id to ignore circular validation errors with nested attributes.
  # plus database schema doesn't allow null advertiser_id

  delegate :launched_at, :to => :publisher
  delegate :publisher, :federal_tax_id, :to => :advertiser

  def require_complete_address?
    advertiser.try(:do_strict_validation?)
  end

  def require_address_or_phone?
    advertiser.try(:do_strict_validation?)
  end

  def to_s
    "#<Store #{id} #{address_line_1} #{address_line_2} #{city} #{state} #{zip} #{phone_number} >"
  end
  
  def address_for_google_geocoding
    address.join(", ")
  end
  
  def country_included_in_publisher_countries
    countries = advertiser.try(:publisher).try(:countries)
    if countries.present?
      unless countries.include?(country)
        error_message = Analog::Themes::I18n.t(advertiser.try(:publisher), "activerecord.errors.custom.not_in_allowed_countries_for_publisher")
        errors.add(:country, error_message)
      end
    end
  end

  def allow_seven_digit_phone_numbers
    advertiser.try(:publisher).try(:allow_seven_digit_advertiser_phone_numbers)
  end

  private

  def validate_full_address_with_store?
    publisher = advertiser.try(:publisher)
    if publisher && publisher.uses_paychex?
      true
    else
      validate_full_address_without_store?
    end
  end
  alias_method_chain :validate_full_address?, :store


end
