module NewSilverpopRecipients
  module AddRecipientToSilverpop

    def add_recipient_to_silverpop
      raise "publishing group is missing database id" unless database_id.present?
      raise "consumer #{consumer} has no email" unless email.present?
      begin
        silverpop.open do
          capture_silverpop_fields
          remove_old_recipient_from_silverpop
          opt_out_of_silverpop_seed_database
          add_recipient_to_silverpop_database
          remove_from_any_extra_silverpop_contact_lists
          create_silverpop_contact_list
          add_to_silverpop_contact_list
          self.success_at = Time.zone.now
        end
      rescue => e
        self.error_at = Time.zone.now
        self.error_message = "#{e.class.name}: #{e.message}"
        # We want the job to end up in the resque failed queue
        # so we re-raise the exception here
        raise e
      ensure
        save!
      end
    end

    def capture_silverpop_fields
      self.silverpop_seed_database_identifier = seed_database_id
      self.silverpop_database_identifier = database_id
      self.silverpop_list_identifier = contact_list_id
    end

    def remove_old_recipient_from_silverpop
      return unless old_email.present?
      silverpop.remove_recipient(silverpop_database_identifier, old_email)
      self.old_email_removed_at = Time.zone.now
    end

    def silverpop
      publishing_group.silverpop
    end

    def email
      @email ||= consumer.email
    end

    def publishing_group
      @publishing_group ||= consumer.publisher.publishing_group
    end

    def publisher
      @publisher ||= consumer.publisher
    end

    def contact_list_id
      # might change so not memoizing
      publisher.silverpop_list_identifier
    end

    def seed_database_id
      @seed_database_id ||= publisher.silverpop_seed_database_identifier
    end

    def database_id
      @database_id ||= publishing_group.silverpop_database_identifier
    end

    def opt_out_of_silverpop_seed_database
      return unless seed_database_id.present?
      return unless silverpop.recipient_exists?(seed_database_id, email)
      silverpop.opt_out_recipient(seed_database_id, email)
      self.opted_out_of_silverpop_seed_database_at = Time.zone.now
    end

    def add_recipient_to_silverpop_database
      return if silverpop.recipient_exists?(database_id, email)
      silverpop.add_recipient(database_id, email)
      self.recipient_added_to_silverpop_database_at = Time.zone.now
    end

    def remove_from_any_extra_silverpop_contact_lists
      consumer.remove_from_any_extra_silverpop_contact_lists
    end

    def create_silverpop_contact_list
      publisher.create_silverpop_contact_list_as_needed!(silverpop)
    end

    def add_to_silverpop_contact_list
      silverpop.add_contact_to_contact_list(contact_list_id, email)
      self.recipient_added_to_silverpop_list_at = Time.zone.now
    end

  end
end

