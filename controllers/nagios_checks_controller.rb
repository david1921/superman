class NagiosChecksController < ApplicationController

  include Nagios::HttpPlugin

  SANCTIONS_UPLOADS_WIKI_PAGE = "https://analoganalytics.atlassian.net/wiki/display/ops/Sanction+File+Uploads+Broken"

  def ensure_advertiser_sanctions_file_uploaded_before_1pm
    ensure_job_finishes_before_1pm(
      :job_key => "sanction_screening:export_and_uploaded_encrypted_advertiser_file",
      :wiki_page => SANCTIONS_UPLOADS_WIKI_PAGE)
  end

  def ensure_publisher_sanctions_file_uploaded_before_1pm
    ensure_job_finishes_before_1pm(
      :job_key => "sanction_screening:export_and_uploaded_encrypted_publisher_file",
      :wiki_page => SANCTIONS_UPLOADS_WIKI_PAGE)
  end

  def ensure_consumer_sanctions_file_uploaded_before_1pm
    ensure_job_finishes_before_1pm(
      :job_key => "sanction_screening:export_and_uploaded_encrypted_consumer_file",
      :wiki_page => SANCTIONS_UPLOADS_WIKI_PAGE)
  end

  private

  def ensure_job_finishes_before_1pm(options = {})
    job_key = options[:job_key]
    wiki_page = options[:wiki_page]
    unless wiki_page.present?
      raise ArgumentError, "you must provide a wiki help page for job '#{job_key}'" 
    end

    now = Time.zone.now.in_time_zone("Pacific Time (US & Canada)")
    if now.hour < 13
      render_nagios_warning(
        "Too early to check whether #{job_key} completed successfully. This job " +
        "is allowed to finish anytime before 01:00 PM PST, and it's only #{hh_mm_p(now)} right now.") && return
    end

    last_finished_at = Job.last_finished_at(job_key).try(:in_time_zone, "Pacific Time (US & Canada)")
    if last_finished_at.blank? || last_finished_at.day != now.day
      render_nagios_critical(
        "Expected #{job_key} to finish running by 01:00 PM PST today, but it appears to have not run at all. " +
        "See #{wiki_page}")
    elsif last_finished_at.hour == 12 && (00..49).include?(last_finished_at.min)
      render_nagios_ok("#{job_key} finished at #{hh_mm_p(last_finished_at)}")
    elsif last_finished_at.hour == 12 && (50..59).include?(last_finished_at.min)
      render_nagios_warning(
        "Expected #{job_key} to finish running by 01:00 PM PST. It finished at #{hh_mm_p(last_finished_at)}, " +
        "which is fine, but uncomfortably close to the hard cutoff time. We should investigate this ASAP.")
    elsif last_finished_at.hour >= 13
      render_nagios_critical(
        "Expected #{job_key} to finish running by 01:00 PM PST today, but it finished at #{hh_mm_p(last_finished_at)}")
    else
      render_nagios_warning("Failed to match any of the expected check conditions. This checker may not be working right.")
    end

  end

  def hh_mm_p(datetime)
    datetime.strftime("%I:%M %p")
  end

end
