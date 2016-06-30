module Publishers
  module PushNotifications

    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods

      # started at in the last 24 hours is to help protect us from sending
      # out notifications that have already started when an admin turns on
      # push notifications for a publisher (this was an assumption)
      def daily_deals_requiring_notifications
        return daily_deals.active.started_in_last_24_hours.to_notify_consumers
      end
      
      
      # responsible for sending out push notifications for all daily deals that
      # require the consumer to be notified.  the notifications are sent to all
      # or specified devices.
      #
      # options:
      #    devices - can be an array of push notification device tokens, and only 
      #              notifications will be sent to these devices. default is to
      #              send to all devices.
      #
      # requirement:
      #    publisher mush have send_daily_deal_push_notifications set to true.
      #    publisher must have a pem file in config/apns/:label.pem
      def send_push_notifications!(options = {})
        return false if push_notification_devices.empty?
        return false if daily_deals_requiring_notifications.empty?
        devices = options[:devices] && options[:devices].any? ? push_notification_devices.by_tokens(options[:devices]) : push_notification_devices
        daily_deals_requiring_notifications.each do |deal|
          # TODO: need to set the push_notifications_sent_at for daily deal
          devices.each do |device|
            device.send_notification!(deal.value_proposition)
          end
          deal.push_notifications_sent!
        end
      end

    end
    
  end
end
