module Publishers
  module Core

    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods

      def allow_consumer_access?(consumer)
        return false if consumer.nil?
        return true if self == consumer.publisher
        return allow_single_sign_on? && (self.publishing_group == consumer.publisher.publishing_group)
      end

      def force_password_reset?(email)
        find_consumer_by_email_if_force_password_reset(email).present?
      end

      def enable_daily_deal_variations?
        publishing_group.try(:enable_daily_deal_variations?) || read_attribute(:enable_daily_deal_variations)
      end

      def send_litle_campaign?
        publishing_group.try(:send_litle_campaign) || send_litle_campaign
      end

    end

  end
end
