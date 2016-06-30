module Drop
  class Publisher < Liquid::Drop
    include ActionController::UrlWriter
    include ActionView::Helpers::TagHelper
    include DailyDealHelper
    include Drop::Publishers::Paths
    include UrlVerifierHelper

    delegate :address_line_1, :address_line_2, :zip, :state, :support_email_address, :support_url, :currency_code, :currency_symbol,
             :sales_email_address, :city, :daily_deal_host, :production_daily_deal_host, :label, :name, :show_special_deal?, :uses_a_ready_made_theme?, :sub_theme,
             :formatted_phone_number, :brand_name, :gift_certificate_disclaimer, :enable_daily_deal_referral, :support_phone_number, :parent_theme, :allow_offers,
             :daily_deal_referral_credit_amount, :daily_deal_brand_name, :market_name, :market_name_or_city, :publishers_in_publishing_group, :allow_gift_certificates, :allow_all_deals_page,
             :link_to_website?, :brand_name_or_name, :daily_deal_referral_message_head, :daily_deal_referral_message_body, :daily_deal_email_subject, :daily_deal_universal_terms,
             :allowable_daily_deal_categories, :google_map_latitude, :google_map_longitude, :google_map_zoom_level, :enable_affiliate_url_popup, :group_label_or_label, :allow_discount_codes?,
             :to => :publisher

    def initialize(publisher)
      @publisher = publisher
    end

    def active_deals
      @active_deals ||= publisher.daily_deals.active.map { |active_deal| Drop::DailyDeal.new(active_deal) }
    end

    def current_or_previous_deal
      publisher.daily_deals.current_or_previous
    end

    def daily_deals_path
      daily_deals_public_index_path(publisher.label)
    end
    
    def daily_deals_public_index_js_path
      daily_deals_public_index_path(publisher.label, :format => "js")
    end

    def recent_deals_path
      past_deals_path
    end

    def past_deals_path
      past_deals_of_day_path(publisher.label)
    end

    def deal_credit_path
      deal_credit_publisher_consumers_path(publisher.id)
    end

    def signup_credit_amount
      publisher.signup_discount_amount
    end

    def offers_path
      public_offers_path publisher.id
    end

    def refer_a_friend_path
      refer_a_friend_publisher_consumers_path( publisher )
    end

    def refer_a_friend_url
      refer_a_friend_publisher_consumers_url( publisher, :host => publisher.daily_deal_host )
    end

    def cart_path
      publisher_cart_path( publisher.label )
    end

    def id
      publisher.id
    end

    def publishing_group
      if publisher.publishing_group
        Drop::PublishingGroup.new(publisher.publishing_group)
      end
    end

    def contact_path
      market_label = params[:market_label]

      if market_label.present?
        daily_deals_contact_for_market_path :publisher_id => id, :market_label => market_label
      else
        contact_publisher_daily_deals_path :publisher_id => id
      end
    end

    def launched?
      publisher.launched?
    end

    def how_daily_deal_works
      daily_deal_how_it_works publisher
    end

    def current_consumer
      controller.send(:current_consumer)
    end

    def current_user_belongs_to?
      controller.send(:current_consumer_for_publisher?, publisher)
    end

    def password_reset_path
      controller.send(:consumer_password_reset_path_or_url, publisher)
    end

    def new_consumer_path
      market_label = params[:market_label]

      if market_label.present?
        new_publisher_consumer_for_market_path :publisher_id => id, :market_label => market_label
      else
        new_publisher_consumer_path publisher
      end
    end

    def presignup_consumers_url
      presignup_publisher_consumers_url :publisher_id => id, :host => publisher.daily_deal_host
    end

    def consumers_path
      publisher_consumers_path publisher
    end

    def subscribers_path
      publisher_subscribers_path publisher
    end

    def subscribers_thank_you_path
      #todo make route
      "/publishers/#{publisher.id }/daily_deals/subscribed"
    end

    def verifiable_thank_you_publisher_daily_deal_subscribers_path
      verifiable_url(thank_you_publisher_daily_deal_subscribers_path(:publisher_id => publisher.id))
    end

    def thank_you_daily_deal_subscribers_fbtab_path
      thank_you_publisher_daily_deal_subscribers_path(:publisher_id => publisher.id, :format => "fbtab")
    end

    def thank_you_2_daily_deal_subscribers_path
      thank_you_2_publisher_daily_deal_subscribers_path(:publisher_id => publisher.id)
    end

    def thank_you_2_daily_deal_subscribers_fbtab_path
      thank_you_2_publisher_daily_deal_subscribers_path(:publisher_id => publisher.id, :format => "fbtab")
    end



    def daily_deal_subscribers_path
      publisher_daily_deal_subscribers_path publisher
    end

    def about_us_path
      market_label = params[:market_label]

      if market_label.present?
        daily_deals_about_us_for_market_path :publisher_id => id, :market_label => market_label
      else
        about_us_publisher_daily_deals_path :publisher_id => id
      end
    end

    def faq_path
      market_label = params[:market_label]

      if market_label.present?
        daily_deals_faqs_for_market_path :publisher_id => id, :market_label => market_label
      else
        faqs_publisher_daily_deals_path :publisher_id => id
      end
    end

    def login_path
      market_label = params[:market_label]

      if market_label.present?
        daily_deal_login_for_market_path :publisher_id => id, :market_label => market_label
      else
        daily_deal_login_path :publisher_id => id
      end
    end

    def my_deals_path
      publisher_consumer_daily_deal_purchases_path(publisher, current_consumer)
    end

    def shopping_mall_path
      market_label = params[:market_label]

      if market_label.present?
        shopping_mall_for_market_path :label => publisher.label, :market_label => market_label
      else
        publisher_shopping_mall_path :publisher_id => publisher.label
      end
    end

    def privacy_path
      market_label = params[:market_label]

      if market_label.present?
        daily_deals_privacy_policy_for_market_path :publisher_id => id, :market_label => market_label
      else
        privacy_policy_publisher_daily_deals_path :publisher_id => id
      end
    end
    
    def popup_privacy_path
      privacy_policy_publisher_daily_deals_path :publisher_id => id, :layout => 'popup'
    end

    def legal_path
      legal_publisher_daily_deals_path(publisher)
    end

    def california_privacy_path
      california_privacy_policy_publisher_daily_deals_path :publisher_id => id
    end

    def terms_path
      market_label = params[:market_label]

      if market_label.present?
        daily_deals_terms_for_market_path :publisher_id => id, :market_label => market_label
      else
        terms_publisher_daily_deals_path :publisher_id => id
      end
    end
    
    def popup_terms_path
      terms_publisher_daily_deals_path :publisher_id => id, :layout => 'popup'
    end

    def my_account_path
      edit_publisher_consumer_path(publisher, current_consumer)
    end

    def logout_path
      daily_deal_logout_path publisher
    end

    def landing_page_path
      publisher_landing_page_path( :publisher_id => publisher.label )
    end

    def affiliate_show_path
      market_label = params[:market_label]

      if market_label.present?
        market_affiliate_show_path(:label => publisher.label, :market_label => market_label)
      else
        show_publisher_affiliate_path(:publisher_id => publisher.label)
      end
    end

    def affiliate_faq_path
      market_label = params[:market_label]

      if market_label.present?
        market_affiliate_faq_path(:label => publisher.label, :market_label => market_label)
      else
        faqs_publisher_affiliate_path(:publisher_id => publisher.label)
      end
    end

    def landing_page_url
      publisher_landing_page_url( :publisher_id => publisher.label, :host => publisher.daily_deal_host )
    end

    def landing_page_url_for_email
      add_params_to_email_link(landing_page_url, publisher.label)
    end

    def sweepstakes_path
      publisher_sweepstakes_path( :publisher_id => publisher.label )
    end

    def communities_path
      publisher_communities_path( :publisher_id => publisher.label )
    end
    
    #this returns the daily deal path for the market specified in the url.
    #/publishers/kowabunga/atlanta/deal-of-the-day
    def todays_daily_deal_path
      market_label = params[:market_label]
      if market_label.present?
        public_deal_of_day_for_market_path(:label => publisher.label, :market_label => market_label)
      else
        public_deal_of_day_path :label => publisher.label
      end
    end
    
    #this returns the daily deal path for the market sassociated with the users 
    #physical location or the market associated with the 'zip_code' cookie.
    def user_market_aware_todays_daily_deal_path
      market_label = user_market_label
      if market_label.present?
        public_deal_of_day_for_market_path(:label => publisher.label, :market_label => market_label)
      else
        todays_daily_deal_path
      end
    end
    
    def todays_daily_deal_url
      public_deal_of_day_url :label => publisher.label, :host => publisher.daily_deal_host
    end

    def todays_daily_deal_email_url
      body = URI.escape("Check out the deals at #{todays_daily_deal_url}")
      subject = URI.escape("#{daily_deal_email_subject}")
      escape_once "mailto:?body=#{body}&subject=#{subject}"
    end

    def offers_path
      public_offers_path publisher
    end

    def search_path
      publisher_search_path( publisher.label )
    end

    def map_businesses_path
      public_advertisers_path( publisher, :with_map => true )
    end
    
    def map_businesses_path_as_json
      public_advertisers_path( publisher, :with_map => true, :format => "json" )
    end
    
    def businesses_json_path
      public_advertisers_path( publisher, :format => "json" )
    end
    
    def gift_certificates_path
      public_gift_certificates_path :label => publisher.label
    end

    def how_it_works_path
      market_label = params[:market_label]

      if market_label.present?
        how_it_works_for_market_path :publisher_id => publisher.id, :market_label => market_label
      else
        how_it_works_publisher_daily_deals_path publisher
      end
    end

    def feature_your_business_path
      market_label = params[:market_label]

      if market_label.present?
        daily_deals_feature_your_business_for_market_path :publisher_id => publisher.id, :market_label => market_label
      else
        feature_your_business_publisher_daily_deals_path publisher
      end

    end

    def feature_your_business_url
      feature_your_business_publisher_daily_deals_url publisher, :host => publisher.daily_deal_host
    end

    def facebook_connect_path
      auth_init_path publisher if facebook_configured?
    end

    def facebook_configured?
      FacebookApp.facebook_configured?(publisher)
    end

    def facebook_app_id
      FacebookApp.facebook_app_id(publisher)
    end

    def facebook_api_key
      FacebookApp.facebook_api_key(publisher)
    end

    def presignup_daily_deal_subscribers_url
      presignup_publisher_daily_deal_subscribers_url :publisher_id => publisher.id, :host => publisher.daily_deal_host
    end

    def gogosavingsdailydeal_publisher
      @gogosavingsdailydeal_publisher ||= ::Publisher.find_by_label("gogosavingsdailydeal")
    end

    def gogosavings_publisher
      @gogosavings_publisher ||= ::Publisher.find_by_label("gogosavings")
    end

    def gogosavings_current_or_previous_deal
      gogosavings_publisher.daily_deals.current_or_previous
    end

    def paypal_url
      Paypal::Notification.ipn_url
    end

    def paypal_return_url
      controller.request.headers['HTTP_REFERER']
    end

    def paypal_view_cart_parameters
      parameters = {
        'cmd' => "_cart",
        'display' => "1",
        'redirect_cmd' => "_cart",
        'business' => controller.send(:paypal_business),
        'return' => paypal_return_url,
        'cancel_return' => paypal_return_url
      }
      parameters.merge!('notify_url' => AppConfig.paypal_notify_url ) if AppConfig.respond_to?(:paypal_notify_url)
      return parameters
    end

    def paypal_view_cart_parameter_names
      paypal_view_cart_parameters.keys
    end

    def current_user_subscribed?
      controller.send(:cookies)[:subscribed] == "subscribed"
    end

    def daily_deal_categories
      publisher.daily_deal_categories.map do |daily_deal_category|
        Drop::DailyDealCategory.new(daily_deal_category)
      end
    end

    def default_daily_deal_categories
      publisher.default_daily_deal_categories.map do |daily_deal_category|
        Drop::DailyDealCategory.new(daily_deal_category)
      end
    end

    def subscription_locations
      publisher.subscription_locations.map do |subscription_location|
        Drop::SubscriptionLocation.new(subscription_location)
      end
    end

    def google_analytics_ids
      if market_label
        publisher.google_analytics_ids(market_label).map {|id| "'#{id}'"}.join(",")
      else
        publisher.google_analytics_ids.map {|id| "'#{id}'"}.join(",")
      end
    end
    
    def google_analytics_publishing_group
      if market_label.present?
        publisher.label
      elsif publisher.publishing_group.present?
        publisher.publishing_group.label
      else
        "(none)"
      end
    end

    def google_analytics_publisher
      if market_label.present?
        publisher.label + "-" + market_label
      else
        publisher.label
      end
    end
    
    def market_label
      if controller.request.parameters.has_key?('market_label') && !controller.request.parameters['market_label'].empty?
        return controller.request.parameters['market_label']
      else
        nil
      end
    end
    
    def markets
      @markets ||= publisher.markets.map { |market| Drop::Market.new(market) }
    end
    
    def user_market_name
      market = controller.send(:current_market, publisher)
      market.try(:name)
    end

    def user_market_label
      market = controller.send(:current_market, publisher)
      market.try(:label)
    end
    
    private

    def gift_certs_for_tampa(category)
      tampa_publisher_for_category = ::Publisher.find_by_label("tampa#{category}")
      tampa_publisher_for_category.gift_certificates.active.available.recent
    end

    def controller
      @context.registers[:controller] if @context.present?
    end

    def params
      controller.present? ? controller.params : {}
    end

    def publisher
      @publisher
    end
    
    def to_s
      "#<Drop::Publisher #{id} #{label} #{name}>"
    end
  end
end
