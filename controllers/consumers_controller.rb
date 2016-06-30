class ConsumersController < ApplicationController
  include Publishers::Themes
  include Api
  include ::Consumers::Cookies::LastSeenDeal
  include ::Consumers::RedirectToLocalDeal

  if ssl_rails_environment?
    ssl_required :new, :presignup, :send_activation_request, :show, :edit, :index, :activate_by_administrator, :add_credit, :daily_deal_purchases
  else
    ssl_allowed :new, :presignup, :send_activation_request, :show, :edit, :index, :activate_by_administrator, :add_credit, :daily_deal_purchases
  end
  ssl_allowed :create, :activate, :update, :deal_credit, :refer_a_friend, :twitter, :facebook

  layout with_theme("daily_deals")

  before_filter :set_publisher, :only => [
    :index, :new, :presignup, :thank_you, :create, :deal_credit, :activate, :edit, :show, :update, :send_password_reset_link, :refer_a_friend, :twitter, :facebook
  ]

  before_filter :logged_in_for_publisher, :only => [:edit, :update, :refer_a_friend, :twitter, :facebook]
  before_filter :set_consumer_and_check_current_consumer, :only => [:show, :edit, :update]

  before_filter :redirect_to_current_consumer_publisher_account, :only => [:show]
  before_filter :redirect_to_presignup_if_publisher_is_not_launched, :only => [:create]

  before_filter :set_consumer, :only => [:activate_by_administrator]
  before_filter :ensure_can_manage_consumers_for_current_publisher, :only => [:index]
  before_filter :ensure_current_user_can_manage_consumer, :only => [:activate_by_administrator]
  before_filter :check_and_set_api_version_header_for_json_requests, :only => [:create, :activate, :daily_deal_purchases]
  before_filter :ensure_allow_consumer_show_action, :only => [:show]
  before_filter :login_via_session_for_json_request!, :only => [:daily_deal_purchases]
  require_api_version :minimum => "2.0.0", :only => [:daily_deal_purchases]

  skip_before_filter :verify_authenticity_token

  def index
    @text = params[:text].try(:strip)
    if @text.present?
      attrs = %w{ id login email name first_name last_name activation_code }
      @consumers = Consumer.manageable_by(current_user).find(
        :all, :limit => 200, :order => "created_at desc",
        :conditions => [attrs.map { |attr| "#{attr} LIKE :text" }.join(" OR "), { :text => "%#{@text}%" }]
      )
    else
      @consumers = Consumer.manageable_by(current_user).find(:all, :limit => 20, :order => "created_at desc")
    end
    render :layout => "application"
  end

  def new
    @discount = @publisher.find_usable_discount_by_code(params[:discount_code])
    @consumer = @publisher.consumers.new(:discount_code => @discount.try(:code))
    render with_theme
  end

  def presignup
    @discount = @publisher.find_usable_discount_by_code(params[:discount_code])
    @consumer = @publisher.consumers.new(:discount_code => @discount.try(:code))
    @referral_code = params[:referral_code]
    analytics_tag.presignup!
    render with_theme(:layout => [ "presignup", "daily_deals" ])
  end

  def create
    logout_keeping_session!
    attrs = (params[:consumer] || {}).reverse_merge(:referral_code => cookies[:referral_code], :user_agent => user_agent)
    attrs.slice!(
      :name,
      :email,
      :password,
      :password_confirmation,
      :agree_to_terms,
      :member_authorization,
      :member_authorization_required,
      :discount_code,
      :zip_code,
      :zip_code_required,
      :first_name,
      :last_name,
      :first_name_required,
      :last_name_required,
      :address_line_1,
      :address_line_2,
      :billing_city,
      :state,
      :country_code,
      :referral_code,
      :birth_year,
      :gender,
      :device,
      :user_agent,
      :daily_deal_category_ids,
      :publisher_membership_code_as_text,
      :preferred_locale
    )

    respond_to do |format|
      format.html do
        if @publisher.force_password_reset?(attrs[:email])
          return redirect_to consumer_password_reset_path_or_url @publisher
        elsif (@consumer = active_consumer(@publisher, attrs))
          begin
            set_up_session @consumer
            set_persistent_cookie(:publisher_label, @publisher.label)
          rescue => e
            Exceptional.handle(e, "User record is invalid.")
          end
          return redirect_back_or_default public_deal_of_day_path(@publisher.label)
        elsif (@consumer = passive_consumer(@publisher, attrs))
          @consumer.attributes = attrs.reverse_merge(:name => nil)
          @consumer.require_password = true
        else
          @consumer = @publisher.consumers.build(attrs)
        end

        if @consumer.save_detecting_duplicate_entry_constraint_violation
          @consumer.send_activation_email!
          @consumer.notify_third_parties_of_consumer_creation
          cookies[:deal_credit] = { :value => "applied", :expires => 1.month.from_now }
          set_persistent_cookie(:publisher_label, @publisher.label)
          set_current_locale_to_current_consumers_locale
          analytics_tag.signup!
          # It is possible that the attributes used to create the consumer
          # have resulted in the consumer being created with a different publisher.
          # Specifically, the publisher_membership_code_as_text attribute can reassociate the consumer.
          @publisher = @consumer.publisher
          render with_theme(:layout => "daily_deals", :template => "consumers/create")
        else
          @consumer.password = @consumer.password_confirmation = @consumer.agree_to_terms = @consumer.member_authorization = nil
          render_for_failed_creation
        end
      end
      format.json do
        @consumer = @publisher.consumers.build(attrs)
        @consumer.password_confirmation = @consumer.password
        if @consumer.save
          if "2.2.0" > api_version
            @consumer.send_activation_email!
            render :layout => false
          else
            #
            # Skip manual activation for consumers created via API version >= 3.0.0
            #
            @consumer.activate!
            @consumer.send_welcome_email!
            render :json => consumer_json_for_api(@consumer, api_version)
          end
        else
          render :layout => false, :status => :conflict
        end
      end
    end

  end

  def destroy
    consumers  = @publisher.consumers.find(params[:id])
    consumers.each(&:delete!)
    flash[:notice] = "Deleted #{consumers.size} #{consumers.size > 1 ? 'consumers' : 'consumer'}"
    # redirect_to publisher_consumers_path(@publisher)
  end
    
  def deal_credit
    if current_consumer
      flash[:warn] = "Sorry, you've already created an account"
      redirect_to public_deal_of_day_path(@publisher.label)
    else
      @discount = @publisher.signup_discount
      @consumer = @publisher.consumers.build(:discount_code => @discount.try(:code))
      render with_theme(:template => "consumers/new")
    end
  end

  def activate
    activation_code = params[:activation_code].try(:strip)

    if activation_code.blank?
      render with_theme(:template => "consumers/activate") 
      return
    end

    @consumer = @publisher.consumers.find_by_activation_code(activation_code)
    if @consumer
      if @consumer.valid?
        if !@consumer.active?
          @consumer.activate!
          logout_keeping_session!
          set_up_session @consumer
        end
        respond_to do |format|
          format.html do
            if current_user != @consumer
              redirect_to daily_deal_login_path(@publisher)
            elsif @publisher.launched?
              if @publisher.enable_redirect_to_last_seen_deal_on_login? && last_seen_deal_id.present?
                redirect_to daily_deal_url(last_seen_deal_id)
              else
                redirect_back_or_default public_deal_of_day_path(@publisher.label)
              end
            else
              redirect_to thank_you_publisher_consumer_url(@publisher, @consumer)
            end
          end
          format.json do
            render :json => consumer_json_for_api(@consumer, api_version)
          end
        end
      else
        respond_to do |format|
          format.html do
            flash[:error] = "Account not activated. Consumer is not valid"
            @publishers = Publisher.all
            @publisher = @consumer.publisher
            set_up_session @consumer
            render "consumers/edit"
          end
          format.json do
            render :nothing => true, :status => :unprocessable_entity
          end
        end
      end
    else
      respond_to do |format|
        format.html do
          render with_theme(:template => "consumers/activate")
        end
        format.json do
          render :nothing => true, :status => :not_found
        end
      end
    end

  end

  def activate_by_administrator
    if @consumer.valid?
      @consumer.activate!
      flash[:notice] = "Account activated for #{@consumer.name}"
      if admin?
        redirect_to consumers_path
      else # otherwise we have a publisher user who can manage consumers
        redirect_to publisher_consumers_path( @consumer.publisher )
      end
    else
      flash[:error] = "Account not activated. Consumer is not valid"
      @publishers = Publisher.all
      @publisher = @consumer.publisher
      render "admin/consumers/edit", :layout => 'application'
    end
  end

  def add_credit
    @consumer = Consumer.find(params[:id])
    @consumer.add_credit!
    if @consumer.errors.empty?
      flash[:notice] = "Added Credit for #{@consumer.name}"
    else
      flash[:warn] = "Could not add credit for #{@consumer.name}"
    end
    redirect_to consumers_path
  end

  def send_activation_request
    @consumer = Consumer.find(params[:id])
    ConsumerMailer.deliver_activation_request @consumer
  end

  def show
    render with_theme(:template => "consumers/show", :layout => "daily_deals")
  end

  def edit
    render with_theme(:template => "consumers/edit", :layout => "daily_deals")
  end

  def update
    if @publisher.require_billing_address?
      @consumer.attributes = params[:consumer].delete_if { |key, value| key == "email" }
    else
      @consumer.attributes = params[:consumer].slice(
        :first_name,
        :last_name,
        :email,
        :password,
        :password_confirmation,
        :address_line_1,
        :billing_city,
        :state,
        :zip_code_required,
        :zip_code,
        :country_code,
        :mobile_number,
        :birth_year,
        :gender,
        :daily_deal_category_ids,
        :publisher_membership_code_as_text,
        :preferred_locale,
        :agree_to_terms,
        :member_authorization,
        :member_authorization_required)
    end

    if @consumer.save
      if @consumer.publisher != @publisher
        # The update may have resulted in changing the consumer's publisher.
        # If this happens, we need to log the user into their new publisher.
        set_up_session @consumer
        flash.discard # no welcome message
      end
      set_persistent_cookie(:publisher_label, @consumer.publisher.label)
      set_current_locale_to_current_consumers_locale
      redirect_to public_deal_of_day_path(@consumer.publisher.label)
    else
      @consumer.password = @consumer.password_confirmation = nil
      render with_theme(:template => "consumers/edit", :layout => "daily_deals")
    end
  end

  def refer_a_friend
    raise ActiveRecord::RecordNotFound unless @publisher.enable_daily_deal_referral
    @consumer = current_consumer
    render with_theme(:template => "consumers/refer_a_friend")
  end

  def twitter
    raise ActiveRecord::RecordNotFound unless @publisher.enable_daily_deal_referral
    consumer = @publisher.find_consumer_by_id_if_access_allowed(params[:id])
    raise ActiveRecord::RecordNotFound unless current_consumer == consumer

    consumer.record_click "twitter"
    redirect_to "http://twitter.com/?status=#{CGI.escape(consumer.twitter_status(@publisher)).gsub('+', '%20')}"
  end

  def facebook
    raise ActiveRecord::RecordNotFound unless @publisher.enable_daily_deal_referral
    consumer = @publisher.find_consumer_by_id_if_access_allowed(params[:id])
    raise ActiveRecord::RecordNotFound unless current_consumer == consumer

    consumer.record_click "facebook"
    action = params[:popup].present? ? "sharer.php" : "share.php"
    url = consumer.referral_url_for_bit_ly(@publisher) + "&v=#{Time.now.to_i}"
    redirect_to "http://www.facebook.com/#{action}?u=#{CGI.escape(url)}&t=#{CGI.escape(consumer.facebook_title)}"
  end

  def current_publisher
    @publisher
  end

  def daily_deal_purchases
    consumer = Consumer.find_by_id(params[:id])
    consumer = nil unless current_consumer == consumer
    
    respond_to do |format|
      format.json do
        if consumer
          @daily_deal_purchases = consumer.daily_deal_purchases.executed
          render with_api_version
        else
          render :nothing => true, :status => :not_found
        end
      end
    end
  end

  private

  def render_for_failed_creation
    if @publisher.launched?
      if render_membership_code_error?
        render with_theme( :template => "consumers/membership_code_error" )
      else
        render with_theme( :template => "consumers/new" )
      end
    else
      render with_theme( :layout => [ "presignup", "daily_deals" ], :template => 'consumers/presignup' )
    end
  end

  def render_membership_code_error?
    error_message = translate_with_theme(:blank, :scope => 'activerecord.errors.messages.invalid')
    error = @consumer.errors.on(:publisher_membership_code_as_text)

    (error.present? && error = error_message &&
        !@consumer.publisher_membership_code_as_text.blank?) ? true : false
  end

  def set_publisher
    @publisher = Publisher.find(params[:publisher_id]) if params[:publisher_id].present?
  end

  def set_consumer_and_check_current_consumer
    @consumer = Consumer.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @consumer == current_consumer
  end

  def logged_in_for_publisher
    consumer_login_required(@publisher)
  end

  def active_consumer(publisher, attrs)
    email = attrs[:email].try(:strip)
    if email.present?
      consumer = Consumer.authenticate(publisher, email, attrs[:password])
      consumer && consumer.active? ? consumer : nil
    end
  end

  def passive_consumer(publisher, attrs)
    email = attrs[:email].try(:strip)
    if email.present?
      consumer = publisher.consumers.find_by_email(email)
      consumer && !consumer.active? ? consumer : nil
    end
  end

  def ensure_allow_consumer_show_action
    render_404 and return unless @publisher.allow_consumer_show_action?
  end

  def ensure_can_manage_consumers_for_current_publisher
    return if admin? # let the admin through

    unless current_user.present? && current_user.can_manage?(@publisher) && current_user.can_manage_consumers?
      return access_denied
    end
  end

  def ensure_current_user_can_manage_consumer
    return true if admin?
    return true if current_user && current_user.can_manage_consumer?(@consumer)
    # if we don't have an admin or a current user who can manage the current consumer 
    # then default to the admin_privilege_required before filter (there's a lot of logic
    # there) 
    admin_privilege_required
  end

  def set_consumer
    @consumer = Consumer.find(params[:id])
  end

  def redirect_to_presignup_if_publisher_is_not_launched
    if params[:consumer][:publisher_membership_code_as_text]
      pub = PublisherMembershipCode.find_by_code(params[:consumer][:publisher_membership_code_as_text]).try(:publisher)
      if pub && !pub.launched?
        redirect_to presignup_publisher_daily_deal_subscribers_path(pub, :zip_code => params[:consumer][:zip_code],
                                                            :email => params[:consumer][:email],
                                                            :name => [params[:consumer][:first_name], params[:consumer][:last_name]].join(' '))
        return false
      end
    end
    true
  end
end
