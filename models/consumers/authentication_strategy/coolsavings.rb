module Consumers::AuthenticationStrategy
  class Coolsavings

    AUTHENTICATION_FAILED = "AUTHENTICATION_FAILED"

    def before_authentication(publisher, email, literal_password)
      member_attrs = member_attributes(email, literal_password)
      if authenticated?(member_attrs)
        create_or_update_consumer(publisher, email, member_attrs, literal_password)
      end
    end

    def authenticate(consumer, literal_password)
      authenticated?(member_attributes(consumer.email, literal_password))
    end

    def authenticated?(member_attrs)
      member_attrs != AUTHENTICATION_FAILED
    end

    def member_attributes(email, literal_password)
      member_attributes_by_email[email] ||= retrieve_member_attributes(email, literal_password)
    end

    def retrieve_member_attributes(email, literal_password)
      return AUTHENTICATION_FAILED if email.blank? || literal_password.blank?
      begin
        create_member(email, literal_password).get_attributes!
      rescue Analog::ThirdPartyApi::Coolsavings::ErrorResponse => e
        AUTHENTICATION_FAILED
      end
    end

    def create_or_update_consumer(publisher, email, member_attrs, literal_password)
      existing_consumer = find_for_authentication(publisher, email)
      consumer_attributes = analog_attributes_post_authentication(member_attrs, literal_password)
      if existing_consumer.present?
        update_consumer_attributes(existing_consumer, consumer_attributes)
      else
        create_consumer(consumer_attributes.merge({ "publisher_id" => publisher.id, "activated_at" => Time.zone.now }))
      end
    end

    def analog_attributes_post_authentication(coolsavings_attributes, literal_password)
      result = Analog::ThirdPartyApi::Coolsavings::AttributesMapper.new.map_to_analog(coolsavings_attributes)
      result["password"] = literal_password
      result["password_confirmation"] = result["password"]
      result["agree_to_terms"] = true
      result["active"] = true
      # We have just authenticated successfuly and so no password reset
      # is required.
      result["force_password_reset"] = false
      result
    end

    def member_attributes_by_email
      @member_attributes_by_email ||= {}
    end

    def find_for_authentication(publisher, email)
      publisher.find_consumer_by_email_if_access_allowed(email)
    end

    def create_member(email, literal_password)
      Analog::ThirdPartyApi::Coolsavings::Member.new(email, Consumers::Md5Password.md5_password(literal_password))
    end

    def create_consumer(attributes)
      c = Consumer.new(attributes)
      c.save!
    end

    def update_consumer_attributes(existing_consumer, consumer_attributes)
      existing_consumer.update_attributes(consumer_attributes)
    end

  end
end

