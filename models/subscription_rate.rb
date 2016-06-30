class SubscriptionRate < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  belongs_to :subscription_rate_schedule

  TIME_UNITS = %w{ day week month year }
  
  validates_presence_of     :subscription_rate_schedule
  validates_presence_of     :name
  validates_numericality_of :regular_price, :greater_than_or_equal_to => 0.00, :allow_blank => false
  validates_numericality_of :regular_period, :only_integer => true, :greater_than => 0, :allow_blank => false
  validates_inclusion_of    :regular_time_unit, :in => TIME_UNITS, :allow_blank => false
  validates_numericality_of :recurring_count, :only_integer => true, :greater_than => 0, :allow_blank => true
  
  validate :regular_period_allowed_with_regular_time_unit

  def to_paypal_params
    {
      :a3 => regular_price,
      :p3 => regular_period,
      :sra => 1,
      :src => recurs ? 1 : 0,
      :srt => recurs ? recurring_count : 0,
      :t3 => regular_time_unit[0, 1].upcase
    }
  end
  
  private

  def regular_period_allowed_with_regular_time_unit
    allowed = case regular_time_unit
              when 'day'
                regular_period <= 90
              when 'week'
                regular_period <= 52
              when 'month'
                regular_period <= 24
              when 'year'
                regular_period <= 5
              else
                true
              end
    errors.add(:regular_period, "%{attribute} is invalid for time unit #{regular_time_unit}") unless allowed
  end
end

