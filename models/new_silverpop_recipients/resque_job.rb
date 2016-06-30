module NewSilverpopRecipients
  class ResqueJob

    @queue = :new_silverpop_recipients

    def self.perform(new_silverpop_recipient_id)
      return unless Analog::ThirdPartyApi::Silverpop.allow_silverpop_request?

      new_silverpop_recipient = NewSilverpopRecipient.find(new_silverpop_recipient_id)
      new_silverpop_recipient.add_recipient_to_silverpop
    end

  end
end
