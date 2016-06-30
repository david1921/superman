module Advertisers::Core

  def listing_parts=(parts)
    self.listing = self.class.listing_from_parts(*parts)
  end

  def listing_parts
    self.listing.split("-")
  end

  def ensure_no_daily_deal_purchases
    if daily_deal_purchases(true).present?
      errors.add "Can't delete advertiser with daily deal purchases"
      return false
    end
    true
  end

  def destroy_gift_certificates
    gift_certificates.all?(&:destroy)
  end

  def gift_certificates?
    gift_certificates.available.active.present?
  end

  def message_blank?
    self.message.blank?
  end

  def to_sym
    @symbol ||= self.name.gsub(" ", "").underscore.to_sym
  end

  def default_offer
    offers.first
  end

  def recent_offer
    offers.sort {|a, b| a.active_date <=> b.active_date }.first
  end

  def allows_clipping_via(mode)
    normalize_coupon_clipping_modes unless coupon_clipping_modes.is_a?(Set)
    coupon_clipping_modes.include?(mode.to_sym)
  end

  def allows_clipping_only_via?(*modes)
    normalize_coupon_clipping_modes unless coupon_clipping_modes.is_a?(Set)
    coupon_clipping_modes == Set.new(modes.map(&:to_sym))
  end

  def allow_call?
    allows_clipping_via(:call)
  end

  def call_phone_number_as_entered
    @call_phone_number_as_entered || call_phone_number.to_s.sub(/\A1(\d{3})(\d{3})(\d{4})\Z/, '\1-\2-\3')
  end

  # this is the phone number from the
  # associated Store model.
  def phone_number_as_entered
    store ? store.phone_number_as_entered : nil
  end

  def publisher_name=(value)
    unless value.blank?
      self.publisher = Publisher.find_or_initialize_by_name(value)
    end
  end

  def do_strict_validation?
    publisher.try :do_strict_validation?
  end

  def address?
    store.try :address?
  end

  def address(&block)
    store ? store.address(&block) : []
  end

  def zip
    store.try :zip
  end

  def phone_number?
    store.try(:phone_number).present?
  end

  def formatted_phone_number
    store.try(:formatted_phone_number)
  end

  def map_url
    url = read_attribute(:google_map_url)
    url.present? ? url : store.try(:google_map_url, name)
  end

  def store
    stores.first
  end

  def self_serve?
    publisher.advertiser_self_serve?
  end

  def observable_advertisers_scope(not_used = nil)
    { :conditions => { :id => id }}
  end

  def manageable_advertisers_scope(not_used = nil)
    self_serve? ? observable_advertisers_scope : User::EMPTY_SCOPE
  end

  def to_s
    "#<Advertiser #{id} #{name}>"
  end

  # used by the map ui
  def to_map_json
    to_json(
      :only => [:id, :name, :label],
      :include => {
        :stores => {
          :only => [:longitude, :latitude, :address_line_1, :address_line_2, :city, :state, :zip],
          :methods => [:formatted_phone_number]
        },
        :offers => {
          :only => [:id, :message, :featured, :value_proposition],
          :methods => [:category_names, :expired]
        }
      }
    )
  end

  def effective_active_txt_coupon_limit
    if (publisher_limit = publisher.try(:active_txt_coupon_limit)).present?
      if active_txt_coupon_limit.present?
        [publisher_limit, active_txt_coupon_limit].min
      else
        publisher_limit
      end
    else
      active_txt_coupon_limit
    end
  end

  def effective_active_coupon_limit
    if (publisher_limit = publisher.try(:active_coupon_limit)).present?
      if active_coupon_limit.present?
        [publisher_limit, active_coupon_limit].min
      else
        publisher_limit
      end
    else
      active_coupon_limit
    end
  end

  def txt_keyword_prefixes
    if publisher_prefixes = publisher.try(:txt_keyword_prefixes)
      publisher_prefixes.map do |prefix|
        prefix + txt_keyword_prefix.to_s
      end
    end
  end

  def publisher_has_google_offers_feed_enabled?
    publisher && publisher.enable_google_offers_feed?
  end

  def next_keyword_suffix(prefix)
    publisher.try(:next_keyword_suffix, prefix.sub(/#{Regexp.escape(txt_keyword_prefix.to_s)}\Z/, ""))
  end

  def keyword_error(keyword)
    case
    when !txt_keyword_prefixes.any? { |prefix| keyword =~ /\A#{Regexp.escape(prefix)}/ }
      "%{attribute} has an invalid prefix"
    when  txt_keyword_prefixes.any? { |prefix| keyword == prefix } && txt_keyword_prefix.blank?
      "%{attribute} is too short"
    end
  end

  def logo_dimension_valid_for_facebook?
    logo_facebook_width &&
    logo_facebook_height &&
    logo_facebook_width >= 50 &&
    logo_facebook_height >= 50 &&
    logo_facebook_width <= 130 &&
    logo_facebook_height <= 110 &&
    (logo_facebook_width.to_f / logo_facebook_height) <= 3.0 &&
    (logo_facebook_height.to_f / logo_facebook_width) <= 3.0
  end

  def active?
    !paid || (subscribed? && approved?)
  end

  def subscribed?
    0 < (paypal_subscription_notifications.starting.count - paypal_subscription_notifications.stopping.count)
  end

  def recent_return_from_paypal?
    returned_from_paypal_at && (returned_from_paypal_at >= 1.day.ago)
  end

  def subscription_name
    if subscribed?
      subscription_rate_schedule.name
    else
      "None"
    end
  end

  def paypal_subscription_notification_added
    update_offers_advertiser_active
  end

  def update_offers_advertiser_active
    advertiser_active = active?
    offers.each { |offer| offer.update_attributes! :advertiser_active => advertiser_active }
  end

  def subscription_invoice
    "AD-#{id}-#{paypal_subscription_notifications.starting.count}"
  end

  def multi_location?
    stores.many?
  end

  def to_liquid
    Drop::Advertiser.new(self)
  end

  def after_soft_deletion
    soft_delete_any_offers
    soft_delete_any_daily_deals
    soft_delete_any_deal_certificates # aka, gift certificates
  end

  def deal_markets
    Market.find(:all,
                :joins => "INNER JOIN daily_deals_markets ddm ON markets.id = ddm.market_id INNER JOIN daily_deals dd ON ddm.daily_deal_id = dd.id",
                :conditions => ["dd.advertiser_id = ?", self.id],
                :group => "markets.id",
                :order => "markets.name"
    )
  end

  private

  def soft_delete_any_offers
    offers.each {|o| o.delete! }
  end

  def soft_delete_any_daily_deals
    daily_deals.each {|d| d.delete! }
  end

  def soft_delete_any_deal_certificates
    gift_certificates.each {|c| c.delete! }
  end

  def normalize_coupon_clipping_modes
    self.coupon_clipping_modes = returning(Set.new) do |set|
      if self.coupon_clipping_modes.respond_to?(:each)
        self.coupon_clipping_modes.each do |m|
          mode = m.to_sym rescue nil
          set << mode if Advertiser::RECOGNIZED_COUPON_CLIPPING_MODES.include?(mode)
        end
      end
    end
  end

  def remember_and_normalize_call_phone_number
    @call_phone_number_as_entered = self.call_phone_number
    self.call_phone_number = call_phone_number.phone_digits
  end

  def normalize_urls
    %w{ website_url google_map_url }.each do |attr|
      value = send(attr).to_s.strip
      value = "http://" + value unless value.blank? || value.starts_with?("http")
      send(:"#{attr}=", value) # must be used instead of write_attribute for Globalize support
    end
  end

  def set_default_voice_response_code
    self.voice_response_code = default_voice_response_code if voice_response_code.blank?
    voice_response_code.strip!
  end

  def default_voice_response_code
    @@default_voice_response_code ||= AppConfig.default_voice_response_code || "4957"
  end

  def normalize_txt_keyword_prefix
    self.txt_keyword_prefix = txt_keyword_prefix.to_s.gsub(/\s/, "").upcase
  end

  def set_logo_dimensions
    if logo.queued_for_write[:full_size]
      geometry = Paperclip::Geometry.from_file(logo.queued_for_write[:full_size])
      self.logo_width = geometry.width
      self.logo_height = geometry.height
    end

    if logo.queued_for_write[:facebook]
      geometry = Paperclip::Geometry.from_file(logo.queued_for_write[:facebook])
      self.logo_facebook_width = geometry.width
      self.logo_facebook_height = geometry.height
    end
  end

  def subscription_rate_schedule_belongs_to_publisher
    if publisher.present? && subscription_rate_schedule.present? && subscription_rate_schedule.item_owner != publisher
      errors.add(:subscription_rate_schedule, "%{attribute} does not belong to to this advertiser's publisher")
    end
  end

  def active_subscription_count
    paypal_subscription_notifications(true).starting.count - paypal_subscription_notifications.stopping.count
  end

  def at_least_one_store_for_paychex_publisher
    if publisher.uses_paychex?
      store = stores.first  
      # NOTE: we assign the advertiser here if we don't already have one on the store
      # this is to have correct validation on new advertiser creations.
      store.advertiser ||= self if store
      unless store && store.valid?
        errors.add_to_base("Stores must have at least one valid store")
      end
    end    
  end
end
