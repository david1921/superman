class SweepstakeEntry < ActiveRecord::Base

  #
  # === Associations
  #
  belongs_to :sweepstake
  belongs_to :consumer
  
  #
  # === Validations
  #
  validates_presence_of   :consumer, :sweepstake
  validates_format_of     :phone_number, :with => /^(1\s*[-\/\.]?)?(\((\d{3})\)|(\d{3}))\s*[-\/\.]?\s*(\d{3})\s*[-\/\.]?\s*(\d{4})\s*(([xX]|[eE][xX][tT])\.?\s*(\d+))*$/
  validates_associated  :consumer
  validate :accepted_terms
  validate :verified_as_an_adult
  validate :verify_within_entry_limits, :if => :sweepstake
  
  #
  # === Delegation
  #
  delegate :value_proposition, :unlimited_entries?, :max_entries_per_period, :max_entries_period, :to => :sweepstake
  delegate :name, :email, :to => :consumer, :allow_nil => true
  
  #
  # === Names Scopes
  #
  named_scope :for_consumer, lambda { | consumer |
    { :conditions => ["consumer_id = :consumer_id", { :consumer_id => consumer.id } ] }
  }
  named_scope :for_sweepstake, lambda { | sweepstake |
    { :conditions => ["sweepstake_id = :sweepstake_id", { :sweepstake_id => sweepstake.id } ] }
  }
  named_scope :created_between, lambda { | bop, eop |
    { :conditions => ["created_at BETWEEN :bop AND :eop", { :bop => bop, :eop => eop } ] }
  }
  
  def exceeds_entry_limits?
    if unlimited_entries?
      false
    else
      consumer_entries_for_sweepstake = SweepstakeEntry.for_consumer(consumer).for_sweepstake(sweepstake)
      case max_entries_period
        when Sweepstake::ENTRY_PERIODS::Day
          existing_entries = 
            consumer_entries_for_sweepstake.created_between(Time.zone.now.beginning_of_day, Time.zone.now.end_of_day)
        when Sweepstake::ENTRY_PERIODS::Hour
          existing_entries = 
            consumer_entries_for_sweepstake.created_between(Time.zone.now - 1.hour, Time.zone.now)
        when Sweepstake::ENTRY_PERIODS::Month
          existing_entries = 
            consumer_entries_for_sweepstake.created_between(Time.zone.now.beginning_of_month, Time.zone.now.end_of_month)
        when Sweepstake::ENTRY_PERIODS::Week
          existing_entries = 
            consumer_entries_for_sweepstake.created_between(Time.zone.now.beginning_of_week, Time.zone.now.end_of_week)
        when Sweepstake::ENTRY_PERIODS::Sweepstake
          existing_entries = consumer_entries_for_sweepstake
        else
          existing_entries = []
      end
      existing_entries.size + 1 > max_entries_per_period
    end
  end
  
  private
  
  def accepted_terms
    unless agree_to_terms
      errors.add_to_base(I18n.t("activerecord.errors.custom.accept_terms_for_sweepstake"))
    end
  end
  
  def verified_as_an_adult
    unless is_an_adult
      errors.add_to_base(I18n.t("activerecord.errors.custom.must_be_18_or_older_for_sweepstake"))
    end
  end
  
  def verify_within_entry_limits
    if exceeds_entry_limits?
      errors.add_to_base(
        I18n.t("activerecord.errors.custom.only_n_entries_allowed_per_period",
               :n_entries => max_entries_per_period, :period => max_entries_period))
    end
  end
  
end
