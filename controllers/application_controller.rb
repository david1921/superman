
# Some controllers (Advertisers, Reports) will look for a User with a "demo@analoganalytics.com" login,
# and auto-login as that User. The demo User should be associated with a self-serve Publisher. Disabled in production.
class ApplicationController < ActionController::Base
  include Analog::DateHelper  
  include SslRequirement
  include Analog::SslRequirement
  include Application::PasswordReset
  include AuthenticatedSystem
  include DailyDeals::Orders
  include Facebook::Channel::ControllerActions
  include TimeWarnerCable::Logo
  include Application::UserAgent
  include UrlVerifier
  include ::Api::Authentication
  
  helper :all
  protect_from_forgery # :secret => '44177ad6d2f234cf6ede9399a1ef1c8b'
  filter_parameter_logging :password, :bin, :last_4

  AUTHENTICATION_REALM = "Analog Analytics API"

  unless Rails.env.production?
    after_filter :ensure_session_cookie_not_cached
  end

  before_filter :ssl_required_for_hosts_that_require_https
  before_filter :set_secure_session_cookie_for_hosts_that_require_https
  before_filter :enforce_admin_server
  before_filter :set_locale

  ActionController::Base.ip_spoofing_check = false
  
  helper_method :action_name
  helper_method :analytics_tag
  helper_method :consumer_password_reset_path_or_url
  
  caches_page :robots_txt, :channel
  
  def analytics_tag
    @analytics_tag ||= AnalyticsTag.new
  end
  
  
  def robots_txt
    # There is seldom any good reason to use this option. I think I may have just found one :)
    if !Rails.env.production?
      render :inline => "User-agent: *\r\nDisallow: /" 
    else
      expires_in 1.month
      render :inline => ""
    end
  end

  def what_is_cvv
    render :layout => false
  end

  private
  
  def date_range_defaulting_to_last_month(a, b)
    setup_date_range(a, b) do |dates_begin, dates_end|
      unless dates_begin || dates_end
        last_month = Time.zone.now.last_month
        dates_begin, dates_end = [last_month.beginning_of_month, last_month.end_of_month]
      end      
    end
  end
  
  def date_range_defaulting_to_last_30_days(a, b)
    setup_date_range(a, b) do |dates_begin, dates_end|
      unless dates_begin || dates_end
        today = Time.zone.now
        dates_begin, dates_end = [(today - 30.days).beginning_of_day, today.end_of_day]
      end
    end
  end  
  
  def setup_date_range(a, b)
    dates_begin, dates_end = [parse_date(a), parse_date(b)]
    new_dates_begin, new_dates_end = yield dates_begin, dates_end
    dates_begin = new_dates_begin || dates_begin
    dates_end   = new_dates_end || dates_end
    
    dates_begin ||= dates_end.last_month + 1.day
    dates_end ||= dates_begin.next_month - 1.day

    dates_begin, dates_end = [dates_end, dates_begin] if dates_end < dates_begin
    dates_begin .. dates_end
  end

  def https_only_host?
    HttpsOnlyHost.exists?(:host => request.host)
  end

  def set_secure_session_cookie_for_hosts_that_require_https
    return unless ssl_rails_environment?    
    request.session_options[:secure] = true if https_only_host?
  end

  def set_persistent_cookie(key, value)
    cookies[key] = {:value => value, :expires => 1.year.from_now, :secure => https_only_host?}
  end
  
  def api_call?
    request.format.json? || request.format.xml? || request.format.rss?
  end
  
  def self.ssl_rails_environment?
    Rails.env.production? || Rails.env.staging? || Rails.env.benchmark? || ENV["USE_SSL"]
  end

  def ssl_rails_environment?
    self.class.ssl_rails_environment?
  end
  helper_method :ssl_rails_environment?
  
  def self.ssl_required_if_ssl_rails_environment(*args)
    self.send((ssl_rails_environment? ? :ssl_required : :ssl_allowed), *args)
  end

  def enforce_reports_server
    if Rails.env.production? && !request.subdomains.include?("reports")
      redirect_to "#{request.protocol}reports.analoganalytics.com#{request.request_uri}"
    end
  end

  def enforce_admin_server
    if Rails.env.production? && request.subdomains.include?("reports")
      redirect_to "#{request.protocol}admin.analoganalytics.com#{request.request_uri}"
    end
  end
  
  def set_locale
    I18n.locale = params[:locale]
  end
  
  def require_google_offers_import_user_basic_auth
    authed_as_google_offers_user = authenticate_with_http_basic do |user, pass|
      user == "googleoffers" && pass == "nwyxTYwC"
    end    
    request_http_basic_authentication("Google Offers Feed API") unless authed_as_google_offers_user
  end
  
  helper_method :https_unless_development
  def https_unless_development
    if Rails.env.development?
      "http"
    else
      "https"
    end
  end
  
  helper_method :subscribed?
  def subscribed?
    cookies[:subscribed] == "subscribed"
  end
  
  helper_method :admin?
  def admin?
    current_user.present? && current_user.has_admin_privilege?
  end
  
  helper_method :full_admin?
  def full_admin?
    current_user.present? && current_user.has_full_admin_privileges?
  end
  
  helper_method :accountant?
  def accountant?
    current_user.present? && current_user.has_accountant_privilege?
  end
  
  %w{ publishing_group publisher advertiser affiliate }.each do |type|
    class_eval "helper_method :#{type}?", "app/controllers/application_controller.rb", 137
    class_eval "def #{type}?; current_user && current_user.#{type}?; end", "app/controllers/application_controller.rb", 138
  end
  
  helper_method :consumer?

  def consumer?
    logged_in? && current_user.consumer?
  end

  helper_method :current_consumer_for_publisher?

  def current_consumer_for_publisher?(publisher)
    logged_in? && publisher.allow_consumer_access?(current_consumer)
  end

  helper_method :current_consumer
  
  def current_consumer
    consumer? ? current_user : nil
  end

  def consumer_access_denied(publisher)
    store_location
    flash[:notice] = Analog::Themes::I18n.translate(publisher, :please_sign_in)
    redirect_to new_publisher_daily_deal_session_path(publisher)
  end
  
  def consumer_login_required(publisher)
    current_consumer_for_publisher?(publisher) || consumer_access_denied(publisher)
  end

  def set_p3p
    response.headers["P3P"] = 'CP="CAO PSA OUR"'
  end

  def add_crumb(text, link=nil)
    @crumbs ||= []
    @crumbs << [text, link]
  end

  def insufficient_privilege
    respond_to do |format|
      format.html do
        flash[:notice] = "Unauthorized access"
        redirect_to root_url
      end
      format.any(:js, :json, :xml) do
        render :nothing => true, :status => :forbidden
      end
    end
    false
  end
  
  def admin_privilege_required
    return access_denied unless authorized?
    admin? || insufficient_privilege
  end
  
  def full_admin_privilege_required
    return access_denied unless authorized?
    full_admin? || insufficient_privilege
  end
  
  def default_to_demo_login
    if current_user.nil? && !Rails.env.production?
      self.current_user = User.find_by_login("demo@analoganalytics.com")
    end
    user_required
  end

  def with_demo_or_regular_login
    if current_user.nil? && !Rails.env.production?
      self.current_user = User.find_by_login("demo@analoganalytics.com")
    end
    if authorized?
      yield
    else
      access_denied
    end
  end

  def stream_csv(filename)
    #
    # MS Internet Explorer needs special headers
    #
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers["Content-type"] = "text/plain"
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      headers['Expires'] = "0"
    else
      headers["Content-Type"] ||= 'text/csv'
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
    end

    render :text => Proc.new { |response, output|
      #
      # Rails 2.3 ActionController::Response doesn't have <<, only write
      #
      def output.<<(*args)
        write(*args)
      end
      yield FasterCSV.new(output, :row_sep => "\r\n")
    }
  end

  # defined here, instead of helper to to make it available to the controller.
  # particularly, Homes#index
  helper_method :render_public_offers_path
  def render_public_offers_path(publisher, parameters = {})
    parameters          = parameters.clone
    category            = parameters.delete(:category)
    seo_deals_path      = "#{publisher.label}_seo_deals_url"
    skip_trailing_slash = parameters.delete(:skip_trailing_slash) 
    if respond_to?(seo_deals_path.to_sym)
      category_id      = parameters.delete(:category_id) 
      category         ||= category_id # TODO: cleanup view locals to use category instead of category_id
      publisher_id     = parameters.delete(:publisher_id)  
      advertiser_label = parameters.delete(:advertiser_label) 
      host_and_port_parameters = { :host => publisher.production_host }
      host_and_port_parameters.merge!(:port => request.port) if request.port.present? && request.port != 80
      parameters.merge! host_and_port_parameters
      if advertiser_label
        url = send("#{publisher.label}_seo_advertiser_url", host_and_port_parameters.merge({:advertiser_label => advertiser_label, :trailing_slash => true}))        
      else
        url = send(seo_deals_path.to_sym, parameters.merge(:trailing_slash => !skip_trailing_slash))      
        if category && category.is_a?(Category)
          extended_path = category.parent ? "#{category.parent.label}/#{category.label}" : "#{category.label}"
          url.gsub!("deals", "deals/#{extended_path}")
        end
      end            
    else
      url = public_offers_url(publisher, parameters)
    end
    url
  end

  helper_method :render_public_advertisers_path
  def render_public_advertisers_path( publisher, parameters = {} )
    parameters             = parameters.clone
    category               = parameters.delete(:category)
    seo_businesses_path    = "#{publisher.label}_seo_businesses_url" 
    seo_map_path           = "#{publisher.label}_seo_map_url" 
    skip_map_url_transform = parameters.delete(:skip_map_url_transform) 
    skip_trailing_slash    = parameters.delete(:skip_trailing_slash)
    path_for_map           = parameters.delete(:path_for_map)
    if respond_to?( seo_businesses_path.to_sym )
      category_id      = parameters.delete(:category_id) 
      category         ||= category_id # TODO: cleanup view locals to use category instead of category_id
      publisher_id     = parameters.delete(:publisher_id)
      parameters.merge!( :host => publisher.production_host )
      parameters.merge!( :port => request.port) if request.port.present? && request.port != 80
      url = send(seo_businesses_path.to_sym, parameters.merge(:trailing_slash => !skip_trailing_slash))
      if category && category.is_a?( Category )        
        extended_path = category.parent ? "#{category.parent.label}/#{category.label}" : "#{category.label}"
        url.gsub!("businesses", "businesses/#{extended_path}")
      end
      url.gsub!("businesses", "map") if (@map||path_for_map) && !skip_map_url_transform
      url
    else
      parameters.merge!(:with_map => true) if (@map||path_for_map) && !skip_map_url_transform
      url = public_advertisers_url( publisher, parameters )
    end
    url
  end 

  def browse_market_name
    if params[:market_label]
      params[:market_label].gsub("-", " ").titleize
    elsif @daily_deal && @daily_deal.markets.first
      @daily_deal.markets.first.name
    else
      'National'
    end
  end

  def strictly_require_ssl
    return unless ssl_rails_environment?

    unless request.ssl?
      render :nothing => true, :status => :forbidden
    end
  end

  def default_url_options(options={})
    { :locale => I18n.locale }
  end

  def set_current_locale_to_current_consumers_locale
    I18n.locale = current_consumer.try(:reload).try(:preferred_locale) || I18n.locale
  end

  private
  
  def analytics_tag=(value)
    @analytics_tag = value
  end
  
  def ensure_session_cookie_not_cached
    if cache_control? && sesson_loaded?
      raise SecurityError, "Cache-Control header set and session accessed"
    end
  end
  
  def cache_control?
    cache_control = response.headers["Cache-Control"]
    cache_control && cache_control["max-age="] && !cache_control["max-age=0"]
  end
  
  def sesson_loaded?
    case session
    when Hash
      !session.empty?
    else
      session.send :loaded?
    end
  end  
  
  def render_404
    render :file => "#{Rails.root}/public/404.html", :status => :not_found, :layout => false
  end
  
  def detect_zip_code
    GeoIP.new(AppConfig.geoip_data_file).city(request.remote_ip).try(:postal_code)
  end
  
  def detect_market(publisher)
    zip = detect_zip_code
    market = publisher.find_market_by_zip_code(zip)
  end
  
  def set_zip_code_cookie(zip_code)
    cookies['zip_code'] = {
      :value   => zip_code,
      :expires => 10.years.from_now
    }
  end
  
  def current_zip_code
    @current_zip_code ||= cookies['zip_code']
  end
  
  def redirect_to_publisher_based_on_zip_code
    if @publishing_group && @publishing_group.stick_consumer_to_publisher_based_on_zip_code?
      if current_zip_code 
        publisher = @publishing_group.publishers.launched.by_zip_code(current_zip_code).first
        redirect_to( public_deal_of_day_url(:label => publisher.label) ) and return if publisher        
      end
    end
  end
  
  def current_market(publisher)
    return if publisher.nil? || publisher.markets.empty?
    market = publisher.find_market_by_zip_code(current_zip_code)
    unless market
      market = detect_market(publisher)
    end
    unless market
      market = publisher.markets.find_or_create_by_name("National")
    end
    market
  end
  
  def popup?
    params[:layout] == "popup"
  end



end
