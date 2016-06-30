module DailyDealHelper

  include Analog::Referer::Helper

  def url_for_facebook_daily_deal_image(daily_deal)
    if daily_deal.photo.file?
      daily_deal.photo :facebook
    elsif daily_deal.advertiser.logo.file? && daily_deal.advertiser.logo_dimension_valid_for_facebook?
      daily_deal.advertiser.logo :facebook
    else
      # missing.png
      daily_deal.advertiser.logo :standard
    end
  end
  
  def apple_app_store_url(publisher)
    if publisher.apple_app_store_url.present?
      publisher.apple_app_store_url
    elsif publisher.publishing_group.try(:apple_app_store_url).present?
      publisher.publishing_group.apple_app_store_url
    else
      nil
    end
  end
  
  def all_daily_deal_hosts_as_autocomplete_source
    Publisher.find(
      :all,
      :select => "DISTINCT production_daily_deal_host", 
      :conditions => "production_daily_deal_host != '' AND production_daily_deal_host IS NOT NULL",
      :order => "production_daily_deal_host ASC"
    ).map { |p| %Q{"#{p.production_daily_deal_host}"} }.join(", ")
  end
  
  def all_publisher_labels_as_autocomplete_source
    Publisher.all(:select => :label).map(&:label).compact.map { | label | %Q{"#{label}"} }.join(", ")
  rescue
    ""
  end
  
  def email_voucher_redemption_message_for_this_exact_locale(daily_deal)
    translations_in_this_locale = daily_deal.translations.by_locale(I18n.locale)
    if translations_in_this_locale.email_voucher_redemption_message.present?
      translations_in_this_locale.email_voucher_redemption_message
    else
      nil
    end
  rescue
    nil
  end
  
  def daily_deals_terms_link(publisher, label = t(:terms))
    checkbox_label_link(label, terms_publisher_daily_deals_path(publisher))
  end

  def daily_deals_privacy_link(publisher, label = t(:privacy_policy))
    checkbox_label_link(label, privacy_policy_publisher_daily_deals_path(publisher))
  end
  
  def checkbox_label_link(label, location, new_window = true)
    #
    # JavaScript needed to cancel automatic checking of checkbox when link in label is clicked.
    #
    if new_window
      link_to_function(label, "window.open('#{location.html_safe}', '_blank'); return false")
    else
      link_to_function(label, "window.open('#{location.html_safe}'); return false")
    end
  end
  
  def daily_deal_cancel_link(publisher)
    if params && params[:market_label]
      path = public_deal_of_day_for_market_path(:label => publisher.label, :market_label => params[:market_label])
    elsif publisher.try(:custom_cancel_url)
      path = publisher.custom_cancel_url
    else
      path = public_deal_of_day_path(publisher.label)
    end
    link_to(t(:cancel), path, :id => "cancel_link")
  end
  
  def special_deal_link(publisher)
    link_to deal_credit_publisher_consumers_url(@publisher, :protocol => https_unless_development), :method => :post, :style => "float: left; margin-left: 0" do
      %Q(<span>Special Promo:&nbsp;</span><span style="color: #ddec52">Sign up here to receive your $10 credit</span>)
    end unless cookies[:deal_credit] == "applied" || current_consumer
  end

  def daily_deal_page_title(style = :default)
    case style
    when :default
      deal = @daily_deal.try(:email_blast_subject)
      deal = @publisher && @publisher.daily_deals.current_or_previous.try(:email_blast_subject) unless deal.present? 
      slug = @daily_deal_page_title_slug.if_present
      tail = [@publisher.try(:daily_deal_name) || "Deal of the Day", @publisher.try(:name).if_present].compact.join(": ")
      [deal, slug, tail].compact.join(" - ").html_safe
    when :daily_deal_if_present
      deal = @daily_deal.try(:email_blast_subject)
      slug = @daily_deal_page_title_slug.if_present
      tail = [@publisher.try(:daily_deal_name) || "Deal of the Day", @publisher.try(:name).if_present].compact.join(": ")
      [deal, slug, tail].compact.join(" - ").html_safe
    when :chicagoreader
      branding = "Chicago Reader Real Deal"
      if @daily_deal
        "#{@daily_deal.short_description} #{branding}".html_safe
      else
        slug = @daily_deal_page_title_slug.if_present
        [slug, branding].compact.join(" - ").html_safe
      end
    when :villagevoicemedia
      if @daily_deal
        "VOICE | #{@daily_deal.advertiser.name} Deal – #{@daily_deal.value_proposition}".html_safe
      else
        location = params[:location] || @publisher.try(:name)
        "VOICE | Deal of the Day – discounts deals and coupons for #{location} restaurants, vacations, and services."
      end      
    when :thomsonlocal
      if @daily_deal_page_title_slug.present?
        "#{@publisher.daily_deal_brand_name} - #{@daily_deal_page_title_slug}".html_safe
      else
        @publisher.daily_deal_brand_name.try(:html_safe)
      end
    end
  end
  
  def get_dollars_and_cents(value)
    return ["", ""] if value.blank?
    return ("%0.2f" % value.to_f).split(".")
  end
  
  def set_daily_deal_page_title_slug(slug)
    @daily_deal_page_title_slug = slug
  end
  
  def daily_deal_how_it_works(publisher)
    return "" unless publisher
    
    if publisher.how_it_works.present?
      publisher.how_it_works
    elsif publisher.publishing_group.try(:how_it_works).present?
      publisher.publishing_group.how_it_works
    else
      ""
    end
  end
  
  def should_show_ticker?
    return %w(seo_friendly_deal_of_the_day deal_of_the_day).include?(controller.action_name) ||
           (controller.controller_name == "daily_deals" &&
            controller.action_name == "show")
  end
  
  def truncate_textiled(textile_source, options)
    return textile_source if textile_source.blank?
    
    max_length = options[:length] || 30
    
    truncated_source = if textile_source.length > max_length
      truncate(textile_source, :length => max_length)
    else
      textile_source
    end
    
    return RedCloth.new(truncated_source).to_html
  end

  def add_params_to_email_link (url, publabel = nil)
    params = {
      "utm_source"   => (publabel) ? publabel : @publisher.label,
      "utm_medium"   => "email",
      "utm_campaign" => Time.new.strftime("%Y%m%d")
    }
    return url + (url.include?("?") ? "&" : "?") + params.to_query
  end  

  def affiliated_publishers_for(daily_deal)
    affiliate_placements = daily_deal.affiliate_placements.not_deleted
    render :partial => "daily_deals/affiliate_placements", :locals => { :affiliate_placements => affiliate_placements }
  end
  
  def map_image_url_for(deal, size = "640x250", multi_loc = false)
    stores = deal.advertiser.stores
    if multi_loc && stores.present? && stores.length > 1
      escaped_addresses = stores.map do |s|
        CGI.escape("#{s.address_line_1}, #{s.city}, #{s.state} #{s.zip}")
      end
      "http://maps.google.com/maps/api/staticmap?size=#{size}&markers=size:small|#{escaped_addresses.join('|')}&sensor=false"
    else
      store = deal.advertiser.store
      if store
        escaped_address = CGI.escape("#{store.address_line_1}, #{store.city}, #{store.state} #{store.zip}")
        "http://maps.google.com/maps/api/staticmap?size=#{size}&center=#{escaped_address}&markers=size:small|#{escaped_address}&key=ABQIAAAAzObGV3GscSCtMupcN2Jm-RSSjhI9lG3KGwm-Keiwru5ERTctHhTXe3LfYrff_rQT8DZgaQB6AthF0A&sensor=false"
      else
        ""
      end
    end
  end

  def options_for_email_voucher_offer(daily_deal)
    # Include the currently selected offer, even if it's expired
    ([daily_deal.email_voucher_offer] | daily_deal.advertiser.offers.unexpired).compact.collect{|o| [email_voucher_offer_option_text(o), o.id]}
  end
  
  def off_platform_daily_deal_path(daily_deal)
    daily_deal_path(daily_deal)
  end
  
  def loyalty_program_url(daily_deal, referrer)
    unless referrer_can_use_loyalty_program_for_deal_publisher?(daily_deal, referrer) 
      raise "can't generate loyalty program url: this consumer belongs to a different publisher"
    end
    
    publisher_host = daily_deal.publisher.production_daily_deal_host.present? ? daily_deal.publisher.production_daily_deal_host : AppConfig.default_host
    daily_deal_url(:id => daily_deal.to_param, :referral_code => referrer.referrer_code, :host => publisher_host)
  end

  def category_deals_only_for(deals)
    deals.reduce([]) do |r, deal|
      if deal.publishers_category_id.present?
        r.push(deal)
      else
        r
      end
    end
  end

  def remove_category_deals_from(deals)
    deals.reduce([]) do |r, deal|
      if deal.publishers_category_id.blank?
        r.push(deal)
      else
        r
      end
    end
  end

  def show_sales_agent_id_input?
    @daily_deal.publisher.enable_sales_agent_id_for_advertisers?
  end

  private

  def referrer_can_use_loyalty_program_for_deal_publisher?(daily_deal, referrer)
    return true if daily_deal.publisher == referrer.publisher
    return true if daily_deal.publishing_group.present? &&
                   daily_deal.publishing_group.allow_single_sign_on? &&
                   daily_deal.publishing_group == referrer.publishing_group
    return false
  end

  def email_voucher_offer_option_text(offer)
    "#{offer.message} (#{(x = offer.show_on) ? x : 'now'} => #{(y = offer.expires_on) ? y : 'forever'})"
  end

  def daily_deal_buy_now_path(daily_deal, controller = nil)
    controller ||= @controller
    unless daily_deal.affiliate_url.present?
      new_daily_deal_daily_deal_purchase_path daily_deal
    else
      link_to_affiliate_url(daily_deal, :controller => controller)
    end
  end

  def market_aware_daily_deal_url(daily_deal, url_params = {})
    url_params = url_params.symbolize_keys.reject{|k,v| [:action, :controller].include?(k)} # remove routing params, they mess things up
    market_label = url_params[:market_label]
    publisher = daily_deal.publisher
    if market_label.present?
      publisher_daily_deal_for_market_url(url_params.merge(:label => publisher.label, :host => publisher.daily_deal_host, :id => daily_deal.id, :market_label => market_label))
    else
      publisher_daily_deal_url(url_params.merge(:publisher_id => publisher.label, :host => publisher.daily_deal_host, :id => daily_deal.id))
    end
  end
  
  def formatted_price_for(price, currency_symbol='$')
    return "" if price.blank?
    if price.is_fractional?
      "<span class='deal_fractional_price'>#{ number_to_currency(price, :unit => currency_symbol) }</span>".html_safe
    else
      number_to_currency(price, :precision => 0, :unit => currency_symbol)
    end
  end
  
  def show_syndication_financials?(daily_deal)
    !daily_deal.new_record? && daily_deal.available_for_syndication?
  end
  
  def syndication_revenue_split_publisher_label
    if accountant? || admin?
      return "Syndication Revenue Split<br>(Source Publisher):"
    else
      return "Syndication Revenue Split:"
    end
  end
  
  def syndication_revenue_split_deal_label
    if accountant? || admin?
      return "Syndication Revenue Split<br>(Deal-specific):"
    else
      return "Syndication Revenue Split:"
    end
  end
  
  def syndication_cc_fee_split_label
    if accountant? || admin?
      return "Syndication CC Fee Split<br>(Deal-specific):"
    else
      return "Syndication CC Fee Split:"
    end
  end
  
  def hours_or_days_remaining_from_now(from_time)
    return nil if from_time.nil?
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = Time.zone.now
    distance_in_hours = (((to_time - from_time).abs)/3600).round
    if distance_in_hours < 24
      "#{distance_in_hours} #{t(:hour, :count => distance_in_hours)}"
    else
      days = (distance_in_hours/24.0).round
      "#{days} #{t(:day, :count => days)}"
    end
  end

  def daily_deal_status_hash(daily_deal)
    status = {
        :quantity_sold => @daily_deal.number_sold,
        :updated_at =>    @daily_deal.updated_at.utc.to_formatted_s(:iso8601)
    }
    status.merge!(:variations => daily_deal.daily_deal_variations.map do |ddv|
      {:daily_deal_variation_id => ddv.id, :quantity_sold => ddv.number_sold}
    end) if daily_deal.daily_deal_variations.any?
    return status
  end

end
