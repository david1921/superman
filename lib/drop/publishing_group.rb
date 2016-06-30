module Drop
  class PublishingGroup < Liquid::Drop
    include ActionController::UrlWriter
        
    delegate :label, :parent_theme, :uses_a_ready_made_theme?, :to => :publishing_group

    def initialize(publishing_group)
      @publishing_group = publishing_group
    end

    def publishers
      @publishers ||=
        publishing_group.publishers.map{ |publisher| Drop::Publisher.new(publisher) }
    end

    def live_publishers
      @live_publishers ||=
        publishing_group.publishers.launched.map{ |publisher| Drop::Publisher.new(publisher) }
    end

    def live_publishers_with_active_daily_deals
      @live_publishers_with_deals ||=
        publishing_group.publishers.launched.with_active_daily_deals.map{ |publisher| Drop::Publisher.new(publisher) }
    end

    def publishers_included_in_market_selection
      @publishers_included_in_market_selection ||=
        publishing_group.publishers.included_in_market_selection.map{ |publisher| Drop::Publisher.new(publisher) }
    end

    def live_publishers_included_in_market_selection
      @live_publishers_included_in_market_selection ||=
        publishing_group.publishers.included_in_market_selection.launched.map{ |publisher| Drop::Publisher.new(publisher) }
    end
    
    def landing_page_path
      publishing_group_landing_page_path(publishing_group.label)
    end
    
    def search_market_path
      search_publishing_group_markets_path(:publishing_group_id => publishing_group.label)
    end
    
    def subscribers_path
      publishing_group_subscribers_path(publishing_group.label)
    end
    
    def about_us_path
      about_us_publishing_group_path(publishing_group.label)
    end
    
    def popup_about_us_path
      about_us_path + "?layout=popup"
    end
    
    def terms_path
      terms_publishing_group_path(publishing_group.label)
    end
    
    def popup_terms_path
      terms_path + "?layout=popup"
    end
    
    def privacy_policy_path
      privacy_policy_publishing_group_path(publishing_group.label)
    end
    
    def popup_privacy_policy_path
      privacy_policy_path + "?layout=popup"
    end
    private

    attr_reader :publishing_group

  end
end
