class Accounting::SyndicationRevenueSharingAgreementsController < Accounting::ApplicationController
  
  before_filter :assign_publishing_group_or_publisher
  before_filter :assign_agreement, :only => [:edit, :update, :destroy]
  
  def index
    add_crumb "Revenue Sharing Agreements", revenue_sharing_agreements_path
    add_crumb @publishing_group.try(:name) || @publisher.try(:name)
    add_crumb "Syndication Revenue Sharing Agreements"
  end
  
  def edit
    add_crumb "Revenue Sharing Agreements", revenue_sharing_agreements_path
    add_crumb @publishing_group.try(:name) || @publisher.try(:name)
    add_crumb "Syndication Revenue Sharing Agreements", syndication_revenue_sharing_agreements_path
    add_crumb "Edit"
  end
  
  def new
    add_crumb "Revenue Sharing Agreements", revenue_sharing_agreements_path
    add_crumb @publishing_group.try(:name) || @publisher.try(:name)
    add_crumb "Syndication Revenue Sharing Agreements", syndication_revenue_sharing_agreements_path
    add_crumb "New"
    @syndication_revenue_sharing_agreement = build_agreement
    render :edit
  end
  
  def create
    @syndication_revenue_sharing_agreement = build_agreement(params[:accounting_syndication_revenue_sharing_agreement])
    if @syndication_revenue_sharing_agreement.save
      flash[:notice] = "Created syndication revenue sharing agreement."
      redirect_to_edit
    else
      render :edit
    end
  end
  
  def update
    @syndication_revenue_sharing_agreement.attributes = params[:accounting_syndication_revenue_sharing_agreement]
    if approved_unacceptable?
        flash[:error] = "Insufficient privileges to update approved."
        render :edit
    else
      if @syndication_revenue_sharing_agreement.save
        flash[:notice] = "Updated syndication revenue sharing agreement."
        redirect_to_edit
      else
        render :edit
      end
    end
  end
  
  def destroy
    if @syndication_revenue_sharing_agreement.destroy
      flash[:notice] = "Deleted syndication revenue sharing agreement."
      redirect_to syndication_revenue_sharing_agreements_path
    else
      flash[:error] = "Unable to delete the revenue sharing agreement."
    end
  end
  
  private
  
  def redirect_to_edit
    if @publishing_group.present?
      redirect_to edit_publishing_group_syndication_revenue_sharing_agreement_path(@publishing_group, @syndication_revenue_sharing_agreement)
    elsif @publisher.present?
      redirect_to edit_publisher_syndication_revenue_sharing_agreement_path(@publisher, @syndication_revenue_sharing_agreement)
    else
      raise "Publishing Group or Publisher required."
    end
  end
  
  def assign_agreement
    if @publishing_group.present?
      @syndication_revenue_sharing_agreement = @publishing_group.syndication_revenue_sharing_agreements.find_by_id(params[:id])
    elsif @publisher.present?
      @syndication_revenue_sharing_agreement = @publisher.syndication_revenue_sharing_agreements.find_by_id(params[:id])
    else
      raise "Publishing Group or Publisher required."
    end
  end
  
  def build_agreement(attributes = nil)
    if @publishing_group.present?
      @publishing_group.syndication_revenue_sharing_agreements.build(attributes)
    elsif @publisher.present?
      @publisher.syndication_revenue_sharing_agreements.build(attributes)
    else
      raise "Publishing Group or Publisher required."
    end
  end
  
  def syndication_revenue_sharing_agreements_path
    if @publishing_group.present?
      publishing_group_syndication_revenue_sharing_agreements_path(@publishing_group)
    elsif @publisher.present?
      publisher_syndication_revenue_sharing_agreements_path(@publisher)
    else
      raise "Publishing Group or Publisher required."
    end
  end
  
  def approved_unacceptable?
    if @syndication_revenue_sharing_agreement.approved_changed? && !@current_user.has_fee_sharing_agreement_approver_privilege?
       return true
    else
      return false
    end
  end
end