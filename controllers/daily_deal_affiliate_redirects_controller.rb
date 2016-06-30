class DailyDealAffiliateRedirectsController < ApplicationController
  include Publishers::Themes

  skip_before_filter :ssl_required_for_hosts_that_require_https, :only => [:show]
  before_filter :set_affiliate_redirect, :only => [:show]
  before_filter :set_daily_deal, :except => [:show]
  before_filter :logged_in_for_publisher, :except => [:show]

  def show
    @publisher = @affiliate_redirect.daily_deal.publisher
    render with_theme(:layout => "daily_deals")
  end

  def create
    consumer_login_required(@daily_deal.publisher)
    affiliate_redirect = @daily_deal.daily_deal_affiliate_redirects.create(:consumer => current_consumer)
    redirect_to :action => :show, :id => affiliate_redirect, :protocol => "http://"
  end

  private

  def set_daily_deal
    @daily_deal = DailyDeal.find(params[:daily_deal_id])
  end

  def logged_in_for_publisher
    consumer_login_required(@daily_deal.publisher)
  end

  def set_affiliate_redirect
    @affiliate_redirect = DailyDealAffiliateRedirect.find( params[:id] )
  end

  def ensure_current_consumer_owns_affiliate_redirect
    unless @affiliate_redirect.consumer == current_consumer
      consumer_access_denied(@affiliate_redirect.daily_deal.publisher)
    end
  end

end
