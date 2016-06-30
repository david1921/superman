module SilverpopListMoves
  module MoveConsumerToDifferentSilverpopList

    def move_consumer_to_different_silverpop_list
      begin
        silverpop.open do |session|
          verify_consumer_exists!
          remove_from_old_list
          add_to_new_list
        end
      rescue => e
        self.error_at = Time.zone.now
        self.error_message = "#{e.class.name}: #{e.message}"
      ensure
        save!
      end
    end

    def publishing_group
      @publishing_group ||= consumer.publisher.publishing_group
    end

    def database_id
      @database_id ||= publishing_group.silverpop_database_identifier
    end

    def email
      consumer.email
    end

    def silverpop
      publishing_group.silverpop
    end

    def verify_consumer_exists!
      unless silverpop.recipient_exists?(database_id, email)
        raise "Recipient #{email} is not in silverpop database #{database_id}."
      end
    end

    def old_list_id
      old_publisher.silverpop_list_identifier
    end

    def new_list_id
      new_publisher.silverpop_list_identifier
    end

    def remove_from_old_list
      silverpop.remove_recipient(old_list_id, email)
      self.removed_from_old_list_at = Time.zone.now
    end

    def add_to_new_list
      silverpop.add_contact_to_contact_list(new_list_id, email)
      self.added_to_new_list_at = Time.zone.now
    end

  end
end
