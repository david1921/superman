class CyberSourceController < ApplicationController
  include Publishers::Themes
  include DailyDeals::Analytics
  
  ssl_allowed :decline, :receipt
  
  protect_from_forgery :except => [:decline, :receipt]

  layout with_theme("daily_deals")

  def decline
    @daily_deal_purchase, @cyber_source_order = CyberSource::Context::Decline.call(request)
    render_order_failure
  end
  
  def receipt
    @daily_deal_purchase, @cyber_source_order = CyberSource::Context::Receipt.call(request)

    if @daily_deal_purchase.previously_executed
      handle_repeated_sale
    else
      handle_order_success
    end
  end

  private
    
  def render_order_failure
    flash.now[:warn] = translate_with_theme("daily_deal_purchases.braintree_buy_now_form.credit_card_info_error")
    @daily_deal = @daily_deal_purchase.daily_deal
    @publisher = @daily_deal.publisher
    render "daily_deal_purchases/confirm"    
  end
    
  def handle_order_success
    set_up_session @daily_deal_purchase.consumer unless @daily_deal_purchase.consumer == current_consumer
    cookies[:deal_credit] = { :value => "applied", :expires => 1.month.from_now }
    set_analytics_tag
    host = @daily_deal_purchase.daily_deal.publisher.daily_deal_host
    redirect_to thank_you_daily_deal_purchase_url(@daily_deal_purchase, :protocol  => https_unless_development, :host => host)
  end
  
  def handle_repeated_sale
    host = @daily_deal_purchase.daily_deal.publisher.daily_deal_host
    if @daily_deal_purchase.consumer == current_consumer
      redirect_to thank_you_daily_deal_purchase_url(@daily_deal_purchase, :protocol  => "https", :host => host)
    else
      redirect_to public_deal_of_day_url(@daily_deal_purchase.publisher.label, :host => host)
    end
  end
end

