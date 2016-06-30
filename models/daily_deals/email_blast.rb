module DailyDeals::EmailBlast

  def self.included(base)
    base.class_eval do
      delegate :send_todays_email_blast_at, :to => :publisher
    end
  end

  # only blast less than 24 hours after a deal becomes featured
  def expected_email_blast_at?(blast_time)
    enable_daily_email_blast && featured_at?(blast_time) && became_featured_within_interval_of?(24.hours, blast_time) &&
        had_no_scheduled_mailing_for_previous_featured_window?(blast_time.to_date)
  end

  private

  def had_no_scheduled_mailing_for_previous_featured_window?(blast_date)
    return true unless featured_date_ranges.size > 1 # no 2nd featured window
    first_window = featured_date_ranges.first
    return true if first_window == current_featured_window # we're in the 1st window
    !publisher.scheduled_mailings.find_by_mailing_date(first_window.begin.to_date) # find mailing on start day of first window
  end

end
