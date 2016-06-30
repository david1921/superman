# FIXME Move to daily_deals folder
module DailyDealApi
  
  LOG_PREFIX = "[APNs]"
  
  class << self

    def send_push_notifications!
      log("Sending push notifications")
      todays_deal = {}
      num_sent = 0
      PushNotificationDevice.publishers_with_deals_today.each do |publisher|
        value_proposition = truncate(publisher.daily_deals.today.value_proposition, 120) rescue nil
      
        unless value_proposition.present?      
          log_warn("publisher #{publisher.label}'s deal should have a value proposition, but the value proposition is blank")
          next
        end
        
        publisher.push_notification_devices.each do |pnd|
          log("Sending to device token: #{pnd.token}, message: #{value_proposition}")
          APNS.send_notification(pnd.token, value_proposition) unless dry_run?
          num_sent += 1
        end
      end
      log("#{num_sent} push notifications sent")
    end
  
    private
    
    def log(msg)
      log_string = "#{LOG_PREFIX} #{dry_run_prefix}#{msg}"

      if dry_run? && !Rails.env.test?
        puts log_string
      else
        Rails.logger.info log_string
      end
    end
  
    def log_warn(msg)
      log_string = "#{LOG_PREFIX} #{dry_run_prefix}#{msg}"
      if dry_run? && !Rails.env.test?
        puts log_string
      else
        Rails.logger.warn log_string
      end
    end
    
    def truncate(msg, length=100)
      return msg if msg.blank? || msg.length <= length
      return msg[0...length-3] + "..." if msg.length > length
    end
    
    def dry_run_prefix
      dry_run? ? "** dry run ** " : ""
    end
    
    def dry_run?
      ENV["DRY_RUN"].present?
    end
    
  end
  
end