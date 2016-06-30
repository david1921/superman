class TravelsaversBooking < ActiveRecord::Base
  VERSIONED_COLUMNS = [ :book_transaction_id, :book_transaction_xml]
  BROWSER_POLLING_TIME_LIMIT = 30.seconds
  CUSTOMER_SERVICE_NUMBER = 5167303099


  include TravelsaversBookings::Core
  include TravelsaversBookings::Statuses
  include TravelsaversBookings::StateMachine

  def self.version_without_using_audit_module_to_avoid_class_reloading_bug_in_development
    versioned :only => VERSIONED_COLUMNS
  end

  version_without_using_audit_module_to_avoid_class_reloading_bug_in_development

  belongs_to :daily_deal_purchase

  validates_presence_of :daily_deal_purchase
  validates_presence_of :book_transaction_id
  validates_inclusion_of :booking_status, :in => BookingStatus::VALID_STATUSES, :allow_nil => true
  validates_inclusion_of :payment_status, :in => PaymentStatus::VALID_STATUSES, :allow_nil => true
  validates_uniqueness_of :daily_deal_purchase_id
  
  named_scope :unresolved, :conditions => "(%s)" % UNRESOLVED_STATUSES.map { |s| "(booking_status = '%s' AND payment_status = '%s')" % [s[:booking_status], s[:payment_status]] }.join(" OR ")
  named_scope :not_flagged_for_manual_review, :conditions => { :needs_manual_review => false }
  named_scope :successful_bookings_with_any_payment_status, :conditions => ["booking_status = ?", BookingStatus::SUCCESS]
  named_scope :with_service_start_date_in_future_or_nil, lambda {
    { :conditions => ["service_start_date > ? OR service_start_date IS NULL", Time.zone.now] }
  }
  named_scope :with_service_start_date_in_past, lambda {
    { :conditions => ["service_start_date <= ?", Time.zone.now] }
  }
  named_scope :refunded, :joins => "INNER JOIN daily_deal_purchases ddp ON travelsavers_bookings.daily_deal_purchase_id = ddp.id",
                         :conditions => "ddp.payment_status = 'refunded'"

  delegate :has_user_fixable_cc_errors?, :has_errors_that_cant_be_ignored?, :fixable_errors, :unfixable_errors, :checkout_form_values, :has_sold_out_error?,
           :to => :book_transaction
  delegate :refunded?, :daily_deal, :daily_deal_variation, :consumer, :publisher, :to => :daily_deal_purchase

end
