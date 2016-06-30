module Drop
  class DailyDeal < Liquid::Drop
    include ActionController::UrlWriter
    include ActionView::Helpers::TagHelper
    include CouponsHelper
    include DailyDealHelper

    delegate :active?,
             :address,
             :available?,
             :advertiser_name,
             :affiliate_url,
             :description,
             :short_description,
             :ending_time_in_milliseconds,
             :starting_time_in_millseconds,
             :facebook_description,
             :facebook_title,
             :hide_at,
             :highlights,
             :min_quantity,
             :number_sold,
             :number_left,
             :number_sold_display_threshold,
             :over?,
             :price,
             :publisher,
             :publisher_prefix,
             :reviews,
             :email_blast_subject,
             :savings,
             :savings_as_percentage,
             :sold_out_at_localized,
             :sold_out?,
             :start_at,
             :terms,
             :time_remaining_display,
             :time_remaining_text_display,
             :twitter_status,
             :value,
             :value_proposition_subhead,
             :number_sold_meets_or_exceeds_display_threshold?,
             :value_proposition,
             :publishers_category,
             :side_deals_in_custom_entercom_order,
             :to => :daily_deal

    def initialize(daily_deal)
      @daily_deal = daily_deal
    end

    def advertiser
      Drop::Advertiser.new(daily_deal.advertiser)
    end
    
    def photo
      Drop::Photo.new(daily_deal.photo)
    end
    
    def side_deals
      @side_deals ||= daily_deal.side_deals {|d| d.created_at }
      @side_deals.reverse!  # the above line won't let me do a -d.created_at
      @side_deals.map { |side_deal| Drop::DailyDeal.new(side_deal) } 
    end
    
    def side_deals_in_shopping_mall
      @side_deals_in_shopping_mall ||= daily_deal.side_deals(:in_shopping_mall => true).map { |side_deal| Drop::DailyDeal.new(side_deal) }
    end
    
    def random_side_deals_in_shopping_mall
      side_deals_in_shopping_mall.shuffle
    end
    
    def side_deals_sorted_by_hide_at
      @sorted_side_deals ||= side_deals.sort_by {|deal| deal.hide_at}
    end
    
    def random_side_deals
      side_deals.shuffle
    end
    
    
    def upcoming_deals
      @upcoming_deals ||= ::DailyDeal.upcoming.map { |upcoming_deal| Drop::DailyDeal.new(upcoming_deal) }
    end

    # This deal could be /deal-of-the-day or reference a deal id
    def this_deal_path
      controller.request.request_uri
    end
    
    def side_deals_in_deal_1_category
      side_deals_in_category("Deal 1")
    end

    def side_deals_in_deal_2_category
      side_deals_in_category("Deal 2")
    end

    def side_deals_in_deal_3_category
      side_deals_in_category("Deal 3")
    end

    def side_deals_in_deal_4_category
      side_deals_in_category("Deal 4")
    end

    def side_deals_in_category(category_name)
      category = publisher.allowable_daily_deal_categories.find_by_name(category_name)
      category.present? ? side_deals.select { |sd| sd.publishers_category == category } : []
    end

    def buy_now_path
      daily_deal_buy_now_path(daily_deal, controller)
    end
    
    def buy_now_url
      unless affiliate_url.present?
        new_daily_deal_daily_deal_purchase_url(:daily_deal_id => id, :host => publisher.daily_deal_host)
      else
        link_to_affiliate_url(daily_deal)
      end
    end
    
    def email_url
      body = URI.escape("Check out this deal at #{url}")
      subject = URI.escape("#{publisher_prefix} #{value_proposition}")
      escape_once "mailto:?body=#{body}&subject=#{subject}"
    end
    
    def facebook_url
      facebook_daily_deal_url(:id => id, :host => publisher.daily_deal_host)
    end

    def facebook_popup_url
      facebook_daily_deal_url(:id => id, :popup => true, :host => publisher.daily_deal_host)
    end
    
    def facebook_daily_deal_image_url
      url_for_facebook_daily_deal_image daily_deal
    end
    
    def fine_print
      daily_deal.terms
    end
    
    # Need to replace with a tag (I think) to remove hard-coded dimensions
    def map_image_url
      map_image_url_for daily_deal, "199x169"
    end

    def map_image_url_large
      map_image_url_for daily_deal, "282x149"
    end
    
    def multi_loc_map_image_url
      map_image_url_for daily_deal, "199x169", true
    end

    def privacy_policy_url
      privacy_policy_publisher_daily_deals_url(:publisher_id => publisher.id, :host => publisher.daily_deal_host)
    end

    def terms_url
      terms_publisher_daily_deals_url(:publisher_id => publisher.id, :host => publisher.daily_deal_host)
    end

    # Need to add a helper for Facebook
    def twitter_url
      twitter_daily_deal_url(daily_deal, :host => publisher.daily_deal_host)
    end

    def loyalty_program_url
      loyalty_program_daily_deal_url(id, :host => publisher.daily_deal_host)
    end

    def url
      market_aware_daily_deal_url(daily_deal, params)
    end

    def url_for_email
      add_params_to_email_link(url, publisher.label)
    end

    def id
      daily_deal.id
    end
    
    def value_proposition_escaped
      URI.escape(daily_deal.value_proposition)
    end

    def json_path
      daily_deal_path(daily_deal, :format => "json")
    end
    
    def js_path
      daily_deal_path(daily_deal, :format => "js")
    end
    
    def js_url
      daily_deal_url(daily_deal, :format => "js", :host => publisher.daily_deal_host)
    end

    def category
      Drop::DailyDealCategory.new(daily_deal.analytics_category) if daily_deal.analytics_category
    end
    
    def side_deal_value_proposition
      daily_deal.side_deal_value_proposition.present? ? daily_deal.side_deal_value_proposition : daily_deal.value_proposition
    end
    
    def side_deal_value_proposition_subhead
      daily_deal.side_deal_value_proposition_subhead.present? ? daily_deal.side_deal_value_proposition_subhead : daily_deal.value_proposition_subhead
    end
    
    def value_based_on_min_quantity
      if min_quantity > 1
        (value * min_quantity).to_f
      else
        value
      end
    end
    
    def savings_based_on_min_quantity
      if min_quantity > 1
        (savings * min_quantity).to_f
      else
        savings
      end
    end

    private
    
    def daily_deal
      @daily_deal
    end
    
    def controller
      @context.registers[:controller] if @context.present?
    end

    def params
      controller.present? ? controller.params : {}
    end

  end
end
