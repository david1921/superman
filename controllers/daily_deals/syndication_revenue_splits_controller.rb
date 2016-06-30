class DailyDeals::SyndicationRevenueSplitsController < ApplicationController
  
  before_filter :user_required
  before_filter :assign_daily_deal
  before_filter :assign_syndication_revenue_split, :only => [:edit, :update]
  before_filter :require_daily_deal_available_for_syndication
  before_filter :require_source_publisher_user
  before_filter :require_syndication_revenue_sharing_agreement
  
  def new
    @syndication_revenue_split = build_syndication_revenue_split
    @syndication_revenue_split.aa_gross_percentage
    @syndication_revenue_split.aa_net_percentage_of_remaining
    add_crumb @daily_deal.publisher.name
    add_crumb "Daily Deals", publisher_daily_deals_path(@daily_deal.publisher)
    add_crumb "Edit Daily Deal", edit_daily_deal_path(@daily_deal)
    add_crumb "New Syndication Revenue Split"
    render :edit
  end
  
  def create
    @syndication_revenue_split = 
      @daily_deal.build_syndication_revenue_split(params[:daily_deals_syndication_revenue_split])
    if @syndication_revenue_split.save
      flash[:notice] = "Created syndication revenue split."
      redirect_to edit_daily_deal_syndication_revenue_split_path(@daily_deal)
    else
      render :edit
    end
  end
  
  def edit
    add_crumb @daily_deal.publisher.name
    add_crumb "Daily Deals", publisher_daily_deals_path(@daily_deal.publisher)
    add_crumb "Edit Daily Deal", edit_daily_deal_path(@daily_deal)
    add_crumb "Edit Syndication Revenue Split"
    render :edit
  end
  
  def update
    if @syndication_revenue_split.update_attributes(params[:daily_deals_syndication_revenue_split])
      flash[:notice] = "Updated syndication revenue split."
      redirect_to edit_daily_deal_syndication_revenue_split_path(@daily_deal)
    else
      render :edit
    end
  end
  
  private
  
  def assign_daily_deal
    if params[:daily_deal_id].present?
      @daily_deal = DailyDeal.find(params[:daily_deal_id])
    else
      access_denied
    end
  end
  
  def assign_syndication_revenue_split
    @syndication_revenue_split = @daily_deal.syndication_revenue_split
  end
  
  def require_daily_deal_available_for_syndication
    unless @daily_deal.available_for_syndication?
      flash[:error] = "Deal must be available for syndication."
      redirect_to edit_daily_deal_path(@daily_deal)
    end
  end
  
  def require_source_publisher_user
    unless @daily_deal.sourced_by_publisher?(current_user.company) || accountant? || admin?
      access_denied("Only the source publisher can edit the syndication revenue split.")
    end
  end
  
  def require_syndication_revenue_sharing_agreement
    @syndication_revenue_sharing_agreement = @daily_deal.syndication_revenue_sharing_agreement
    unless @syndication_revenue_sharing_agreement.present?
      flash[:error] = "A current syndication deal revenue sharing agreement must exist and be approved."
      redirect_to edit_daily_deal_path(@daily_deal)
    end
  end
  
  def build_syndication_revenue_split
    syndication_revenue_split = DailyDeals::SyndicationRevenueSplit.new
    syndication_revenue_split.aa_gross_percentage = @syndication_revenue_sharing_agreement.syndication_fee_gross_percentage
    syndication_revenue_split.aa_net_percentage_of_remaining = @syndication_revenue_sharing_agreement.syndication_fee_net_percentage
    syndication_revenue_split
  end
  
end