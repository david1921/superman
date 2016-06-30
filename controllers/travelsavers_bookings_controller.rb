class TravelsaversBookingsController < ApplicationController
  include Publishers::Themes

  if ssl_rails_environment?
    ssl_required :handle_redirect, :try_to_resolve
  else
    ssl_allowed :handle_redirect, :try_to_resolve
  end

  layout with_theme("daily_deals")

  before_filter :set_travelsavers_booking, :except => :handle_redirect
  before_filter :set_publisher_from_travelsavers_booking, :except => :handle_redirect

  def handle_redirect
    [:ts_transaction_id, :daily_deal_purchase_id].each do |param_name|
      raise ArgumentError, "missing required parameter #{param_name}" unless params[param_name].present?
    end

    logger.debug "[Travelsavers] Got ts_transaction_id #{params[:ts_transaction_id]}"

    @travelsavers_booking = set_or_create_booking_record(params[:ts_transaction_id], params[:daily_deal_purchase_id])

    @daily_deal = @travelsavers_booking.daily_deal_purchase.daily_deal
    @publisher = @travelsavers_booking.daily_deal_purchase.publisher
  end

  def try_to_resolve
    begin
      @travelsavers_booking.sync_with_travelsavers! if @travelsavers_booking.unresolved?
    rescue Exception => e
      Rails.logger.error("Unexpected error trying to resolve TravelsaversBooking #{@travelsavers_booking.id}: #{e.message}\n#{e.backtrace.join("\n")}")
      Exceptional.handle(e)
      render_unexpected_error_text && return
    end

    if @travelsavers_booking.unresolved?
      if polling_time_limit_exceeded? || @travelsavers_booking.needs_manual_review?
        if @travelsavers_booking.booking_succeeded?
          render_thank_you_response_text
        else
          deliver_unresolved_email @travelsavers_booking
          render_unresolved_response_text
        end
      else
        render :nothing => true
      end
    elsif @travelsavers_booking.success?
      render_thank_you_response_text
      set_up_session @travelsavers_booking.consumer unless @travelsavers_booking.consumer == current_consumer
    else
      render_error_response_text
    end
  end

  def unresolved
    if @travelsavers_booking.resolved?
      redirect_to thank_you_daily_deal_purchase_url(@travelsavers_booking.daily_deal_purchase) 
    else
      render with_theme
    end
  end

  private

  def set_travelsavers_booking
    @travelsavers_booking = get_booking(params[:id])
  end

  def set_publisher_from_travelsavers_booking
    @publisher = @travelsavers_booking.publisher
  end

  def set_or_create_booking_record(ts_transaction_id, purchase_uuid)
    existing_booking =  DailyDealPurchase.find_by_uuid!(params[:daily_deal_purchase_id]).travelsavers_booking
    if existing_booking && existing_booking.book_transaction_id == ts_transaction_id
      existing_booking
    else
      create_or_reset_booking_record!(params[:ts_transaction_id], params[:daily_deal_purchase_id])
    end
  end

  def create_or_reset_booking_record!(ts_transaction_id, purchase_uuid)
    TravelsaversBooking.create_or_reset_with_new_transaction_id!(ts_transaction_id, purchase_uuid)
  end

  def get_booking(booking_id)
    TravelsaversBooking.find(booking_id)
  end

  def polling_time_limit_exceeded?
    Time.zone.now > (@travelsavers_booking.updated_at + TravelsaversBooking::BROWSER_POLLING_TIME_LIMIT)
  end

  def render_thank_you_response_text
    render :text => success_url
  end

  def render_error_response_text
    render :text => error_daily_deal_purchase_url(@travelsavers_booking.daily_deal_purchase)
  end

  def render_unexpected_error_text
    render :text => unexpected_error_travelsavers_booking_url(@travelsavers_booking)
  end

  def render_unresolved_response_text
    render :text => unresolved_travelsavers_booking_url(@travelsavers_booking)
  end

  def success_url
    thank_you_daily_deal_purchase_url(@travelsavers_booking.daily_deal_purchase.to_param)
  end

  def redirect_based_on_whether_errors_are_fixable(travelsavers_booking)
    purchase = travelsavers_booking.daily_deal_purchase

    if travelsavers_booking.unfixable_errors.present?
      redirect_to ts_errors_daily_deal_purchase_url(purchase)
    else
      redirect_to confirm_daily_deal_purchase_url(purchase)
    end
  end

  def deliver_unresolved_email(travelsavers_booking)
    TravelsaversBookingMailer.deliver_unresolved_booking(travelsavers_booking)
  end
end

