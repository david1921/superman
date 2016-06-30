class DailyDealSessionsController < ApplicationController
  include Publishers::Themes
  include Api
  include FacebookAuth
  include DailyDealSessions::AutoLogin
  include ::Consumers::Cookies::LastSeenDeal
  include ::Consumers::ValidConsumers

  require_api_version :minimum => "2.0.0", :only => [:api_facebook]

  if ssl_rails_environment?
    ssl_required :new
  else
    ssl_allowed  :new
  end
  ssl_allowed :create, :destroy, :api_facebook

  layout with_theme("daily_deals")

  before_filter :set_publisher, :except => [:daily_deals]
  before_filter :check_and_set_api_version_header_for_json_requests, :only => [:create, :api_facebook, :destroy]
  before_filter :flag_password_as_md5_on_get, :only => [:create, :daily_deals]
  before_filter :login_via_session_for_json_request!, :only => [:destroy]

  skip_before_filter :verify_authenticity_token, :only => [:create, :api_facebook, :destroy]

  def new
    session[:return_to] = place_to_return_to if safe_to_return

    @consumer = Consumer.new
    render with_theme(:layout => "daily_deals", :template => "daily_deal_sessions/new")
  end

  def create
    set_consumer_and_login
    respond_to do |format|
      format.html do
        if @consumer.try(:force_password_reset?)
          redirect_to consumer_password_reset_path_or_url(@publisher)
        elsif @consumer
          return if !ensure_valid_consumer
          set_current_locale_to_current_consumers_locale
          set_persistent_cookie(:publisher_label, @consumer.publisher.label)
          redirect_back_or_to_deal_page
        else
          flash[:warn] = if @consumer_account_locked
            translate_with_theme(:consumer_account_locked, :contact_url => contact_publisher_daily_deals_url(@publisher)).html_safe
          else
            translate_with_theme(:failed_login_message)
          end
          @consumer = Consumer.new
          redirect_back_on_failure? ? redirect_to( request_referrer ) : render( with_theme(:layout => "daily_deals", :template => "daily_deal_sessions/new") )
        end
      end
      format.js do
        render with_theme
      end
      format.json do
        if @consumer
          render :json => consumer_json_for_api(@consumer, api_version)
        else
          if @consumer_account_locked          
            render :json => { :errors => [I18n.t(:user_account_locked)] }.to_json, :layout => false, :status => :conflict
          else
            render :json => { :errors => ["Invalid username and/or password"] }.to_json, :layout => false, :status => :conflict
          end
        end
      end
    end
  end

  def api_facebook
    facebook_token = (params[:consumer]||{})[:facebook_token]
    if request.post?
      if facebook_token.present?
        consumer = consumer_for_publisher_via_facebook_token(@publisher, facebook_token)
        unless current_consumer # check that we are actually logged in.
          if consumer
            @errors = consumer.errors.full_messages
          else
            @errors = ["We were unable find or create an account."]
          end
          render "api/failure.json", :layout => false, :status => :not_acceptable
        else
          render :json => consumer_json_for_api(current_consumer, api_version)
        end
      else
        @errors = ["Missing facebook token."]
      end
    else
      @errors = ["Request needs to be a POST request."]
      render "api/failure.json", :layout => false, :status => :not_acceptable
    end
  end

  def destroy
    if current_consumer
      logger.info "DailyDealSessionsController#destroy #{Time.now.to_s(:db)} session for #{current_consumer}"
      name = current_consumer.name
      logout_killing_session!
      flash[:notice] = translate_with_theme(:logout_goodbye_message, :name => name)
    end
    respond_to do |format|
      format.html do
        redirect_back_or_default public_deal_of_day_path(@publisher.label)
      end
      format.json do
        render with_api_version(:template => "publishers/show")
      end
    end
    
  end

  def daily_deals
    deal = DailyDeal.find(params[:id])
    @publisher = deal.publisher
    set_consumer_and_login
    if @consumer.try(:force_password_reset?)
      redirect_to consumer_password_reset_path_or_url(@publisher)
    else
      if params[:referral_code].present?
        redirect_to daily_deal_url(deal, :referral_code => params[:referral_code])
      else
        redirect_to daily_deal_url(deal)
      end
    end
  end

  def current_publisher
    @publisher
  end

  private

  def consumer_params
    @consumer_params ||= params[:session] || {}
  end

  def email
    @email ||= consumer_params[:email].try(:strip)
  end

  def set_publisher
    @publisher = Publisher.find(params[:publisher_id])
  end

  def set_consumer_and_login
    case auth_result = Consumer.authenticate(@publisher, email, consumer_params[:password])
    when User
      @consumer = auth_result
      set_up_session @consumer, consumer_params[:remember_me_flag] == "1"
      logger.info "#{Time.now.to_s(:db)} DailyDealSessionsController#create for publisher_id #{@publisher.try(:id)} found: #{@consumer}"
      flash.discard
    when :locked
      @consumer = nil
      @consumer_account_locked = true
    else
      if auth_result.blank?
        @consumer = @publisher.find_consumer_by_email_if_force_password_reset(email)
        if @consumer
          flash[:warn] = "You must change your password."
        end
      else
        Rails.logger.warn "Unexpected return value from Consumer.authenticate: #{auth_result.inspect}"
      end
    end
  end

  def place_to_return_to
    params[:return_to] || request_referrer
  end

  def request_referrer
    request.referrer
  end

  def production_host
    @publisher.try(:production_host)
  end

  def safe_to_return
    return true if params[:return_to].present?
    return false unless request_referrer.try(:present?)
    return false unless production_host.try(:present?)
    production_host == URI.parse(request_referrer).host
  end

  def redirect_back_or_to_deal_page
    if @publisher.enable_redirect_to_last_seen_deal_on_login? && last_seen_deal_id.present?
      redirect_to daily_deal_url(last_seen_deal_id)
    elsif @consumer.publisher != @publisher && @publisher.allow_publisher_switch_on_login?
      redirect_to public_deal_of_day_path(@consumer.publisher.label)
    else
      redirect_back_or_default public_deal_of_day_path(@publisher.label)
    end
  end
  
  def consumer_for_publisher_via_facebook_token(publisher, facebook_token)
    facebook_signin(publisher, access_token_from_publisher_and_facebook_token(publisher, facebook_token))    
  end
  def access_token_from_publisher_and_facebook_token(publisher, facebook_token)
    OAuth2::AccessToken.new(FacebookAuth.oauth2_client(publisher), facebook_token)
  end

  def redirect_back_on_failure?
    "true" == params[:redirect_back_on_failure] && request_referrer.present?
  end

  
end
