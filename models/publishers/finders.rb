module Publishers
  module Finders

    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods

      def find_consumer_by_id(consumer_id)
        consumers.find_by_id(consumer_id)
      end

      def find_consumer_by_email(email)
        consumers.find_by_email(email)
      end

      def find_consumer_in_publishing_group_by_id(consumer_id)
        return nil if self.publishing_group.nil?
        publishing_group.consumers.find_by_id(consumer_id)
      end

      def find_consumer_in_publishing_group_by_email(email)
        return nil if self.publishing_group.nil?
        publishing_group.consumers.find_by_email(email)
      end

      def find_consumer_by_id_if_access_allowed(consumer_id)
        consumer = find_consumer_by_id(consumer_id)
        consumer ||= (find_consumer_in_publishing_group_by_id(consumer_id) if allow_single_sign_on?)
      end

      def find_consumer_by_email_if_access_allowed(email)
        consumer = find_consumer_by_email(email)
        consumer ||= (find_consumer_in_publishing_group_by_email(email) if allow_single_sign_on?)
      end

      def find_consumer_by_email_if_force_password_reset(email)
        consumer = find_consumer_by_email_if_access_allowed(email)
        return nil if consumer.nil?
        consumer.force_password_reset? ? consumer : nil
      end

      def find_consumer_by_email_for_authentication(email)
        consumer = (find_consumer_in_publishing_group_by_email(email) if allow_publisher_switch_on_login?)
        consumer ||= find_consumer_by_email_if_access_allowed(email)
      end

    end
  end
end
