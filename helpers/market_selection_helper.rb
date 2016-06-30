module MarketSelectionHelper

  def market_selection(publisher, *options)
    # options_to_hash to hash needed here to support liquid's lack of hashes
    options = options_to_hash(options, :field_name, :include_blank, :launched_only, :use_ids)

    options = {
      :field_name    => "subscriber[city]",
      :include_blank => false,
      :launched_only => true,
      :blank_text    => "Please select",
      :use_ids       => false
    }.merge(options)

    markets = publisher_or_publishing_group_markets(publisher, options[:launched_only])

    if markets.present?
      html = %{<select name="#{options[:field_name]}" class="market_selection">}

      if options[:include_blank]
        html += %{<option value="">#{options[:blank_text]}</option>}
      end

      markets.each do |market|
        html += "<option"

        if options[:use_ids]
          html += %{ value="#{market.id}"}
        end

        html += ">#{market_name_or_city(market)}</option>"
      end

      html += '</select>'

      html_safe(html)
    end
  end

  def market_selection_list(publisher, *options)
    options = options_to_hash(options, :use_landing_page)

    options = {
      :use_landing_page => false,
      :launched_only    => true
    }.merge(options)

    path_callback = options[:path_callback]
    markets = publisher_or_publishing_group_markets(publisher, options[:launched_only])

    if markets.present?
      html = '<ul class="market_selection_list">'
      markets.each do |market|
        path = path_callback.present? ? path_callback.call(market) : market_path(market, options[:use_landing_page])
        market = market_name_or_city(market)

        html += %{<li><a href="#{path}">#{market}</a></li>}
      end
      html += '</ul>'

      html_safe(html)
    end
  end
  
  def offers_market_selection_list(publisher, *options)
    market_selection_list(
      publisher, :path_callback => lambda { |market| public_offers_path(market) })
  end

  def market_selection_dropdown(publisher, *options)
    options = options_to_hash(options, :launched_only, :blank_option_string, :include_state)

    options = {
      :launched_only => true,
      :blank_option_string => "Your city",
      :include_state => false
    }.merge(options)

    markets = publisher_or_publishing_group_markets(publisher, options[:launched_only])

    market_name_callback = options[:market_name_callback]
    path_callback = options[:path_callback]

    if markets.present?
      html = %{<select class="market_selection_dropdown"}
      html += ' onchange="if (this.options[this.selectedIndex].value)'
      html += ' {window.location=this.options[this.selectedIndex].value;}">'

      html += '<option value="">' + options[:blank_option_string] + '</option>'

      markets.each do |market|
        market_name = market_name_callback ? market_name_callback.call(market) : market_name_or_city(market)
        path = path_callback ? path_callback.call(market) : market_path(market, false)

        html += %{<option value="#{path}">#{market_name}#{ options[:include_state] ? ", #{market.state}" : ''}</option>}
      end

      html += '</select>'

      html_safe(html)
    end
  end
  
  def offers_market_select_dropdown(publisher, launched_only = true)
    market_selection_dropdown(publisher,
      :launched_only => launched_only,
      :path_callback => lambda { |market| public_offers_path(:publisher_id => market.id) },
      :market_name_callback => lambda { |market| "#{market.city}, #{market.state}" })
  end
  
  protected

  def market_path(market, use_landing_page)
    case market
    when Publisher
      if use_landing_page
        publisher_landing_page_path(:publisher_id => market.label)
      else
        public_deal_of_day_path(:label => market.label)
      end
    when Market
      public_deal_of_day_for_market_path(market.publisher.label, market.label)
    when ::Drop::Publisher
      if use_landing_page
        market.landing_page_path
      else
        market.todays_daily_deal_path
      end
    when ::Drop::Market
      market.todays_daily_deal_path
    end
  end

  def market_name_or_city(market)
    case market
    when Publisher, ::Drop::Publisher
      market.market_name_or_city
    when Market, ::Drop::Market
      market.name
    end
  end

  def publisher_or_publishing_group_markets(publisher_or_publishing_group, launched_only)
    case publisher_or_publishing_group
    when Publisher, ::Drop::Publisher
      if publisher_or_publishing_group.markets.present?
        publisher_or_publishing_group.markets.sort_by(&:name)
      else
        publishing_group_market_publishers(publisher_or_publishing_group.publishing_group, launched_only)
      end
    when PublishingGroup, ::Drop::PublishingGroup
      publishing_group_market_publishers(publisher_or_publishing_group, launched_only)
    else
      raise ArgumentError, "Invalid argument to market_selection. Must be publisher or publishing group, but was #{publisher_or_publishing_group.try(:class)}"
    end
  end

  def publishing_group_market_publishers(publishing_group, launched_only)
    case publishing_group
    when PublishingGroup
      if launched_only
        publishers = publishing_group.publishers.included_in_market_selection.launched
      else
        publishers = publishing_group.publishers.included_in_market_selection
      end
    when ::Drop::PublishingGroup
      if launched_only
        publishers = publishing_group.live_publishers_included_in_market_selection
      else
        publishers = publishing_group.publishers_included_in_market_selection
      end
    when nil
      publishers = []
    end

    publishers.select(&:market_name_or_city).sort_by(&:market_name_or_city)
  end

  def options_to_hash(options, *keys)
    if options.first.is_a? Hash
      options = options.first
    else
      options_hash = {}
      keys.each_with_index do |key, i|
        options_hash[key] = options[i] if options[i] != nil
      end
      options_hash
    end
  end

  def html_safe(html)
    if respond_to?(:raw)
      raw(html)
    else
      html
    end
  end

end
