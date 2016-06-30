module Consumers::AuthenticationStrategy
  class Default
    def before_authentication(publisher, email, password)
      noop("no default before_authentication strategy")
    end

    def authenticate(user, password)
      if user_authenticated = user.authenticated?(password)
        user.successful_login!
        return user_authenticated
      else
        user.failed_login!
        return :locked if user.access_locked?
        return nil
      end
    end

    def find_for_authentication(publisher, email)
      publisher.find_consumer_by_email_for_authentication(email)
    end
  end
end
