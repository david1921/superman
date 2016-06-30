class DailyDeals::PlatformRevenueSharingAgreementController < ApplicationController
  before_filter :accountant_privilege_required
  before_filter :assign_daily_deal

  def new
    @platform_revenue_sharing_agreement = Accounting::PlatformRevenueSharingAgreement.new
    render 'accounting/platform_revenue_sharing_agreements/edit'
  end

  def create
    @platform_revenue_sharing_agreement = Accounting::PlatformRevenueSharingAgreement.new({:agreement => @daily_deal}.merge(params[:accounting_platform_revenue_sharing_agreement]))
    if @platform_revenue_sharing_agreement.save
      redirect_to edit_daily_deal_platform_revenue_sharing_agreement_path(@daily_deal)
    else
      render 'accounting/platform_revenue_sharing_agreements/edit'
    end
  end

  def update
    @platform_revenue_sharing_agreement = @daily_deal.platform_revenue_sharing_agreement
    if @platform_revenue_sharing_agreement.update_attributes(params[:accounting_platform_revenue_sharing_agreement])
      redirect_to edit_daily_deal_platform_revenue_sharing_agreement_path(@daily_deal)
    else
      render 'accounting/platform_revenue_sharing_agreements/edit'
    end
  end

  def edit
    @platform_revenue_sharing_agreement = @daily_deal.platform_revenue_sharing_agreement
    if @platform_revenue_sharing_agreement.present?
      render 'accounting/platform_revenue_sharing_agreements/edit'
    else
      redirect_to new_daily_deal_platform_revenue_sharing_agreement_path(@daily_deal)
    end
  end

  private

  def accountant_privilege_required
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
end
