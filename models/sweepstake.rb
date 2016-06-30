class Sweepstake < ActiveRecord::Base
  include HasPublisherDependentAttachments
  
  acts_as_textiled :description, :short_description, :terms, :value_proposition_subhead, :official_rules
  
  module ENTRY_PERIODS
    Day = "day"
    Hour = "hour"
    Month = "month"
    Sweepstake = "sweepstake"
    Week = "week"
  end
  
  ALLOWED_ENTRY_PERIODS = {
    Sweepstake::ENTRY_PERIODS::Day => "Day",
    Sweepstake::ENTRY_PERIODS::Hour => "Hour",
    Sweepstake::ENTRY_PERIODS::Month => "Month",
    Sweepstake::ENTRY_PERIODS::Sweepstake => "Sweepstake",
    Sweepstake::ENTRY_PERIODS::Week => "Week"
  }
  
  #
  # === Associations
  #
  has_many    :entries, :foreign_key => "sweepstake_id", :class_name => "SweepstakeEntry"
  belongs_to  :publisher
  
  #
  # === Callbacks
  #
  before_save :clear_max_entries, :if => :unlimited_entries
  
  #
  # === Validation
  #
  validates_presence_of :publisher, :value_proposition, :terms, :official_rules
  validates_presence_of :max_entries_period, :unless => :unlimited_entries
  validates_presence_of :max_entries_per_period, :unless => :unlimited_entries
  validate              :start_at_and_hide_at_date_range
  validate              :only_one_active_featured
  
  #
  # === Attachments
  #
  has_attached_file :photo,
                    :bucket => "photos.sweepstakes.analoganalytics.com",
                    :s3_host_alias => "photos.sweepstakes.analoganalytics.com",
                    :default_style => :full,
                    :styles => publisher_dependent_attachment_styles(
                      :full           => { :geometry => "706x334#", :format => :png },
                      :medium         => { :geometry => "508x238#", :format => :png },
                      :thumb          => { :geometry => "50x50%", :format => :png }
                    )

  # 
  # NOTE: the reason for logo and logo-alternate is to accommodate TWC to handle a logo that appears on 
  # a dark background and a light background.
  #
  has_attached_file :logo,
                    :bucket => "logos.sweepstakes.analoganalytics.com",
                    :s3_host_alias => "logos.sweepstakes.analoganalytics.com",
                    :default_style => :full,
                    :styles => publisher_dependent_attachment_styles(
                      :full           => { :geometry => "261x73>", :format => :png },
                      :thumb          => { :geometry => "50x50%", :format => :png }
                    )
                    
  has_attached_file :logo_alternate,
                    :bucket => "logos-alternate.sweepstakes.analoganalytics.com",
                    :s3_host_alias => "logos-alternate.sweepstakes.analoganalytics.com",
                    :default_style => :full,
                    :styles => publisher_dependent_attachment_styles(
                      :full           => { :geometry => "204x62>", :format => :png },
                      :medium         => { :geometry => "155x50>", :format => :png },
                      :thumb          => { :geometry => "50x50%", :format => :png }
                    )

  #
  # === Names Scopes
  #
  named_scope :active,    lambda { { :conditions => ["start_at <= :now AND hide_at > :now", { :now => Time.zone.now } ] }}
  named_scope :featured,  lambda { { :conditions => {:featured => true} } }
  named_scope :except,    lambda { |sweepstake| 
    {
      :conditions => ["sweepstakes.id != ?", sweepstake.id]
    }
  }
  named_scope :with_text, lambda { |text| { 
    :conditions => ["(sweepstakes.description LIKE :text OR sweepstakes.value_proposition LIKE :text)", {:text => "%#{text}%"}]
  }}
  
  #
  # === Class Methods
  #
  
  
  #
  # === Instance Methods
  #
  def to_liquid
    Drop::Sweepstake.new(self)
  end
  
  def humanize_start_at
    start_at.present? ? start_at.to_s(:compact_with_tz) : ""
  end
  
  def humanize_hide_at
    hide_at.present? ? hide_at.to_s(:compact_with_tz) : ""
  end
  
  private
  
  def start_at_and_hide_at_date_range
    if hide_at
      if start_at
        if start_at >= hide_at
          errors.add :hide_at, "%{attribute} must be after start at"
        end
      else
        errors.add :start_at, "%{attribute} must be present"
      end
    end
  end

  
  def clear_max_entries
    self.max_entries_period = nil
    self.max_entries_per_period = nil
  end
  
  def only_one_active_featured
    if publisher && featured
      active_and_featured_overlapping = publisher.sweepstakes.active.featured.first(:conditions => [
        "( :id IS NULL OR id != :id )
         AND hide_at >= :now 
         AND ( start_at  BETWEEN :start_at AND :hide_at
            OR hide_at   BETWEEN :start_at AND :hide_at
            OR :start_at BETWEEN start_at  AND hide_at
            OR :hide_at  BETWEEN start_at  AND hide_at )", 
        { :now => Time.zone.now, :start_at => start_at, :hide_at => hide_at, :id => id }])

      if active_and_featured_overlapping
        errors.add :featured, "There is already one active featured sweepestake"
      end
    end
  end
  
end
