module Publishers
  module SilverpopSync

    def synchronize_with_silverpop!(silverpop, audit=false, audit_size=nil)
      synchronize_subscribers_with_silverpop(silverpop) unless audit
      synchronize_consumers_with_silverpop(silverpop, audit_size)
      save_silverpop_audit_run! if audit
    end

    def synchronize_subscribers_with_silverpop(silverpop)
      subscribers.each do |subscriber, index|
        subscriber.synchronize_with_silverpop(silverpop)
        increment_silverpop_contacts_processed_counter
        sleep silverpop_sync_sleep_time
      end
    end

    def synchronize_consumers_with_silverpop(silverpop, audit_size = nil)
      consumers.each_with_index do |consumer, index|
        consumer.synchronize_with_silverpop(silverpop, silverpop_audit_run)
        increment_silverpop_contacts_processed_counter
        sleep silverpop_sync_sleep_time
        break if audit_size && index >= (audit_size - 1)
      end
    end

    def silverpop_sync_sleep_time
      0.25
    end

    def silverpop_audit_run
      @silverpop_audit_run ||= create_silverpop_audit_run!
    end

    def create_silverpop_audit_run!
      SilverpopContactAuditRun.create!(:publisher => self, :started_at => Time.zone.now)
    end

    def save_silverpop_audit_run!
      silverpop_audit_run.number_of_contacts_audited = @silverpop_contacts_synched
      silverpop_audit_run.ended_at = Time.zone.now
      silverpop_audit_run.save!
    end

    def increment_silverpop_contacts_processed_counter
      @silverpop_contacts_synched ||= 0
      @silverpop_contacts_synched += 1
    end

  end
end
