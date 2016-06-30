class DailyDeals::SyndicationRevenueSharingAgreementsController < ApplicationController
  before_filter :require_accountant_privilege
  before_filter :assign_daily_deal
  before_filter :require_daily_deal_available_for_syndication
  before_filter :assign_syndication_revenue_sharing_agreement
  
  def edit
    add_crumb @daily_deal.publisher.name
    add_crumb "Daily Deals", publisher_daily_deals_path(@daily_deal.publisher)
    add_crumb "Edit Daily Deal", edit_daily_deal_path(@daily_deal)
    add_crumb "Override Syndication Revenue Sharing Agreement"
    render 'accounting/syndication_revenue_sharing_agreements/edit'
  end
  
  def create
    @syndication_revenue_sharing_agreement = 
      @daily_deal.build_syndication_revenue_sharing_agreement(params[:accounting_syndication_revenue_sharing_agreement])
    if @syndication_revenue_sharing_agreement.save
      flash[:notice] = "Created syndication revenue sharing agreement."
      redirect_to edit_daily_deal_syndication_revenue_sharing_agreement_path(@daily_deal)
    else
      render 'accounting/syndication_revenue_sharing_agreements/edit'
    end
  end
  
  def update
    @syndication_revenue_sharing_agreement.attributes = params[:accounting_syndication_revenue_sharing_agreement]
    if @syndication_revenue_sharing_agreement.save
      flash[:notice] = "Updated syndication revenue sharing agreement."
      redirect_to edit_daily_deal_syndication_revenue_sharing_agreement_path(@daily_deal)
    else
      render 'accounting/syndication_revenue_sharing_agreements/edit'
    end
  end
  
  private
  
  def require_accountant_privilege
    if logged_in? && current_user.has_admin_privilege? && current_user.has_accountant_privilege?
      return true
    else
      logout_keeping_session!
      return access_denied
    end
  end
  
  def assign_daily_deal
    if params[:daily_deal_id].present?
      @daily_deal = DailyDeal.find(params[:daily_deal_id])
    else
      access_denied
    end
  end
  
  def require_daily_deal_available_for_syndication
    unless @daily_deal.available_for_syndication?
      flash[:error] = "Deal must be available for syndication."
      redirect_to edit_daily_deal_path(@daily_deal)
    end
  end
  
  def assign_syndication_revenue_sharing_agreement
    @syndication_revenue_sharing_agreement = @daily_deal.syndication_revenue_sharing_agreement
    build_syndication_revenue_sharing_agreement unless @syndication_revenue_sharing_agreement.present?
  end
  
  def build_syndication_revenue_sharing_agreement
    parent_agreement = @daily_deal.parent_syndication_revenue_sharing_agreement
    if parent_agreement.present?
      @syndication_revenue_sharing_agreement = Accounting::SyndicationRevenueSharingAgreement.new
      @syndication_revenue_sharing_agreement.attributes = parent_agreement.attributes
      @syndication_revenue_sharing_agreement.effective_date = @daily_deal.start_at.to_date
    else
      flash[:error] = "A current publishing group or publisher syndication revenue sharing agreement must exist and be approved."
      redirect_to edit_daily_deal_path(@daily_deal)
    end
  end
  
end

