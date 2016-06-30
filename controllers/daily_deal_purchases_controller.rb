class DailyDealPurchasesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include DailyDeals::Analytics
  include DailyDeals::Orders
  include Publishers::Themes
  include Api
  include DailyDealPurchaseHelper
  include DailyDealPurchases::Braintree
  include DailyDealPurchases::ConsumerActionGuard
  include DailyDealPurchases::Create

  helper_method :current_daily_deal_order

  if ssl_rails_environment?
    ssl_required :resend_email, :loyalty_refund, :index, :redeemed, :expired, :show, :new, :optimal, :confirm, :optimal_confirm, :optimal_return, :edit, :admin_index, :consumers_admin_index, :consumers_admin_edit, :consumers_admin_update, :status
    ssl_required :admin_void_or_full_refund, :admin_partial_refund_index, :admin_partial_refund, :review_and_buy_form
  else
    ssl_allowed  :resend_email, :loyalty_refund, :index, :redeemed, :expired, :show, :new, :optimal, :confirm, :optimal_confirm, :optimal_return, :edit, :admin_index, :consumers_admin_index, :consumers_admin_edit, :consumers_admin_update, :status
    ssl_allowed  :admin_void_or_full_refund, :admin_partial_refund_index, :admin_partial_refund, :review_and_buy_form
  end
  ssl_allowed :deal_credit, :create, :destroy, :update, :braintree_redirect, :execute_free, :thank_you

  layout with_theme("daily_deals")

  before_filter :check_and_set_api_version_header_for_json_requests, :only => [ :status, :create, :braintree_redirect ]
  before_filter :verify_session_or_consumer_and_not_both_for_json_requests!, :only => [:create]
  require_api_version :minimum => "2.0.0", :only => [:daily_deal_certificates]
  before_filter :login_via_session_for_json_request!, :only => [ :daily_deal_certificates, :status ]
  before_filter :set_daily_deal, :only => [ :new, :optimal, :create, :deal_credit, :review_and_buy_form ]  
  before_filter :set_daily_deal_purchase, :only => [ :confirm, :optimal_confirm, :optimal_return, :edit, :update,
                                                     :braintree_redirect, :execute_free, :thank_you, :ts_errors,
                                                     :resend_email, :error ]
  before_filter :set_publisher, :only => [ :index, :redeemed, :refunded, :expired, :show ]
  before_filter :set_consumer, :only => [:consumers_admin_index]
  before_filter :set_consumer_by_id_if_access_allowed, :only => [:show]
  before_filter :set_daily_deal_purchase_and_consumer, :only => [:consumers_admin_edit, :consumers_admin_update]
  before_filter :admin_privilege_required, :only => [
    :admin_index, :admin_void_or_full_refund, :admin_partial_refund_index, :admin_partial_refund
  ]
  before_filter :ensure_current_user_can_manage_consumer, :only => [:loyalty_refund, :consumers_admin_index, :consumers_admin_edit, :consumers_admin_update, :admin_index]
  before_filter :set_daily_deal_variation, :only => [:new, :create]
  before_filter :require_consumer_unless_registration_is_allowed_during_purchase_process, :only => [:new, :create]
  before_filter :require_consumer_or_purchase_session, :only => [:confirm, :thank_you]
  before_filter :ensure_redirect_to_affiliate_url_for_daily_deal_or_daily_deal_variation, :only => [:new, :create]

  def index
    return unless allow_consumer_action?
    @consumer = @publisher.find_consumer_by_id_if_access_allowed(params[:consumer_id])
    @daily_deal_purchases = @consumer.my_daily_deal_purchases
    render with_theme
  end
  
  def error
    unless @daily_deal_purchase.travelsavers?
      raise NotImplementedError,
            "purchase error page is currently implemented only for Travelsavers purchases " +
            "and DailyDealPurchase #{@daily_deal_purchase.id} is not a Travelsavers purchase"
    end

    booking = @daily_deal_purchase.travelsavers_booking
    begin
      if booking.has_errors_that_cant_be_ignored?
        set_travelsavers_errors_user_can_fix(booking)
        set_travelsavers_errors_user_cannot_fix(booking)
        set_travelsavers_checkout_form_values(booking)

        if booking.unfixable_errors.present?
          render with_theme(:template => "daily_deal_purchases/ts_errors")
        else
          redirect_to confirm_daily_deal_purchase_url(@daily_deal_purchase)
        end
      end
    rescue Travelsavers::BookTransaction::UnknownStatusError => e
      Exceptional.handle(e)
      flash[:travelsavers_errors_user_cannot_fix] = ["An unknown error occurred. Please contact customer support."]
    end
  end

  def loyalty_refund
    purchase = DailyDealPurchase.find(params[:id])
    purchase.loyalty_refund!(current_user)
    formatted_loyalty_refund_amount = number_to_currency(purchase.loyalty_refund_amount, :unit => purchase.currency_symbol)
    flash[:notice] = "Loyalty refund for #{formatted_loyalty_refund_amount} was successful"
    redirect_to daily_deal_purchases_consumers_admin_edit_path(purchase.id)
  end

  def redeemed
    return unless allow_consumer_action?
    @consumer = @publisher.find_consumer_by_id_if_access_allowed(params[:consumer_id])
    @redeemed_certificates = @consumer.daily_deal_certificates.redeemed_and_marked_used_by_user
    @past_travelsavers_bookings = @consumer.travelsavers_bookings.with_service_start_date_in_past
    @redeemed_items = @redeemed_certificates + @past_travelsavers_bookings
    render with_theme
  end
  
  def refunded
    return unless allow_consumer_action?
    @consumer = @publisher.find_consumer_by_id_if_access_allowed(params[:consumer_id])
    @refunded_certificates = @consumer.daily_deal_certificates.not_travelsavers.refunded
    @refunded_travelsavers_bookings = @consumer.travelsavers_bookings.refunded
    @refunded_items = @refunded_certificates + @refunded_travelsavers_bookings
    render with_theme
  end
  
  def expired
    return unless allow_consumer_action?
    @consumer = @publisher.find_consumer_by_id_if_access_allowed(params[:consumer_id])
    @expired_certificates = @consumer.daily_deal_certificates.expired
    render with_theme    
  end

  def admin_index
    @daily_deal = DailyDeal.find(params[:daily_deal_id])
    render :layout => "application"
  end

  def consumers_admin_index
    @daily_deal_purchases = @consumer.my_daily_deal_purchases
    render :layout  => "application"
  end

  def show
    can_manage_consumer = current_user && current_user.can_manage_consumer?(@consumer)
    return unless can_manage_consumer || allow_consumer_action?
    @daily_deal_purchase = @consumer.daily_deal_purchases.find_by_uuid(params[:id])
    @filename = @daily_deal_purchase.daily_deal_certificates_file_name
    respond_to do |format|
      format.pdf do
        send_data @daily_deal_purchase.daily_deal_certificates_pdf, :filename => @filename, :type => :pdf
      end
      format.html do
        if custom_voucher_template_exists?(source_publisher_label)
          @source_publisher = Publisher.find_by_label(source_publisher_label)
          render :layout => false, :template => custom_voucher_template_path(source_publisher_label)
        else
          render_404
        end
      end
    end
  end

  def status
    @daily_deal_purchase = current_consumer.daily_deal_purchases.find_by_uuid(params[:id])
    respond_to do |format|
      format.json do
        if @daily_deal_purchase.present?
          render with_api_version
        else
          render :nothing => true, :status => :not_found
        end
      end
    end
  end

  def new
    build_daily_deal_purchase
    analytics_tag.presale!
    render with_theme(:layout => "daily_deals", :template => "daily_deal_purchases/new")
  end

  def review_and_buy_form
    build_daily_deal_purchase
    @daily_deal_purchase.quantity = params[:quantity]
    @daily_deal_purchase.gift = params[:gift]
    if @daily_deal_purchase.gift?
      @daily_deal_purchase.expected_number_of_recipients.times do
        @daily_deal_purchase.recipients.build
      end
    end
    render :partial => "review_and_buy_form"
  end

  # this is for handling new/create within an iframe for
  # the optimal payment gateway.
  def optimal
    build_daily_deal_purchase
    render with_theme(:layout => "optimal", :template => "daily_deal_purchases/optimal")
  end
  
  def create
    if @daily_deal.non_voucher_deal?
      find_or_create_non_voucher_deal_purchase
    else
      create_and_render_daily_deal_purchase
    end
    set_purchase_session(@daily_deal_purchase.consumer.purchase_auth_token) if @daily_deal_purchase
  end

  def confirm
    if @publisher.pay_using?(:paypal)    
      @paypal_configuration = PaypalConfiguration.for_currency_code(@publisher.currency_code)
      @paypal_configuration.setup_paypal_notification! if @paypal_configuration
    elsif @publisher.pay_using?(:cyber_source)
      @cyber_source_order = CyberSource::Order.new(
        :billing_first_name => @daily_deal_purchase.consumer.first_name,
        :billing_last_name => @daily_deal_purchase.consumer.last_name,
        :billing_address_line_1 => @daily_deal_purchase.consumer.address_line_1,
        :billing_address_line_2 => @daily_deal_purchase.consumer.address_line_2,
        :billing_city => @daily_deal_purchase.consumer.billing_city,
        :billing_state => @daily_deal_purchase.consumer.state,
        :billing_postal_code => @daily_deal_purchase.consumer.zip_code,
        :billing_country => @daily_deal_purchase.consumer.country_code.downcase,
        :billing_email => @daily_deal_purchase.consumer.email
      )
    elsif @publisher.pay_using?(:credit)
      consumer = @daily_deal_purchase.consumer
      @billing_address = OpenStruct.new({
        :first_name => consumer.first_name,
        :last_name => consumer.last_name,
        :street_address => consumer.address_line_1,
        :extended_address => consumer.address_line_2,
        :locality => consumer.billing_city,
        :region => consumer.state,
        :postal_code => consumer.zip_code,
        :country_code_alpha2 => consumer.country_code
        })
    end
  end
  
  def edit
    if @publisher.pay_using?(:optimal)
      render :optimal, :layout => "optimal"
    else
      render :new
    end
  end

  def consumers_admin_edit
    render :layout => "application"
  end

  def consumers_admin_update
    @daily_deal_purchase.store = Store.find(params[:daily_deal_purchase][:store_id]) if params[:daily_deal_purchase][:store_id].present?
    @daily_deal_purchase.gift = params[:daily_deal_purchase][:gift]
    if (recipient_names = params[:daily_deal_purchase][:recipient_names]).present?
      @daily_deal_purchase.recipient_names = recipient_names.map(&:strip)
    end

    if !@daily_deal_purchase.save
      flash[:warn] = "Save Failed"
      @daily_deal_purchase.errors.each { |attr, msg| flash[:warn] = msg }
      render :consumers_admin_edit, :layout => "application"
    else
      flash[:notice] = "Updated"
      redirect_to consumers_daily_deal_purchases_admin_index_path(@daily_deal_purchase.consumer)
    end
  end

  def admin_void_or_full_refund
    daily_deal_purchase = DailyDealPurchase.find_by_uuid(params[:id])
    daily_deal_purchase.void_or_full_refund! current_user
    flash[:notice] = daily_deal_purchase.travelsavers? ? "Changed status of booking ##{daily_deal_purchase.travelsavers_booking.confirmation_number} to refunded" : "The purchase was refunded"
  rescue StandardError => error
    logger.warn error
    flash[:warn] = "There was an error processing the void or full refund: #{error.message}"
  ensure
    @consumer = daily_deal_purchase.try(:consumer)
    redirect_to daily_deal_purchases_consumers_admin_edit_url(daily_deal_purchase.id)
  end

  def admin_partial_refund_index
    @daily_deal_purchase = DailyDealPurchase.find_by_uuid(params[:id])
    render :layout => "application"
  end

  def admin_partial_refund
    daily_deal_purchase = DailyDealPurchase.find_by_uuid(params[:id])
    raise "No certs specified" if params[:daily_deal_certificate].nil?
    all_cert_ids = params[:daily_deal_certificate].keys
    cert_ids_to_refund = all_cert_ids.select { |cert_id| params[:daily_deal_certificate][cert_id][:refunded] == "1" }
    results = daily_deal_purchase.partial_refund!(current_user, cert_ids_to_refund)
    flash[:notice] = "Refunded #{pluralize(results[:number_of_certs_refunded], 'voucher')} for a total of #{number_to_currency(results[:amount_refunded])}"
  rescue StandardError => error
    logger.warn error.backtrace
    flash[:warn] = "There was an error processing the partial refund: #{error.message}"
  ensure
    @consumer = daily_deal_purchase.try(:consumer)
    redirect_to daily_deal_purchases_consumers_admin_edit_url(daily_deal_purchase.id)
  end

  def current
    publisher = Publisher.find_by_label!(params[:label])
    if (daily_deal = publisher.daily_deals.active.first)
      redirect_to new_daily_deal_daily_deal_purchase_path(daily_deal)
    else
      flash[:warning] = "That deal is no longer available."
      redirect_to public_deal_of_day_path(publisher.label)
    end
  end

  def update
    status = update_daily_deal_purchase
    
    if @daily_deal_purchase.consumer.force_password_reset?
      redirect_to consumer_password_reset_path_or_url @publisher
    elsif :failure == status
      render_new_based_on_publishers_payment_method
    else
      deal_credit_applied :notice if @daily_deal_purchase.discount_amount > 0
      if @publisher.pay_using?(:optimal)
        redirect_to optimal_confirm_daily_deal_purchase_path(@daily_deal_purchase)
      elsif @publisher.shopping_cart?
        redirect_to publisher_cart_path(@publisher.label)
      else
        render_purchase_confirmation
      end
    end
  end

  def toggle_allow_execution
    @daily_deal_purchase = DailyDealPurchase.find_by_uuid(params[:id])
    if @daily_deal_purchase.toggle_allow_execution!
      flash[:notice] = "Set allow purchase for #{@daily_deal_purchase.consumer.name}."
    else
      flash[:warn] = "Cannot set allow purchase for #{@daily_deal_purchase.consumer.name}. Only voided purchases are allowed."
    end
    redirect_to daily_deal_daily_deal_purchases_admin_index_path(@daily_deal_purchase.daily_deal)
  end

  def braintree_redirect
    case (status = handle_braintree_redirect)
    when :already_executed
      redirect_after_duplicate_braintree_transaction
    when :success
      #
      # FIXME: Is the following auto-login step a security hole?
      #
      respond_to do |format|
        format.html do
          set_up_session @daily_deal_purchase.consumer unless @daily_deal_purchase.consumer == current_consumer
          cookies[:deal_credit] = { :value => "applied", :expires => 1.month.from_now }
          set_analytics_tag
          redirect_to thank_you_daily_deal_purchase_path(@daily_deal_purchase)
        end
        format.json do
          @session = api_session_for_consumer(@daily_deal_purchase.consumer)
          @consumer = consumer_for_api(@daily_deal_purchase.consumer, @api_version)
          render with_api_version
        end
      end
    when :failure
      respond_to do |format|
        format.html do
          flash.now[:warn] = translate_with_theme("daily_deal_purchases.braintree_buy_now_form.credit_card_info_error")
          render :confirm
        end
        format.json do
          render :nothing => true, :status => :conflict
        end
      end
    else
      raise "Unexpected status #{status} from handle_braintree_redirect"
    end
  end

  def execute_free
    execute_free_purchase
    redirect_to thank_you_daily_deal_purchase_path(@daily_deal_purchase)
  end

  def thank_you
    unless flash[:analytics_tag].blank?
      analytics_tag.sale!(flash[:analytics_tag])
      flash[:analytics_tag] = nil
    end

    if @publisher.pay_using?( :optimal )
      render with_theme(:layout => "optimal", :template => "daily_deal_purchases/optimal_thank_you")
    elsif @daily_deal_purchase.pay_using?(:travelsavers)
      render "daily_deal_purchases/thank_you/travelsavers"
    else
      render with_theme(:layout => "daily_deals", :template => "daily_deal_purchases/thank_you")
    end
  end
  
  def optimal_confirm
    @shop_id              = OptimalPayments::Configuration.shop_id
    @optimal_payment_url  = OptimalPayments::ProfileCheckoutRequest.url
    @encoded_message, @signature = create_encoded_message_and_signature_for_daily_purchase( @daily_deal_purchase )

    render with_theme(:layout => "optimal", :template => "daily_deal_purchases/optimal_confirm")
  end

  def optimal_return
    set_up_session @daily_deal_purchase.consumer unless @daily_deal_purchase.consumer == current_consumer
    cookies[:deal_credit] = { :value => "applied", :expires => 1.month.from_now }
    @daily_deal_purchase.handle_optimal_return(params['confirmationNumber'])
    set_analytics_tag
    redirect_to(thank_you_daily_deal_purchase_path(@daily_deal_purchase))
  end

  def destroy
    ddp = DailyDealPurchase.find_by_uuid(params[:id])
    publisher = ddp ? ddp.publisher : Publisher.find(params[:publisher_id])

    if ddp && ddp.pending?
      ddp.destroy
      flash[:notice] = 'The item was removed.'
    else
      flash[:error] = 'The item could not be removed.'
    end

    redirect_to publisher_cart_path(publisher.label)
  end

  def resend_email
    unless @daily_deal_purchase.captured?
      raise ArgumentError, "can't resend confirmation email for DailyDealPurchase #{@daily_deal_purchase.uuid} because its " +
                           "status must be 'captured', but is '#{@daily_deal_purchase.payment_status}'"
    end
    @daily_deal_purchase.send_email!(:force => true)
    flash[:notice] = "Confirmation email successfully resent"
    redirect_to publisher_consumer_daily_deal_purchases_url(:publisher_id => @daily_deal_purchase.publisher.to_param,
                                                           :consumer_id => @daily_deal_purchase.consumer.to_param)
  end

  def daily_deal_certificates
    @daily_deal_purchase = current_consumer.daily_deal_purchases.find_by_uuid!(params[:id])

    respond_to do |format|
      format.json do
        render :json => @daily_deal_purchase.daily_deal_certificates
      end
    end
  end

  def non_voucher_redemption
    @daily_deal_purchase = current_consumer.non_voucher_daily_deal_purchases.find_by_uuid(params[:id])

    if @daily_deal_purchase
      @publisher = @daily_deal_purchase.publisher
      @daily_deal = @daily_deal_purchase.daily_deal
      render with_theme
    else
      consumer_access_denied(current_consumer.publisher)
    end
  end

  def current_publisher
    @publisher
  end

  private

  def set_travelsavers_errors_user_can_fix(travelsavers_booking)
    flash[:travelsavers_errors_user_can_fix] = travelsavers_booking.fixable_errors.map(&:consumer_message)
  end

  def set_travelsavers_checkout_form_values(travelsavers_booking)
    flash[:travelsavers_checkout_form_values] = travelsavers_booking.checkout_form_values
  end

  def set_travelsavers_errors_user_cannot_fix(travelsavers_booking)
    flash[:travelsavers_errors_user_cannot_fix] = travelsavers_booking.unfixable_errors.map(&:consumer_message)
  end

def verify_authenticity_token
    super unless request.format.json? && action_name == "create"
  end

  def set_daily_deal
    @daily_deal = DailyDeal.active_or_qr_code_active.find(params[:daily_deal_id], :include => :publisher)
    @publisher = @daily_deal.publisher
  end

  def set_daily_deal_purchase
    @daily_deal_purchase = DailyDealPurchase.find_by_uuid!(params[:id], :include => [:consumer, { :daily_deal => :publisher }])
    @consumer = @daily_deal_purchase.consumer
    @daily_deal = @daily_deal_purchase.daily_deal
    @publisher = @daily_deal.publisher
    @daily_deal_purchase.mailing_address || @daily_deal_purchase.build_mailing_address # gets cleared by validation or is nil unless shipping option chosen
  end

  def set_publisher 
    if params[:publisher_id].present?
      @publisher = Publisher.find(params[:publisher_id])
    else
      render_404
    end
  end

  # To show PDF generation errors in development
  def rescue_action_locally(exception)
    headers.delete("Content-Disposition")
    super
  end

  def deal_credit_applied(flash_key)
    flash_text = "Your #{number_to_currency(@daily_deal_purchase.discount_amount, :unit => @daily_deal_purchase.currency_symbol)} Deal Credit has been applied"
    if flash[flash_key].blank?
      flash[flash_key] = flash_text
    else
      flash[flash_key] += ". #{flash_text}"
    end
    cookies[:deal_credit] = { :value => "applied", :expires => 1.month.from_now }
  end

  def redirect_after_duplicate_braintree_transaction
    respond_to do |format|
      format.html do
        if !@daily_deal_purchase.executed?
          flash[:warn] = "Sorry, we couldn't complete this purchase. Please try again."
          return redirect_to(confirm_daily_deal_purchase_path(@daily_deal_purchase))
        elsif @daily_deal_purchase.consumer == current_consumer
          set_analytics_tag
          return redirect_to(thank_you_daily_deal_purchase_path(@daily_deal_purchase))
        else
          return redirect_to(public_deal_of_day_path(@daily_deal_purchase.publisher.label))
        end
      end
      format.json do
        render :nothing => true, :status => :not_acceptable
      end
    end
  end

  # If the publisher is using the optimal payment method
  # then we using the optimal view and layout, since its
  # being iframed.  Otherwise, we just use the default
  # new template and appropriate publisher layout.
  def render_new_based_on_publishers_payment_method
      unless request.format.json?
      unless @publisher.pay_using?( :optimal )
        render :new
      else
        render with_theme(:layout => "optimal", :template => "daily_deal_purchases/optimal")
      end
    else
      if @daily_deal_purchase
        if @daily_deal_purchase.consumer && @daily_deal_purchase.consumer.errors.present?
          render :json => {:errors => @daily_deal_purchase.consumer.errors.full_messages}.to_json, :layout => false, :status => :conflict
        else
          render :json => {:errors => @daily_deal_purchase.errors.full_messages}.to_json, :layout => false, :status => :conflict
        end
      else
        render :nothing => true, :status => :forbidden
      end
    end
  end

  def create_encoded_message_and_signature_for_daily_purchase( daily_deal_purchase )
    parameters = {
      :merchant_ref_num => daily_deal_purchase.uuid,
      :return_url       => optimal_return_daily_deal_purchase_url( daily_deal_purchase,   :protocol => 'https', :host => @publisher.daily_deal_host),
      :cancel_url       => optimal_confirm_daily_deal_purchase_url( daily_deal_purchase,  :protocol => 'https', :host => @publisher.daily_deal_host),
      :currency_code    => @publisher.currency_code,
      :shopping_cart    => [
        {
          :description => daily_deal_purchase.value_proposition,
          :quantity    => daily_deal_purchase.quantity,
          :amount      => daily_deal_purchase.total_price
        }
      ],
      :total_amount => daily_deal_purchase.total_price,
      :customer_profile => {
        :merchant_customer_id => daily_deal_purchase.uuid,
        :is_new_customer      => false
      },
      :locale       => @publisher.locale
    }
    OptimalPayments::ProfileCheckoutRequest.encoded_message_and_signature( parameters )
  end

  def create_and_render_daily_deal_purchase
    status = create_daily_deal_purchase

    if @daily_deal_purchase.consumer.force_password_reset?
      redirect_to consumer_password_reset_path_or_url @publisher
    elsif :failure == status
      render_new_based_on_publishers_payment_method
    else
      deal_credit_applied :notice if @daily_deal_purchase.discount_amount > 0
      if @publisher.pay_using?(:optimal)
        redirect_to optimal_confirm_daily_deal_purchase_path(@daily_deal_purchase)
      elsif @publisher.shopping_cart?
        render_shopping_cart
      elsif @daily_deal_purchase.non_voucher_purchase?
        execute_non_voucher_daily_deal_purchase_and_redirect
      else
        render_purchase_confirmation
      end
    end
  rescue ::Consumers::AfterCreateError => e
    flash[:warn] = e.message
    @daily_deal_purchase.consumer = @publisher.consumers.build
    render_new_based_on_publishers_payment_method
  end

  def find_or_create_non_voucher_deal_purchase
    previous_daily_deal_purchase = current_consumer.non_voucher_daily_deal_purchases.find_by_daily_deal_id(@daily_deal.id)

    if previous_daily_deal_purchase
      redirect_to non_voucher_redemption_daily_deal_purchase_url(previous_daily_deal_purchase)
    else
      create_and_render_daily_deal_purchase
    end
  end

  def verify_session_or_consumer_and_not_both_for_json_requests!
    if request.format.json?
      if params[:consumer][:session] && (params[:consumer][:email] || params[:consumer][:password])
        render :nothing => true, :status => :not_acceptable
      end
    end
  end

  def redirect_to_daily_deal_login(publisher_id)
    store_location
    redirect_to daily_deal_login_path(:publisher_id => publisher_id)
  end

  def execute_free_purchase
    @daily_deal_purchase.execute_without_payment!
    cookies[:deal_credit] = { :value => "applied", :expires => 1.month.from_now }
    set_analytics_tag
  end

  def execute_non_voucher_daily_deal_purchase_and_redirect
    execute_free_purchase
    redirect_to non_voucher_redemption_daily_deal_purchase_url(@daily_deal_purchase)
  end
  
  protected
  
  def render_shopping_cart
    respond_to do |format|
      format.html { redirect_to publisher_cart_url(@publisher.label) }
      format.json { render :layout => false }
    end
  end
  
  def render_purchase_confirmation
    respond_to do |format|
      format.html { redirect_to confirm_daily_deal_purchase_url(@daily_deal_purchase) }
      format.json { render :layout => false }
    end
  end
  
  def set_consumer
    @consumer = Consumer.find_by_id(params[:consumer_id])
  end

  def ensure_current_user_can_manage_consumer
    return true if admin?
    return true if current_user && current_user.can_manage_consumer?(@consumer)
    # if we don't have an admin or a current user who can manage the current consumer 
    # then default to the admin_privilege_required before filter (there's a lot of logic
    # there) 
    admin_privilege_required
  end

  def set_consumer_by_id_if_access_allowed
    @consumer = @publisher.find_consumer_by_id_if_access_allowed(params[:consumer_id]) if params[:consumer_id]
  end

  def set_daily_deal_purchase_and_consumer
    @daily_deal_purchase = DailyDealPurchase.find(params[:id])
    @consumer = @daily_deal_purchase.consumer if @daily_deal_purchase
  end

  def set_daily_deal_variation
    publisher = @daily_deal.publisher if @daily_deal
    if publisher && publisher.enable_daily_deal_variations?
      @daily_deal_variation = @daily_deal.daily_deal_variations.find_by_id( extract_daily_deal_variation_id_from_params )
    end
  end

  def ensure_redirect_to_affiliate_url_for_daily_deal_or_daily_deal_variation
    if @daily_deal.affiliate_url.present?
      redirect_to @daily_deal.affiliate_url and return false
    end
    if @daily_deal_variation && @daily_deal_variation.affiliate_url.present?
      redirect_to @daily_deal_variation.affiliate_url and return false
    end
  end

  def require_consumer_unless_registration_is_allowed_during_purchase_process
    if !@publisher.allow_registration_during_purchase && !current_consumer_for_publisher?(@publisher)
      consumer_access_denied(@publisher)
      false
    end
  end

  def require_consumer_or_purchase_session
    return if current_consumer_for_publisher?(@publisher)
    daily_deal_purchase = DailyDealPurchase.find_by_uuid! params[:id]
    return if has_matching_purchase_session?(daily_deal_purchase.consumer.purchase_auth_token)
    consumer_access_denied(@publisher)
  end

  def extract_daily_deal_variation_id_from_params
    params[:daily_deal_variation_id] || (params[:daily_deal_purchase]||{})[:daily_deal_variation_id]
  end

end
