class OneClickPurchasesController < ApplicationController
  include DailyDeals::Analytics
  include Publishers::Themes
  include Api
  include DailyDealPurchases::Braintree
  include DailyDealPurchases::Create
  include OneClickPurchasesHelper

  ssl_required_if_ssl_rails_environment :new
  ssl_allowed :create, :update, :braintree_redirect, :thank_you

  layout with_theme("one_click_purchases")

  before_filter :set_daily_deal, :only => [:new, :create]
  before_filter :set_daily_deal_purchase, :only => [:update, :braintree_redirect, :thank_you]

  helper_method :current_daily_deal_order
  
  def new
    if @publisher.allow_registration_during_purchase || current_consumer_for_publisher?(@publisher)
      build_daily_deal_purchase
      @daily_deal_purchase.discount = nil
      @daily_deal_purchase.made_via_qr_code = true
      render with_theme(:template => "one_click_purchases/new")
    else
      consumer_access_denied(@publisher)
    end
  end

  def create

    # new.erb has three forms. The first form is being submited to here, where we create the daily deal purchase in rails. With that information we fill the form to submit to braintree redirect. Read javascripts/app/daily_deal_purchases/single_page_checkuot.js
    status = create_daily_deal_purchase

    if :failure == status
      render :xhr_purchase_details_form, :layout => false
    else
      host = @daily_deal_purchase.publisher.daily_deal_host
      @redirect_url = braintree_redirect_daily_deal_one_click_purchase_url(@daily_deal, @daily_deal_purchase, :host => host)
      render :xhr_braintree_redirect_form, :layout => false
    end
  rescue ::Consumers::AfterCreateError => e
    flash[:warn] = e.message
    @daily_deal_purchase.consumer = @publisher.consumers.build
    render :xhr_purchase_details_form, :layout => false
  end

  def update
    status = update_daily_deal_purchase
    
    if :failure == status
      render :xhr_purchase_details_form, :layout => false
    else
      host = @daily_deal_purchase.publisher.daily_deal_host
      @redirect_url = braintree_redirect_daily_deal_one_click_purchase_url(@daily_deal, @daily_deal_purchase, :host => host)
      render :xhr_braintree_redirect_form, :layout => false
    end
  end

  def braintree_redirect
    case (status = handle_braintree_redirect)
    when :already_executed
      if !@daily_deal_purchase.executed?
        flash.now[:warn] = "Sorry, we couldn't complete this purchase. Please try again."
        render with_theme(:template => "one_click_purchases/new")
      elsif @daily_deal_purchase.consumer == current_consumer
        set_analytics_tag
        redirect_to(thank_you_daily_deal_one_click_purchase_path(@daily_deal, @daily_deal_purchase))
      else
        redirect_to(public_deal_of_day_path(@daily_deal_purchase.publisher.label))
      end
    when :success
      set_up_session @daily_deal_purchase.consumer unless @daily_deal_purchase.consumer == current_consumer
      cookies[:deal_credit] = { :value => "applied", :expires => 1.month.from_now }
      set_analytics_tag
      redirect_to thank_you_daily_deal_one_click_purchase_path(@daily_deal, @daily_deal_purchase)
    when :failure
      flash.now[:warn] = translate_with_theme("daily_deal_purchases.braintree_buy_now_form.credit_card_info_error")
      render with_theme(:template => "one_click_purchases/new")
    else
      raise "Unexpected status #{status} from handle_braintree_redirect"
    end
  end
  
  def thank_you
    if flash[:analytics_tag].present?
      analytics_tag.sale!(flash[:analytics_tag])
      flash[:analytics_tag] = nil
    end
    render with_theme(:template => "one_click_purchases/thank_you")
  end
  

  private

  def set_daily_deal
    @daily_deal = DailyDeal.active_or_qr_code_active.find(params[:daily_deal_id], :include => :publisher)
    @publisher = @daily_deal.publisher
  end

  def set_daily_deal_purchase
    @daily_deal_purchase = DailyDealPurchase.find_by_uuid!(params[:id], :include => [:consumer, { :daily_deal => :publisher }])
    @consumer = @daily_deal_purchase.consumer
    @daily_deal = @daily_deal_purchase.daily_deal
    @publisher = @daily_deal.publisher
    @daily_deal_purchase.build_mailing_address unless @daily_deal_purchase.mailing_address
  end

end
