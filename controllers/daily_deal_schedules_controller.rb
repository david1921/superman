class DailyDealSchedulesController < ApplicationController
  before_filter :user_required
  before_filter :admin_privilege_required

  def show
    @publishers = Publisher.launched.allow_daily_deals.any_daily_deals.all(
                    :conditions => ["daily_deals.deleted_at is null and
                      ((daily_deals.side_start_at IS NULL AND daily_deals.side_end_at IS NULL) OR
                        (daily_deals.side_start_at != daily_deals.start_at OR daily_deals.side_end_at != daily_deals.hide_at)) and
                      (daily_deals.start_at between :start_at and :hide_at
                       or daily_deals.hide_at between :start_at and :hide_at
                       or :start_at between daily_deals.start_at and daily_deals.hide_at
                       or :hide_at between daily_deals.start_at and daily_deals.hide_at)",
                                  { :start_at => Time.zone.now.beginning_of_day, :hide_at => Time.zone.now.end_of_day } ],
                    :include => { :advertisers => :daily_deals }
                  )
  end
end
