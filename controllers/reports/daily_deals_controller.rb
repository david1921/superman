class Reports::DailyDealsController < ApplicationController
  include Reports::Reporting

  before_filter :user_required
  before_filter :set_publisher,  :only => [ :index, :syndicated_daily_deals ]
  before_filter :perform_http_basic_authentication, :only => [:syndicated_daily_deals]
  before_filter do |c|
    User.current = c.send(:current_user)
  end

  def index
    if params[:page].present?
      per_page = params[:per_page] || 20
      @daily_deals =  @publisher.daily_deals.not_deleted.in_order.paginate(:page => params[:page], :per_page => per_page)
    else
      @daily_deals =  @publisher.daily_deals.not_deleted.in_order
    end
    respond_to do |format|
      format.xml { render :template => 'daily_deals/index', :layout => false }
    end
  end

  def syndicated_daily_deals
    if params[:page].present?
      per_page = params[:per_page] || 20
      @daily_deals = @publisher.daily_deals.syndicated.not_deleted.in_order.paginate(:page => params[:page], :per_page => per_page)
    else
      @daily_deals = @publisher.daily_deals.syndicated.not_deleted.in_order
    end
    
    respond_to do |format|
      format.xml { render :template => 'daily_deals/index', :layout => false }
    end
  end

  private

  def set_publisher
    @publisher = Publisher.manageable_by(current_user).find(params[:publisher_id])
  end

end
