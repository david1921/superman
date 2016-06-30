class SyndicatedDealsController < ApplicationController 
  
  before_filter :user_required
  before_filter :set_daily_deal
  
  layout "application"
  
  def index
    @publishers = @daily_deal.all_publishers_available_for_syndication
    set_crumb_prefix
    add_crumb "Syndicate Daily Deal", daily_deal_syndicated_deals_path(@daily_deal)    
  end
  
  def create
    @syndicated_deal = @daily_deal.syndicated_deals.build(:publisher_id => params[:publisher_id])
    begin 
      @syndicated_deal.save!
      @daily_deal.update_attributes!(:available_for_syndication => true)
      flash[:notice] = "Created syndicated deal for #{@syndicated_deal.publisher.name}"
    rescue
      flash[:error] = "Could not syndicate deal to #{@syndicated_deal.publisher.name}: #{@syndicated_deal.errors.full_messages.join(', ')}"
    end
    redirect_to daily_deal_syndicated_deals_path(@daily_deal)
  end
  
  def destroy
    @syndicated_deal = DailyDeal.find_by_id(params[:id])
    if @syndicated_deal.mark_as_deleted!
      flash[:notice] = "Syndicated daily deal was deleted."
    else
      flash[:error] = "Unable to delete the daily deal."
    end
    redirect_to daily_deal_syndicated_deals_path(@daily_deal)
  end
  
  def set_daily_deal
    @daily_deal = DailyDeal.find(params[:daily_deal_id])
    Advertiser.manageable_by(current_user).find(@daily_deal.advertiser_id)
  end
  
  def set_crumb_prefix
    add_crumb "Publishers", publishers_path
    add_crumb @daily_deal.publisher.name
    add_crumb "Daily Deals", publisher_daily_deals_path(@daily_deal.publisher)
    add_crumb "Daily Deal", edit_daily_deal_path(@daily_deal)
  end
  
end
