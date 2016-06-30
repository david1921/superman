# Category and subcategory are both added to categories association.
# Example: "Food: Italian" added as "Food" and "Food: Italian."
# Duplicate category names allowed if they have different parents.
class Offer < ActiveRecord::Base
  include Report::Offer
  include ActsAsOffer
  include ActsAsShareable 
  include HasListing
  include HasPublisherDependentAttachments 
  include ActsAsSoftDeletable 

  DEFAULT_TERMS = "One coupon per customer while supplies last"
  ALLOWED_FEATURED_VALUES = %w( none category all both )
  
  attr_writer :category_names    
  
  has_and_belongs_to_many :categories, :before_add => :ensure_unique
  has_many :leads
  has_many :impression_counts, :as => :viewable, :dependent => :destroy  
  has_many :click_counts, :as => :clickable, :dependent => :destroy  
  has_many :voice_messages, :through => :leads
  has_many :txts, :through => :leads
  has_many :placements, :dependent => :destroy
  
  has_attached_file :photo,
                    :bucket => "photos.offers.analoganalytics.com",
                    :s3_host_alias => "photos.offers.analoganalytics.com",
                    :default_style => :normal,
                    :styles => { 
                          :large => { :geometry => "350x550",  :format => :jpg },
                         :normal => { :geometry => "200x208>", :format => :png },
                       :standard => { :geometry => "128x90>",  :format => :png },
                      :thumbnail => { :geometry => "60x60",    :format => :png}
                     },
                     :s3_credentials => "#{Rails.root}/config/paperclip_s3.yml"

  has_attached_file :offer_image,
                    :bucket => "offer-images.offers.analoganalytics.com",
                    :s3_host_alias => "offer-images.offers.analoganalytics.com",
                    :styles => publisher_dependent_attachment_styles({
                      :full_size => { :geometry => "100x100%", :format => :jpg },
                          :large => { :geometry => "350x550>", :format => :png },
                         :medium => { :geometry => "240x90>",  :format => :png },
                      :thumbnail => { :geometry => "100x30>",  :format => :png }
                    })

  before_validation :convert_featured_to_allowed_values                    
  
  validates_presence_of     :message
  validates_presence_of     :txt_message, :if => :allow_txt?
  validates_email           :email, :allow_nil => true, :allow_blank => true
  validates_uniqueness_of   :label, :scope => :advertiser_id, :allow_blank => true
  validates_inclusion_of    :featured, :in => ALLOWED_FEATURED_VALUES
  validates_immutability_of :advertiser_id   
  validates_listing :unique_scope => :advertiser_id
  
  validates_each :map_url, :allow_blank => true do |record, attr, value|
    uri = URI.parse(value) rescue nil
    record.errors.add attr, '%{attribute} must be an HTTP or HTTPS URL' unless uri && (uri.scheme == "http" || uri.scheme == "https")
  end
  validates_each :txt_message, :allow_blank => true do |record, attr, value|
    record.errors.add attr, '%{attribute} contains one or more disallowed characters' unless value.to_s.sms_safe?
  end
  validate :schedule_dates_order
  validate :active_limit_enforced
  validate :txt_message_length
  validate :category_objects

  before_save :set_default_terms
  before_save :set_offer_image_dimensions
  before_save :set_showable
  before_save :create_missing_parent_categories
  after_save :set_placements
  after_save :save_category_objects
  after_create :set_label_if_blank
  after_create :generate_coupon_code 
  after_save   :send_publisher_notification
  
  VERSIONED_COLUMNS = [ :show_on, :expires_at, :deleted_at ]
   audited :only => VERSIONED_COLUMNS
  
  named_scope :active, lambda {
    date = Time.zone.now.to_date
    { :conditions => ["showable AND (show_on IS NULL OR :date >= show_on) AND (expires_on IS NULL OR :date <= expires_on)", { :date => date }] }
  }
  named_scope :active_on, lambda { |date|
    { :conditions => ["showable AND (show_on IS NULL OR :date >= show_on) AND (expires_on IS NULL OR :date <= expires_on)", { :date => date }] }
  }
  named_scope :unexpired, lambda {
    date = Time.zone.now.to_date
    { :conditions => ["showable AND (expires_on IS NULL OR expires_on >= :date)", { :date => date }] }
  }
  named_scope :for_advertisers, lambda { |advertiser_ids| { :conditions => ["advertisers.id in (?)", advertiser_ids] }}
  
  named_scope :in_zips, lambda { |zips| { :include => { :advertiser => :stores }, :conditions => ["SUBSTR(stores.zip, 1, 5) in (?)", zips] }}
  
  named_scope :in_categories, lambda { |category_ids| {
    :include => :categories,
    :conditions => ["(categories.id in (:category_ids) OR categories.parent_id in (:category_ids))", { :category_ids => category_ids }]
  }} 
  
  named_scope :in_publishers, lambda { |publisher_ids| {
    :include => [:advertiser],
    :conditions => ["advertisers.publisher_id in (:publisher_ids)", {:publisher_ids => publisher_ids}] 
  }}
  
  named_scope :placed_in_publishers, lambda {|publisher_ids| {
    :include => [:placements],
    :conditions => ["placements.publisher_id in (:publisher_ids)", {:publisher_ids => publisher_ids}]
  }}
  
  named_scope :with_text, lambda { |text| { 
    :include => [:categories, :advertiser, {:advertiser => :translations}],
    :conditions => ["(offers.message LIKE :text OR advertiser_translations.name LIKE :text OR categories.name LIKE :text)", {:text => "%#{text}%"}]
  }}
    
  named_scope :updated_before, lambda { |time| {
    :conditions => ["offers.updated_at <= ?", time]
  }}
  
  named_scope :updated_between, lambda { |time_min, time_max| {
    :conditions => ["offers.updated_at BETWEEN ? AND ?", time_min, time_max]
  }}
  
  named_scope :manageable_by, lambda { |user|
    manageable_advertisers = Advertiser.manageable_by(user).all

    if user.allow_offer_syndication_access
      advertisers_predicate = "offers.advertiser_id IN (?) OR" if manageable_advertisers.present?
      {:conditions => ["#{advertisers_predicate} publishers.offers_available_for_syndication = TRUE", manageable_advertisers],
       :joins => {:placements => :publisher}}
    else
      {:conditions => {:advertiser_id => manageable_advertisers}}
    end
  }
 
  named_scope :by_popularity, :order => "popularity desc"
    
  named_scope :limit, lambda {|count| 
    {
      :limit => count
    }
  }  
 
  named_scope :by_featured, { :conditions => ["offers.featured in (?)", (ALLOWED_FEATURED_VALUES - ["none"])]}
  named_scope :featured_for_landing_page, { :conditions => ["offers.featured in (?)", (ALLOWED_FEATURED_VALUES - ["none", "category"])] }
 
  named_scope :by_publishing_group, lambda {|publishing_group|
    {
      :include => [:advertiser],
      :conditions => ["advertisers.publisher_id in (?)", publishing_group.publishers.map(&:id)]
    }
  }
  
  named_scope :by_coupon_code, lambda {|coupon_code| 
    {
      :conditions => {:coupon_code => coupon_code}
    }
  }

  named_scope :syndicated, :conditions => "publishers.offers_available_for_syndication = TRUE", :joins => {:placements => :publisher}
  
  named_scope :active_between, lambda { |date_range|
    sql = "offers.deleted_at IS NULL AND ((show_on BETWEEN :bod AND :eod) OR (expires_on BETWEEN :bod AND :eod) OR (show_on <= :bod AND expires_on >= :eod))"
    { :conditions => [sql, { :bod => date_range.first.beginning_of_day, :eod => date_range.last.end_of_day }] }
  }

  def self.find_by_publisher(publisher)
    offer_ids = Offer.connection.select_values(%Q{
                select offers.id from offers
                join advertisers on advertisers.id = offers.advertiser_id
                where advertisers.publisher_id = #{publisher.id}
              })
    Offer.find(offer_ids.sample)
  end 
  #
  # params: Hash or SearchRequest
  # 
  # Lots of in-memory manipulation to avoid complicated SQL. Probably needs to move to SQL.
  # Though tests show that finds take < 1 second with 1,000 offers in the database.
  #
  # Only top-level find_all_for_publisher knows about SearchRequest. Helper methods work
  # with minimal set of basic params. Better for unit-testing.
  #
  def self.find_all_for_publisher(*search_request)
    benchmark "Offer#find_all_for_publisher" do
      search_request = SearchRequest.create(search_request)
      if search_request.no_zip_for_city_and_state?
        return []
      end

      zip_codes = zip_codes_from_search_request(search_request)
      if search_request.postal_code.present? && zip_codes.empty?        
        return []
      end

      publisher = search_request.publisher
      category_ids = category_ids_from_search_request(search_request)
      search_text = search_request.text
      #
      # Note below offers.class == ActiveRecord::NamedScope::Scope: no hits to the DB here.
      # 
      if search_by_publishers_publishing_group?(search_request)
        offers = Offer.in_publishers(publisher.publishing_group.publishers.collect(&:id)).active
      else
        offers = publisher.placed_offers.active
      end      
      offers = offers.in_categories(category_ids) if category_ids.any?
      offers = offers.in_zips(zip_codes) if zip_codes.any?
      offers = offers.with_text(search_text) if search_text.present?
      offers = offers.by_featured if search_request.featured?
      offers
    end
  end

  def self.search_by_publishers_publishing_group?(search_request) 
    search_request.publisher.search_by_publishing_group?    
  end
  
  # responsible for getting the correct zip codes from the SearchRequest.
  def self.zip_codes_from_search_request(search_request)
    if search_request.postal_code.present?
      ZipCode.zips_near_zip_and_radius search_request.postal_code, search_request.radius
    else
      []
    end
  end 
  
  def self.category_ids_from_search_request(search_request)
    search_request.categories.collect(&:id).uniq     
  end
  
  def self.advertiser_ids_from_search_request(search_request)
    return [] if search_request.text.blank?  
    search_request.publisher.advertisers.find_all_with_name_like(search_request.text).collect(&:id)
  end
  
  def self.select_subcategories(publisher, offers, category)
    subcategories_hash = offers.inject({}) do |hash, offer|
      offer.categories.select { |c| c.parent == category }.each do |subcategory|
        if hash[subcategory]
          hash[subcategory] = hash[subcategory] + 1
        else
          hash[subcategory] = 1
        end
      end
      hash
    end
    subcategories = []
    subcategories_hash.each do |subcategory, offers_count|
      subcategory[:offers_count] = offers_count
      subcategories << subcategory
    end
    subcategories
  end

  def self.compare(a, b, with_category, randomize, order_param)
    if with_category
      a_featured = a.feature_with_category? ? 1 : 0
      b_featured = b.feature_with_category? ? 1 : 0
    else
      a_featured = a.feature_without_category? ? 1 : 0
      b_featured = b.feature_without_category? ? 1 : 0
    end
    if 0 == (cmp = b_featured - a_featured)
      cmp = randomize ? ((a.id ^ order_param) <=> (b.id ^ order_param)) : (a.advertiser_name <=> b.advertiser_name)
    end
    cmp
  end

  # Paperclip doesn't believe in persisting attachment dimensions
  def set_offer_image_dimensions
    if offer_image.queued_for_write[:full_size]
      geometry = Paperclip::Geometry.from_file(offer_image.queued_for_write[:full_size])
      self.offer_image_width = geometry.width
      self.offer_image_height = geometry.height
    end
  end
  
  # copies the offer image to photo.
  # NOTE: does not save, use copy_offer_image_to_photo!
  # if you want to copy and save in one call.
  def copy_offer_image_to_photo
    unless self.offer_image.nil?
      original_file = self.offer_image.url(:original)
      unless original_file.nil? 
        original_file_path = "#{RAILS_ROOT}/public#{original_file}"
        if File.exists?(original_file_path)
          file = File.new(original_file_path)
          self.photo = file
        end
      end
    end
  end
  
  # copies the offer image to photo and saves
  def copy_offer_image_to_photo!
    self.copy_offer_image_to_photo
    self.save
  end
  
  def set_label_if_blank
    update_attribute(:label, id) if label.blank?
  end

  def ensure_unique(category)
    if categories.include? category
      raise ActiveRecord::ActiveRecordError, "Offer already has '#{category.name}' category"
    end
  end
  
  def category_names
    return case
    when @category_names.present?
      @category_names
    else
      lowest_categories.map(&:full_name).sort.join(", ")
    end
  end  

  def categories_to_xml(markup, postfix=nil)
    if categories.any?
      markup.categories do
        categories.group_by(&:parent).tap do |hash|
          hash[nil].each do |parent|
            markup.category(:id => "#{parent.id}#{postfix}") do
              markup.name(parent.name)
              if (children = hash[parent])
                markup.categories do
                  children.each do |child|
                    markup.category(:id => "#{child.id}#{postfix}") do
                      markup.name(child.name)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def set_default_terms
    self.terms = DEFAULT_TERMS.dup if terms.blank?
  end

  def image
    offer_image.file? ? offer_image : advertiser.logo
  end
  
  def allow_txt?
    advertiser.try(:allows_clipping_via, :txt)
  end
  
  def updated_since?(time)
    updated_at > time || advertiser.updated_at > time
  end

  def click_through_rate
    if self.impressions.nil? || self.impressions == 0
      0
    else
      self.clicks / self.impressions.to_f
    end
  end

  def record_impression(publisher_id)
    ImpressionCount.record self, publisher_id
  end
    
  def impressions
    impression_counts.sum(:count)
  end
  
  def record_click(publisher_id, mode = nil)
    ClickCount.record self, publisher_id, mode
  end
    
  def clicks
    click_counts.sum(:count)
  end 
  
  # calculates the popularity of the offer based on # of clicks
  # in the last 7 days based on a decaying average.  So the clicks
  # today are weighted higher than clicks yesterday.
  def update_popularity!
    update_attributes!(:popularity => calculate_popularity)
  end

  def <=>(other)
    if other
      self.id <=> other.id
    elsif other && self.id == other.id
      0
    else
      -1
    end
  end

  def to_s
    "#<Offer #{id} #{advertiser_name} #{message}>"
  end

  def txt_head
    advertiser.try(:publisher).try(:brand_txt_header)
  end
    
  def txt_body
    body = txt_message.present? ? txt_message : message
  end

  def txt_foot
    items = []
    items << "Exp#{expires_on.strftime('%m/%d/%y')}" if expires_on.present? && auto_insert_expiration_date?
    items << "#{coupon_code}" unless coupon_code.blank?
    items.empty? ? nil : items.join(" ")
  end
  
  def terms_with_expiration
    terms.dup.tap do |text|
      text.strip!
      text.sub!(/\.$/, '')
      text << "."
      text << " #{expiration}" if expires_on.present? && auto_insert_expiration_date?
    end
  end
  
  def terms_with_expiration_as_textiled
    RedCloth.new( terms_with_expiration ).to_html
  end
  
  def terms_as_textiled
    RedCloth.new( terms ).to_html
  end
  
  def expiration
    expires_on.present? ? "Expires #{expires_on.strftime('%m/%d/%y')}." : ""
  end
  
  def active_date
    show_on || created_at
  end
  
  def coupon_code?
    !coupon_code.blank?
  end
  
  def generate_coupon_code(force = false)
    if (coupon_code.blank? || force) && publisher && publisher.generate_coupon_code?
      code = "#{publisher.coupon_code_prefix.strip}#{self.id + 1000}"
      self.update_attributes!(:coupon_code => code)
    end 
  end
  
  def show_small_icons?
    publisher.nil? ? false : publisher.show_small_icons?
  end
  
  def max_txt_message_length
    MobilePhone.max_body_length(:head => txt_head, :foot => txt_foot)
  end 

  # Should the offer should be featured within a category search?
  def feature_with_category?
    if @feature_with_category.nil?
      @feature_with_category = %w(category both).include?(featured)
    end
    @feature_with_category
  end
  
  def feature_with_category
    feature_with_category? ? 1 : 0
  end

  # Should the offer should be featured within a search not being filtered by category?
  def feature_without_category?
    if @feature_without_category.nil?
      @feature_without_category = %w(all both).include?(featured)
    end
    @feature_without_category
  end
  
  def feature_without_category
    feature_without_category? ? 1 : 0
  end
  
  def place_with(publishers)
    publishers = [*publishers]
    placements.each { |placement| placement.destroy unless publishers.include?(placement.publisher) }
    publishers.each { |publisher| placements.create :publisher => publisher if placements.for_publisher(publisher).empty? }
  end
  
  def bit_ly_path(use_publisher=nil)
    params = {
      "publisher_id" => use_publisher ? use_publisher.to_param : self.publisher.to_param,
      "offer_id" => self.to_param
    }
    path_format = advertiser.publisher.bit_ly_path_format(:offers) || "publishers/:publisher_id/offers?offer_id=:offer_id"
    %w{ publisher_id offer_id }.inject(path_format) do |result, tag|
      result.gsub(/:#{tag}/) { |_| params[tag] }
    end
  end
  
  def url_for_bit_ly
    "http://#{advertiser.publisher.host}/#{bit_ly_path}"
  end 
  
  def listing?   
    advertiser.publisher.offer_has_listing?
  end
  
  def publisher_id
    advertiser.publisher_id
  end 
  
  def to_liquid
    Drop::Offer.new(self)
  end
  
  def self_or_advertiser_or_store_last_updated_at
    [self, advertiser, advertiser.try(:store)].map { |object| object.try(:updated_at) }.compact.max
  end
  
  private

  # responsible for getting the lowest child category.
  def lowest_categories
    categories.reject { |category| categories.any? { |child| child.parent == category } }
  end
  
  def create_missing_parent_categories
    lowest_categories.each do |child|
      if child.parent.present? && !categories.include?(child.parent)
        categories << child.parent
      end
    end
  end
  
  def active_count_less_than(offers, limit)
    #
    # 1: Total offer count is less than N
    #
    return true if offers.size < limit
    #
    # 2: N or more offers unbounded in the future
    #
    return false if offers.select { |offer| offer.expires_on.nil? }.size >= limit
    #
    # 3: N or more offers unbounded in the past and ending today or later
    #
    today = Time.zone.now.to_date
    return false if offers.select { |offer| offer.show_on.nil? && (offer.expires_on.nil? || offer.expires_on >= today) }.size >= limit
    
    min_date, max_date = [[:show_on, :min], [:expires_on, :max]].map { |attr, func| offers.map(&attr).compact.send(func) }
    #
    # 4: Latest end date is before today: check 2 covers false-return case
    #
    return true if max_date < today # !max_date.nil? after checks 1 and 2
    
    min_date = today unless min_date && min_date >= today
    min_date, max_date = max_date, min_date if min_date > max_date
    (min_date..max_date).all? { |date| offers.sum { |offer| offer.active_on?(date) ? 1 : 0 } < limit }
  end
  
  def active_limit_enforced
    if (limit = advertiser.try(:effective_active_coupon_limit)).present? && !deleted?
      offers = Set.new(advertiser.offers.not_deleted.reject { |offer| offer.id == id }).add(self)
      unless active_count_less_than(offers, limit.succ)
        many = case limit; when 0: "any active coupons"; when 1: "more than 1 active coupon"; else "more than #{limit} active coupons"; end
        errors.add_to_base "Can't have #{many}"
      end
    end
  end
  
  def schedule_dates_order
    errors.add(:show_on, "%{attribute} date cannot be after expiration date") if show_on.present? && expires_on.present? && show_on > expires_on
  end
  
  def txt_message_length
    if txt_message.to_s.length > (max_length = max_txt_message_length)
      errors.add :txt_message, "%{attribute} is too long (maximum is #{max_length} characters)"
    end
  end 

  def convert_featured_to_allowed_values
    self.featured = featured.to_s.strip
    self.featured = "none" if featured.blank?
    if !ALLOWED_FEATURED_VALUES.include?(featured) && (0 .. ALLOWED_FEATURED_VALUES.size).map(&:to_s).include?(featured)
      self.featured = ALLOWED_FEATURED_VALUES[featured.to_i]
    end
  end
  
  def set_placements
    Placement.place_offer self
  end
  
  def category_objects
    begin
      @category_objects = Category.valid_objects_from_names(@category_names) if @category_names

      available_categories = advertiser.publisher.try(:publishing_group).try(:categories)
      if available_categories.present?
        invalid_categories = []
        all_categories = (@category_objects || []) + categories

        all_categories.each do |category|
          unless available_categories.include? category
            invalid_categories << category.name
          end
        end

        if invalid_categories.present?
          errors.add :categories, "%{attribute} not allowed by the offer's publishers: #{invalid_categories.join(', ')}"
        end
      end

    rescue RuntimeError => e
      errors.add :categories, e.to_s
      @category_objects = nil
    end
  end

  def save_category_objects
    self.categories = @category_objects if @category_objects
    @category_names = nil
  end
  
  def set_showable
    self.advertiser_active = advertiser ? advertiser.active? : false
    self.showable = advertiser_active && !deleted?
    true
  end
  
  def send_publisher_notification    
    if publisher && !@publisher_notification_sent
      publisher.coupon_changed! self
      @publisher_notification_sent = true
    end
  end

  def calculate_popularity
    today  = Time.zone.now     
    clicks_by_time_and_count_since(Time.zone.now - 7.days).inject(0.0) do |sum, click_by_time_and_count| 

        time, count = click_by_time_and_count # splits array, first value is time and second value is count
        days_ago = ((today - time) / 86400).to_i

        unless days_ago == 0
          sum += (count.to_f)*(0.8**days_ago) 
        else
          sum += (count.to_f)
        end

    end    
  end 
  
  def clicks_by_time_and_count_since(date)
    click_counts.sum(:count, :conditions => ["created_at >= ?", date], :group => "created_at")    
  end 
end
