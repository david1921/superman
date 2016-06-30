class DailyDealSubscribersController < ApplicationController
  include Publishers::Themes
  SUBSCRIBER_API_NAME = "Subscriber Creation API"

  # Need this line to ensure these actions work with IE + iFrame (e.g. inside an FB app.)
  before_filter :set_p3p

  protect_from_forgery :except => [:create, :presignup, :thank_you, :thank_you_2]
  ssl_allowed :create
  before_filter :set_publisher
  before_filter :redirect_to_market, :only => [:presignup]

  layout with_theme

  def presignup
    @subscriber = @publisher.subscribers.build
    @subscriber.subscriber_referrer_code = SubscriberReferrerCode.find_by_code(params[:subscriber_referrer_code]) if params[:subscriber_referrer_code].present?
    @referral_code = params[:referral_code]

    respond_to do |format|
      format.html { render with_theme }
      format.fbtab { render with_theme(:layout => "presignup") }
    end
  end

  def create
    return create_via_api if params[:api_access_key].present?

    verify_authenticity_token

    #this is the publisher that the subscriber will be assigned to, which is different than the
    #one being rendered for entertainment
    publisher = set_publisher_for_subscriber_create

    if publisher.present?
      @subscriber = publisher.subscribers.build(params[:subscriber].reverse_merge(:referral_code => cookies[:referral_code], :user_agent => user_agent))
      if @subscriber.save
        analytics_tag.signup!
        cookies[:subscribed] = "subscribed"
        set_zip_code_cookie_based_on_market
        flash[:notice] = translate_with_theme(:subscription_success_message)
      else
        flash[:warn] = translate_with_theme(:subscription_failure_message, :errors => @subscriber.errors.full_messages.join(". ") + ".")
      end

      if @subscriber.valid?
        flash[:analytics_tag] = analytics_tag.signup!

        # redirect_to_deal_page can be used when @publisher is not the same
        # as the publisher whose id is params[:publisher_id], as is the case
        # when params[:market_publisher_id] is used
        if params[:redirect_to_deal_page]
          redirect_url = public_deal_of_day_path(@publisher.label)
        else
          redirect_url = verify_url(params[:redirect_to]) || thank_you_publisher_daily_deal_subscribers_url(@publisher.label)
        end


        redirect_query = {:id => @subscriber.hashed_id}
        redirect_url += "?#{redirect_query.to_query}"

        redirect_to redirect_url
      else
        if params[:show_form_errors]
          action = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:presignup]) ? "presignup" : "new"
          render :template => template_for_publisher(@publisher, action)
        else
          redirect_to :back
        end
      end
    else
      if @market_publisher_id
        flash[:warn] = "Please select a city to subscribe to"
      end
      redirect_to :back
    end
  end

  def thank_you
    set_subscriber_from_hashed_id
    self.analytics_tag = flash[:analytics_tag]
    respond_to do |format|
      format.html { render with_theme }
      format.fbtab { render with_theme(:layout => "presignup") }
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    render_404
  end

  def thank_you_2
    respond_to do |format|
      format.html { render with_theme }
      format.fbtab { render with_theme(:layout => "presignup") }
    end
  end

  def update
    set_subscriber_from_hashed_id

    if @subscriber.update_attributes(params[:subscriber])
      flash[:notice] = "Subscription preferences saved."
    end

    redirect_to(verify_url(params[:redirect_to]) || public_deal_of_day_path(:label => @publisher.label))
  end

  private

  def log_subscribers_api_call_info(msg)
    Rails.logger.info("[#{SUBSCRIBER_API_NAME}] #{msg}")
  end

  def api_version
    @api_version = request.headers['API-Version']
  end

  def set_publisher_for_subscriber_create
    if @publisher.name.downcase == "entertainment"
      zip_code = params[:subscriber][:zip_code].to_s[0,5]
      pub_zip_code = PublisherZipCode.find_by_zip_code(zip_code)
      if pub_zip_code.present?
        pub_zip_code.publisher
      else
        @publisher
      end
    elsif params[:subscriber][:market_publisher_id]
      @market_publisher_id = params[:subscriber].delete(:market_publisher_id)

      @publisher = Publisher.find_by_id(@market_publisher_id)
    else
      @publisher
    end
  end

  def set_publisher
    @publisher = Publisher.find_by_label_or_id!(params[:publisher_id])
  end

  def create_via_api
    raise ActionController::InvalidAuthenticityToken unless "2K9Id8vvMq41821l" == params[:api_access_key]
    publisher = set_publisher_for_subscriber_create
    if publisher.present?
      @subscriber = publisher.subscribers.build((params[:subscriber] || {}).merge(:email_required => true))
      if @subscriber.save
        log_subscribers_api_call_info("Successfully added subscriber '#{@subscriber.email}' to publisher #{@subscriber.publisher.label}")
        status = :ok
      else
        log_subscribers_api_call_info("Failed to add subscriber '#{@subscriber.email}' to any publisher: #{@subscriber.errors.full_messages.join(", ")}")
        status = :bad_request
      end
      response.template.template_format = :xml
      render :action => :create_via_api, :layout => false, :status => status
    else
      subscriber_email = params[:subscriber][:email] rescue nil
      log_subscribers_api_call_info("Failed to add subscriber '#{subscriber_email}' to any publisher: no publisher with ID #{params[:publisher_id]} found")
      render :nothing => :true, :status => :bad_request
    end
  end

  def set_subscriber_from_hashed_id
    if params[:id].present?
      @subscriber = Subscriber.find_by_hashed_id(params[:id])
    end
  end

  def set_zip_code_cookie_based_on_market
    if @publisher.find_market_by_zip_code(params[:subscriber][:zip_code])
      set_zip_code_cookie(params[:subscriber][:zip_code])
    end
  end

  def redirect_to_market
    return if @publisher.nil? || @publisher.markets.empty? || !@publisher.launched?
    market = @publisher.find_market_by_zip_code(current_zip_code)

    unless market
      zip = detect_zip_code
      market = @publisher.find_market_by_zip_code(zip)
      set_zip_code_cookie(zip) if market
    end

    unless market
      market = @publisher.markets.find_or_create_by_name("National")
    end

    redirect_to public_deal_of_day_for_market_path(:label => @publisher.label, :market_label => market.label)
  end
end
