class ConsumerPasswordResetsController < ApplicationController
  include Publishers::Themes
  include Api

  ssl_allowed :new, :create, :edit, :update, :setup

  layout with_theme("daily_deals")

  before_filter :set_publisher, :only => [:new, :create, :update]
  before_filter :set_consumer_from_perishable_token, :only => [:edit, :update, :setup]
  before_filter :check_and_set_api_version_header_for_json_requests, :only => [:create, :update]

  skip_before_filter :verify_authenticity_token, :only => [:create, :update]

  def new
    render with_theme(:layout => "daily_deals", :template => "consumer_password_resets/new")
  end

  def create
    email = params[:email].try(:strip)
    set_consumer(email)
    respond_to do |format|
      format.html do
        if @consumer
          if @consumer.active?
            @consumer.deliver_password_reset_instructions!
            render with_theme(:layout => "daily_deals", :template => "consumer_password_resets/create")
          else
            @consumer.deliver_activation_request
            render :template => "consumers/create"
          end
        else
          if Analog::Util::EmailValidator.new.valid_email?(email)
           flash[:warn] = translate_with_theme(:account_lookup_failure_message,
                                               :scope => :consumer_password_resets_controller)
          else
            flash[:warn] = translate_with_theme(:invalid_email_address_message,
                                                :scope => :consumer_password_resets_controller)
          end
          redirect_to :action => :new
        end
      end
      format.json do
        if @consumer
          if @consumer.active?
            @consumer.deliver_api_password_reset_instructions!
            render :layout => false
          else
            render :json => {:errors => ["Account is not active, please activate the account first"]}, :layout => false, :status => :conflict
          end
        else
          render :json => {:errors => ["Unable to find an account associated with that email address"]}, :layout => false, :status => :conflict
        end
      end
    end
  end

  def edit
    render with_theme(:layout => "daily_deals", :template => "consumer_password_resets/edit")
  end

  def update
    @consumer.password = params[:consumer][:password]
    @consumer.require_password = true
    respond_to do |format|
      format.html do
        @consumer.password_confirmation = params[:consumer][:password_confirmation]
        if @consumer.save
          set_up_session @consumer
          flash[:notice] = translate_with_theme(:password_update_successful_message,
                                                :scope => :consumer_password_resets_controller)

          redirect_to public_deal_of_day_path(@publisher.label)
        else
          @consumer.password = @consumer.password_confirmation = nil
          render with_theme(:layout => "daily_deals", :template => "consumer_password_resets/edit")
        end
      end
      format.json do
        @consumer.password_confirmation = @consumer.password
        if params[:consumer][:reset_code] == @consumer.perishable_token
          if @consumer.save
            render :json => consumer_json_for_api(@consumer, api_version)
          else
            render :json => { :errors => @consumer.errors.full_messages }.to_json, :layout => false, :status => :conflict
          end
        else
          render :json => { :errors => ["Invalid reset code"] }.to_json, :layout => false, :status => :conflict
        end
      end
    end
  end

  def setup
    if @consumer.setup!(params[:consumer])
      set_up_session @consumer
      flash[:notice] = translate_with_theme(:login_welcome_message, :name => @consumer.name)
      cookies[:deal_credit] = { :value => "applied", :expires => 1.month.from_now }
      redirect_to public_deal_of_day_path(@consumer.publisher.label)
    else
      @consumer.password = @consumer.password_confirmation = nil
      render :setup
    end
  end

  def current_publisher
    @publisher
  end

  private

  def set_consumer(email)
    # This method will lookup a consumer on the publisher group level if single
    # sign on is enabled. See app/models/publishers/finders.rb for details
    @consumer = @publisher.find_consumer_by_email_for_authentication(email)
  end

  def set_publisher
    @publisher = Publisher.find(params[:publisher_id])
  end

  def set_consumer_from_perishable_token
    @publisher = Publisher.find(params[:publisher_id])
    @consumer = @publisher.consumers.find_by_perishable_token(params[:id])
    if @publisher.allow_single_sign_on?
      @consumer ||= @publisher.publishing_group.consumers.find_by_perishable_token(params[:id])
    end
    unless @consumer
      respond_to do |format|
        format.html do
          flash[:warn] = translate_with_theme(:token_lookup_failure_message,
                                              :scope => :consumer_password_resets_controller)
          redirect_to public_deal_of_day_path(@publisher.label)
        end
        format.json do
          render :nothing => true, :status => :not_found
        end
      end
    end
  end
end
