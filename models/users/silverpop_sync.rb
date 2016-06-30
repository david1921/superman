module Users
  module SilverpopSync

    def synchronize_with_silverpop(sp = nil, audit_run = nil, reraise_silverpop_exception = false)
      @silverpop = sp
      audit_errors = []
      begin
        opt_out_of_silverpop_seed_database(audit_errors)
        add_to_silverpop_database_if_missing(audit_errors)
        remove_from_any_extra_silverpop_contact_lists(audit_errors)
        add_to_publishers_silverpop_contact_list_if_missing(audit_errors)
      rescue => e
        audit_errors << "Could not sync with silverpop #{e.class}: #{e.message}\n#{e.backtrace}"
        raise e if reraise_silverpop_exception
      ensure
        save_audit_errors_if_any(audit_run, audit_errors)
      end
      audit_errors.empty? ? nil : audit_errors
    end

    def synchronize_with_silverpop!(sp = nil, audit_run = nil)
      synchronize_with_silverpop(sp, audit_run, true)
    end

    def silverpop
      @silverpop ||=  publisher.publishing_group.silverpop
    end

    def silverpop_database_identifier
      publisher.publishing_group.silverpop_database_identifier
    end

    def silverpop_seed_database_identifier
      publisher.silverpop_seed_database_identifier
    end

    def silverpop_contact_list_identifier
      publisher.silverpop_list_identifier
    end

    def opt_out_of_silverpop_seed_database(audit_errors = [])
      if silverpop_seed_database_identifier.present?
        if silverpop.recipient_opted_in?(silverpop_seed_database_identifier, email)
          audit_errors << "opting out from seed database"
          silverpop.opt_out_recipient(silverpop_seed_database_identifier, email)
        end
      end
    end

    def add_to_silverpop_database_if_missing(audit_errors = [])
      if silverpop_database_identifier.present?
        unless silverpop.recipient_exists?(silverpop_database_identifier, email)
          audit_errors << "addding recipient #{email} to database"
          silverpop.add_recipient(silverpop_database_identifier, email)
        end
      else
        audit_errors << "silverpop_database identifier is missing"
      end
    end

    def remove_from_any_extra_silverpop_contact_lists(audit_errors = [])
      silverpop.contact_lists_for_recipient(silverpop_database_identifier, email).each do |contact_list_id|
        unless contact_list_id == silverpop_contact_list_identifier
          audit_errors << "removing recipient #{email} from #{contact_list_id}"
          silverpop.remove_recipient(contact_list_id, email)
        end
      end
    end

    def add_to_publishers_silverpop_contact_list_if_missing(audit_errors = [])
      publisher.create_silverpop_contact_list_as_needed!(silverpop)
      contact_lists = silverpop.contact_lists_for_recipient(silverpop_database_identifier, email)
      unless contact_lists.include?(silverpop_contact_list_identifier)
        audit_errors << "adding #{email} to contact list #{silverpop_contact_list_identifier}"
        silverpop.add_contact_to_contact_list(silverpop_contact_list_identifier, email)
      end
    end

    def save_audit_errors_if_any(audit_run, audit_errors = [])
      if audit_run && !audit_errors.empty?
        audit_error = SilverpopContactAuditRunError.new
        audit_error.silverpop_contact_audit_run = audit_run
        audit_error.error_at = Time.zone.now
        audit_error.error_details = audit_errors.join(",")
        audit_error.save!
      end
    end

  end

end
