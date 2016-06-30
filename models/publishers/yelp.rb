module Publishers::Yelp

  def self.included(base)
    base.send :include, InstanceMethods
  end

  module InstanceMethods

    def yelp_credentials_present_on?(publisher_or_group)
      publisher_or_group.yelp_consumer_key && publisher_or_group.yelp_consumer_secret &&
        publisher_or_group.yelp_token && publisher_or_group.yelp_token_secret
    end

    def yelp_credentials_present?
      (yelp_credentials_present_on?(publishing_group) if publishing_group) ||
        yelp_credentials_present_on?(self)
    end

    def yelp_credentials_for(publisher_or_group)
      {
        :consumer_key => publisher_or_group.yelp_consumer_key,
        :consumer_secret => publisher_or_group.yelp_consumer_secret,
        :token => publisher_or_group.yelp_token,
        :token_secret => publisher_or_group.yelp_token_secret
      }
    end

    def yelp_credentials
      if publishing_group && yelp_credentials_present_on?(publishing_group)
        yelp_credentials_for(publishing_group)
      elsif yelp_credentials_present_on?(self)
        yelp_credentials_for(self)
      end
    end

  end
end

