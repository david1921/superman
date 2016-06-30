class CloseRequestsController < ApplicationController

  protect_from_forgery :except => :create

  if ssl_rails_environment?
    ssl_required :create
  else
    ssl_allowed  :create
  end

  before_filter :perform_http_basic_authentication
  before_filter :assign_publisher_by_label
  before_filter :set_daily_deal
  before_filter :authorize_user_for_daily_deal

  def create
    @daily_deal.sold_out_via_third_party!
    render :nothing => true, :status => :ok
  end

  private

  def assign_publisher_by_label
    @publisher = Publisher.find_by_label!(params[:label])
  end

  def set_daily_deal
    @daily_deal = @publisher.daily_deals.find_by_listing(params[:listing])
  end

  def authorize_user_for_daily_deal
    begin
      Publisher.manageable_by(@user).find(@daily_deal.publisher_id)
    rescue
      render :nothing => true, :status => 401
    end
  end

end