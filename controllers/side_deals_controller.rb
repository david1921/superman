class SideDealsController < ApplicationController
  
  ssl_allowed :active, :with_format => [ Mime::JSON ]
  
  def index
    
    daily_deal = DailyDeal.find_by_id(params[:daily_deal_id])
    
    if (daily_deal.present?)
      @side_deals = daily_deal.side_deals { |deal| deal.hide_at }
      respond_to do |format|
        format.json do
          expires_in AppConfig.expires_in_timeout.minutes, :public => true
          # NOTE: the following is a fix for stupid IE see http://www.rezashojaei.com/2011/06/ie-tries-to-download-json-response.html
          response.content_type = "text/plain"
          render :json => @side_deals
        end
      end
    else
      render :nothing => true, :status => :not_found
    end
    
  end
  
end