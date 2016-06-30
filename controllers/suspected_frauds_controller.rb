class SuspectedFraudsController < ApplicationController
  
  before_filter :admin_privilege_required
  before_filter :set_publisher
  before_filter :set_suspected_frauds_for_publisher
  
  layout "application"
  
  def index
    
  end
  
  private
  
  def set_publisher
    @publisher ||= Publisher.find(params[:publisher_id])
  end
  
  def set_suspected_frauds_for_publisher
    @suspected_fraud_purchases =
      @publisher.
        daily_deal_purchases.
        suspected_frauds.
        captured(nil).
        paginate(:page => params[:page], :per_page => params[:per_page])
  end
  
end
