module Users
  module Lockable
    MAXIMUM_FAILED_ATTEMPTS = 5
    LOG_PREFIX = "Account Locking"
    LOG_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M"

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :alias_method_chain, :successful_login!, :lockable
      base.send :alias_method_chain, :failed_login!, :lockable
      base.send :named_scope, :locked, :conditions => "locked_at IS NOT NULL", :order => "locked_at DESC"
    end

    def self.log_account_locking_activity(msg)
      Rails.logger.info("[#{LOG_PREFIX}] #{Time.now.utc.strftime(LOG_TIMESTAMP_FORMAT)}: #{msg}")
    end

    module InstanceMethods

      def lock_access!(initiating_user = nil)
        self.locked_at = Time.now
        save(:validate => false)
        if initiating_user.present?
          ::Users::Lockable.log_account_locking_activity("User #{login} locked by #{initiating_user.login}")
        else
          ::Users::Lockable.log_account_locking_activity("User #{login} locked due to too many failed login attempts (#{failed_login_attempts})")
        end
      end

      def unlock_access!(initiating_user = nil)
        self.locked_at = nil
        self.failed_login_attempts = 0
        save(:validate => false)
        if initiating_user.present?
          ::Users::Lockable.log_account_locking_activity("User #{login} unlocked by #{initiating_user.login}")
        else
          ::Users::Lockable.log_account_locking_activity("User #{login} unlocked automatically")
        end
      end

      def access_locked?
        locked_at.present?
      end

      def successful_login_with_lockable!
        self.failed_login_attempts = 0
        save(:validate => false)
      end

      def failed_login_with_lockable!
        self.failed_login_attempts ||= 0
        self.failed_login_attempts += 1

        if attempts_exceeded? && !access_locked?
          lock_access!
        else
          save(:validate => false)
        end
      end

      private

      def attempts_exceeded?
        failed_login_attempts >= MAXIMUM_FAILED_ATTEMPTS
      end

    end
  end
end
