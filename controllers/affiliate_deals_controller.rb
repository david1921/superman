class AffiliateDealsController < ApplicationController
  before_filter :admin_privilege_required
  before_filter :user_required
  before_filter :assign_publisher
  before_filter :assign_daily_deal
  
  def create
    begin
      affiliate_placement = @daily_deal.affiliate_placements.deleted.find_by_affiliate_type_and_affiliate_id("Publisher", @publisher.id)
    
      if affiliate_placement.present?
        affiliate_placement.undelete!
      else
        affiliate_placement = AffiliatePlacement.create! :affiliate => @publisher, :placeable => @daily_deal
      end
      respond_to do |format|
        format.json { render :json => affiliate_placement }
      end
    rescue Exception => e
      respond_to do |format|
        format.json { render :json => { :error => e.message }, :status => 500 }
      end
    end
  end
  
  private
  
  def assign_publisher
    @publisher = Publisher.find_by_label_or_id!(params[:publisher_id])
  end
  
  def assign_daily_deal
    @daily_deal = DailyDeal.find(params[:daily_deal_id])
  end
    
end
