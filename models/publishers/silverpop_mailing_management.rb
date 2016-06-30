module Publishers
  module SilverpopMailingManagement

    VALID_EMAIL_BLAST_DAY_NAMES = [""] + Date::DAYNAMES

    def self.included(base)
      base.class_eval do
        has_many :scheduled_mailings
      end
      base.send :include, InstanceMethods
    end

    module InstanceMethods

      # Not sure why the logic in the block is external to the module
      def schedule_todays_silverpop_mailing(&block)
        send_at = send_todays_email_blast_at
        mailing_options = block ? block.call(send_at) : {}
        return if mailing_options.nil?
        return if successful_scheduled_mailing_exists?(send_at)
        schedule_silverpop_mailing(silverpop_list_identifier,
                                   silverpop_template_identifier,
                                   base_mailing_name(send_at),
                                   send_at,
                                   silverpop_account_time_zone,
                                   mailing_options)
      end

      def schedule_this_weeks_silverpop_mailings
        return unless configured_to_schedule_weekly_emails?
        send_at = send_this_weeks_email_blast_at
        return unless in_weekly_blast_scheduling_window?(send_at)
        return unless active_featured_deal_at?(send_at)
        return if weekly_email_already_scheduled?(send_at)
        deal = daily_deal_for_email_blast(send_at)
        schedule_weekly_email_blast_for_seed_list_if_configured(send_at, deal)
        schedule_weekly_email_blast_for_contact_list_if_configured(send_at, deal)
      end

      def silverpop
        publishing_group.silverpop
      end

      def silverpop_account_time_zone
        # nil ok
        publishing_group.try(:silverpop_account_time_zone)
      end

      def configured_to_schedule_weekly_emails?
        (send_weekly_email_blast_to_contact_list || send_weekly_email_blast_to_seed_list) && email_blast_day_of_week
      end

      def successful_scheduled_mailing_exists?(send_at)
        scheduled_mailings.successful.exists?(:mailing_date => localize_date(send_at))
      end

      def schedule_silverpop_mailing(list_id, template_identifier, mailing_name, send_at, time_zone, mailing_options)
        scheduled_mailing = scheduled_mailings.create! :mailing_date => localize_date(send_at), :mailing_name => mailing_name
        begin
          mailing_id = nil
          options = {
            :template_id => template_identifier,
            :list_id => list_id,
            :mailing_name => mailing_name,
            :send_at => send_at,
            :time_zone => time_zone
          }.merge(mailing_options || {})
          silverpop.open do |session|
            mailing_id = session.schedule_mailing(options)
          end
          if mailing_id.present?
            scheduled_mailing.remote_mailing_id = mailing_id
            scheduled_mailing.success_at = Time.zone.now
          else
            raise RuntimeError, "no mailing_id returned from silverpop"
          end
        rescue => e
          scheduled_mailing.error_at = Time.zone.now
          scheduled_mailing.error_message = e.message
          raise e
        ensure
          scheduled_mailing.save!
        end
      end

      def send_this_weeks_email_blast_at
        raise "Publisher #{label} is missing email blast day of week" unless email_blast_day_of_week.present?
        # We subtract 1 day because beginning_of_week returns Sunday and Date::DAYNAMES starts on Monday
        offset_into_week = Date::DAYNAMES.index(email_blast_day_of_week).days + email_blast_hour.hours + email_blast_minute.minutes - 1.day
        publisher_now.beginning_of_week + offset_into_week
      end

      def daily_deal_for_email_blast(blast_time)
        daily_deals.featured_at(blast_time).first
      end

      def active_featured_deal_at?(time)
        daily_deal_for_email_blast(time).present?
      end

      def weekly_email_already_scheduled?(time)
        scheduled_mailings.mailing_date_between(time.beginning_of_week..time.end_of_week).present?
      end

      def publisher_now
        Time.zone.now.in_time_zone(time_zone)
      end

      def in_weekly_blast_scheduling_window?(send_at)
        time_until_blast = (send_at - publisher_now)
        time_until_blast >= 0 && time_until_blast <= weekly_email_blast_scheduling_window_start_in_hours.hours
      end

      def base_mailing_name(send_at)
          "analog-#{label}-#{localize_time(send_at).to_formatted_s(:number)}"
      end

      def weekly_mailing_name(type, send_at)
          "weekly-#{type}-#{base_mailing_name(send_at)}"
      end

      def weekly_mailing_options(daily_deal)
        { :subject => daily_deal.email_blast_subject }
      end

      def schedule_weekly_email_blast_for_contact_list_if_configured(send_at, deal)
        if send_weekly_email_blast_to_contact_list?
          schedule_silverpop_mailing(silverpop_list_identifier,
                                     silverpop_template_identifier,
                                     weekly_mailing_name("contact", send_at),
                                     send_at,
                                     silverpop_account_time_zone,
                                     weekly_mailing_options(deal))
        end
      end

      def schedule_weekly_email_blast_for_seed_list_if_configured(send_at, deal)
        if send_weekly_email_blast_to_seed_list?
          schedule_silverpop_mailing(silverpop_seed_database_identifier,
                                     silverpop_seed_template_identifier,
                                     weekly_mailing_name("seed", send_at),
                                     send_at,
                                     silverpop_account_time_zone,
                                     weekly_mailing_options(deal))
        end
      end

    end

  end
end
