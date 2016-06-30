module ApplicationHelper

  # A port of the page_context_is Liquid block logic for use in ERB
  def context_is?(context)
    page_context  = controller.instance_variable_get("@page_context")
    page_name     = controller.controller_name
    (@page_context == context || page_name == context) ? true : false
  end

  def page_title
    @page_title || "#{controller.controller_name.humanize.titleize}#{': ' + controller.action_name.humanize.titleize unless controller.action_name == 'index'}"
  end
  
  def set_page_title(value)
    @page_title = value
  end
  
  def extra_stylesheets
    @extra_stylesheets || []
  end
  
  def add_stylesheet(path)
    @extra_stylesheets = extra_stylesheets << path
  end

  # Only need this helper once, it will provide an interface to convert a block into a partial.
  # 1. Capture is a Rails helper which will 'capture' the output of a block into a variable
  # 2. Merge the 'body' variable into our options hash
  # 3. Render the partial with the given options hash. Just like calling the partial directly.
  def block_to_partial(partial_name, options = {}, &block)
    options.merge!(:body => capture(&block))
    concat(render(:partial => partial_name, :locals => options))
  end
  
  def service_name
    @@service_name ||= AppConfig.service_name || "TXT411"
  end

  def localized_date(value)
    value = if value == "now"
      Time.zone.now.to_date
    elsif value.respond_to?(:to_date)
      value.to_date
    else
      raise ArgumentError, "expected string 'now' or an object that responds to .to_date. got #{value.inspect}"
    end

    I18n.l(value, :format => :longer)
  end

  def switch_locale_url(locale_name)
    if request.get?
      url_for(params.merge(:locale => locale_name))
    elsif controller.action_name == 'update' && controller..respond_to?(:edit)
      url_for(params.merge(:locale => locale_name, :action => :edit))
    elsif controller.action_name == 'create' && controller..respond_to?(:new)
      url_for(params.merge(:locale => locale_name, :action => :new)) 
    end
  end

  def service_host
    @@service_host ||= AppConfig.service_host || "txt411.com"
  end
  
  def support_email_address
    @@support_email_address ||= AppConfig.support_email_address || "support@txt411.com"
  end
  
  def formatted_crumbs
    if @crumbs
      @crumbs.map { |text, link| link ? link_to(text, link) : text }.join('&nbsp;&brvbar;&nbsp;').html_safe
    else
      #
      # FIXME: eventually remove this clause
      #
      page_title
    end
  end

  def focus(form_field_name)
    render "shared/focus", :object => form_field_name
  end
  
  def navbar_link(text, url_or_path, options={})
    unless on_page?(url_or_path)
      link_to(text, url_or_path, options)
    else
      %Q(<span id="current_navbar_link">#{text}</span>).html_safe
    end
  end
  
  def on_page?(url_or_path)
    request_uri = url_or_path.index("?") ? request.request_uri : request.request_uri.split('?').first
    if url_or_path =~ /^\w+:\/\//
      url_or_path == "#{request.protocol}#{request.host_with_port}#{request_uri}"
    else
      url_or_path == request_uri
    end
  end
  
  def link_to_unescaped(name, url, html_options={})
    "#{tag(:a, html_options.merge(:href => url), true, false)}#{name || url}</a>".html_safe
  end
  
  def credit_card_month_options
   Range.new('01', '12').to_a
  end

  def credit_card_year_options
    Range.new(Time.now.year, 15.years.from_now.year).to_a.map(&:to_s)
  end
  
  def grouped_state_options
    [[ 'United States', us_state_options ],
    [ 'Canada', canadian_state_options ]]
  end
  
  def canadian_state_options
    Addresses::Codes::CA::STATE_CODES
  end
  
  def us_state_options
    Addresses::Codes::US::STATE_CODES
  end
  
  def protocol_relative_url(url)
    if url.is_a? String
      url.gsub(%r{http[s]?\:},'') 
    else
      url
    end 
  end

  def show_if(condition)
    "display: none;" unless condition
  end

  def deal_state_access?
    Rails.env.development? || admin? ||
    params[:deal_preview] == 'active' ||
    params[:deal_preview] == 'variation' ||
    params[:deal_preview] == 'expired' ||
    params[:deal_preview] == 'coming_soon' ||
    params[:deal_preview] == 'expired' ||
    params[:deal_preview] == 'sold_out'
  end
  
  def rum_header
    NewRelic::Agent.browser_timing_header rescue "" 
  end
  def rum_footer
    NewRelic::Agent.browser_timing_header rescue "" 
  end

  def analog_number_to_currency(number, options = {})
    number_to_currency(number, options)
  end

end
