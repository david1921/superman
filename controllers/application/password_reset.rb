module Application
  module PasswordReset

    def consumer_password_reset_path_or_url(publisher)
      publisher.custom_consumer_password_reset_url or default_consumer_password_reset_path(publisher)
    end

    def default_consumer_password_reset_path(publisher)
      new_publisher_consumer_password_reset_path(publisher)
    end

  end
end
