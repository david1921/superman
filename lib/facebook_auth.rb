module FacebookAuth

  class NoFacebookApiKeyConfiguredForPublisher < ActiveRecord::RecordNotFound; end
  class NoFacebookApiSecretConfiguredForPublisher < ActiveRecord::RecordNotFound; end
  
  def self.included(base)
    base.send :include, InstanceMethods
  end
  
  class << self
    
    def oauth2_client(publisher_or_group, rails_env = Rails.env)
      credentials = FacebookApp.facebook_credentials(publisher_or_group, rails_env)
      raise NoFacebookApiKeyConfiguredForPublisher unless credentials[:api_key]
      raise NoFacebookApiSecretConfiguredForPublisher unless credentials[:app_secret]
      OAuth2::Client.new(credentials[:api_key], credentials[:app_secret], :site => 'https://graph.facebook.com')
    end    
    
  end

  module InstanceMethods

    # Responsible for signing in a new or existing consumer based on their facebook id and 
    # access token.  The publisher and access token are required to sign the consumer into
    # the application.
    #
    # The access token is expected to be an OAuth2::AccessToken.
    #
    # If everything is in place, the consumer is logged into the applications. 
    def facebook_signin(publisher, access_token)
      return false unless access_token.present?
      begin
        facebook = JSON.parse(access_token.get('/me'))
        facebook['facebook_id'] = facebook.delete('id')
        consumer = Consumer.find_or_create_by_fb(facebook, access_token, publisher, cookies[:referral_code])
        set_up_session consumer
        consumer
      rescue
        Rails.logger.error("[API] (facebook signin) error occurred: #{$!}")
        false
      end
    end

  end
end
