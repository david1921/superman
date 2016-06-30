module FacebookApp

  ANALOG_SANDBOX_FACEBOOK_APP_ID = "136197326425095" unless defined?(ANALOG_SANDBOX_FACEBOOK_API_KEY)
  ANALOG_SANDBOX_FACEBOOK_API_KEY = "d037226862befdaf3d377f47eb1ec37c" unless defined?(ANALOG_SANDBOX_FACEBOOK_API_KEY)
  ANALOG_SANDBOX_FACEBOOK_APP_SECRET = "3b2df3a7e2589a30da5bb1bcca4d3290" unless defined?(ANALOG_SANDBOX_FACEBOOK_APP_SECRET)

  ANALOG_APP_CREDENTIALS = {
      :development => { :app_id => ANALOG_SANDBOX_FACEBOOK_APP_ID,
                        :api_key => ANALOG_SANDBOX_FACEBOOK_API_KEY,
                        :app_secret => ANALOG_SANDBOX_FACEBOOK_APP_SECRET },
      :test =>        { :app_id => ANALOG_SANDBOX_FACEBOOK_APP_ID,
                        :api_key => ANALOG_SANDBOX_FACEBOOK_API_KEY,
                        :app_secret => ANALOG_SANDBOX_FACEBOOK_APP_SECRET },
      :acceptance =>  { :app_id => ANALOG_SANDBOX_FACEBOOK_APP_ID,
                        :api_key => ANALOG_SANDBOX_FACEBOOK_API_KEY,
                        :app_secret => ANALOG_SANDBOX_FACEBOOK_APP_SECRET },
      :nightly =>     { :app_id => ANALOG_SANDBOX_FACEBOOK_APP_ID,
                        :api_key => ANALOG_SANDBOX_FACEBOOK_API_KEY,
                        :app_secret => ANALOG_SANDBOX_FACEBOOK_APP_SECRET },      
      :staging =>     { :app_id => "115577455178934",
                        :api_key => "85fd0030ec90d0cdb9b9d702f39c24ba",
                        :app_secret => "b04b8063860eed74b839176c33658ea2" }
  } unless defined?(ANALOG_APP_CREDENTIALS)

  class << self

    def facebook_configured?(publisher_or_group, rails_env = Rails.env)
      return false unless facebook_app_id(publisher_or_group, rails_env).present?
      return false unless facebook_api_key(publisher_or_group, rails_env).present?
      return false unless facebook_app_secret(publisher_or_group, rails_env).present?
      return true # all the pieces are there so we are configured ;)
    end

    def facebook_app_id(publisher_or_group, rails_env = Rails.env)
      facebook_credentials(publisher_or_group, rails_env)[:app_id]
    end

    def facebook_api_key(publisher_or_group, rails_env = Rails.env)
      facebook_credentials(publisher_or_group, rails_env)[:api_key]
    end

    def facebook_app_secret(publisher_or_group, rails_env = Rails.env)
      facebook_credentials(publisher_or_group, rails_env)[:app_secret]
    end

    def facebook_credentials(publisher_or_group, rails_env = Rails.env)
      case rails_env
        when "production"
          id = publisher_or_group.facebook_app_id
          key = publisher_or_group.facebook_api_key
          secret = publisher_or_group.facebook_app_secret
          if publisher_or_group.respond_to?(:publishing_group) && publisher_or_group.publishing_group.present?
            id = publisher_or_group.publishing_group.facebook_app_id if id.blank?
            key = publisher_or_group.publishing_group.facebook_api_key if key.blank?
            secret = publisher_or_group.publishing_group.facebook_app_secret if secret.blank?
          end
        else
          id = ANALOG_APP_CREDENTIALS[rails_env.to_sym][:app_id]
          key = ANALOG_APP_CREDENTIALS[rails_env.to_sym][:api_key]
          secret = ANALOG_APP_CREDENTIALS[rails_env.to_sym][:app_secret]
      end
      {:app_id => id, :api_key => key, :app_secret => secret}
    end
  end
end
