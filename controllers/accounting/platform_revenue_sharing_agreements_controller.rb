class Accounting::PlatformRevenueSharingAgreementsController < Accounting::ApplicationController
  
  before_filter :assign_publishing_group_or_publisher
  before_filter :assign_agreement, :only => [:edit, :update, :destroy]
  
  def index
    add_crumb "Revenue Sharing Agreements", revenue_sharing_agreements_path
    add_crumb @publishing_group.try(:name) || @publisher.try(:name)
    add_crumb "Platform Revenue Sharing Agreements"
  end
  
  def edit
    add_crumb "Revenue Sharing Agreements", revenue_sharing_agreements_path
    add_crumb @publishing_group.try(:name) || @publisher.try(:name)
    add_crumb "Platform Revenue Sharing Agreements", platform_revenue_sharing_agreements_path
    add_crumb "Edit"
  end
  
  def new
    add_crumb "Revenue Sharing Agreements", revenue_sharing_agreements_path
    add_crumb @publishing_group.try(:name) || @publisher.try(:name)
    add_crumb "Platform Revenue Sharing Agreements", platform_revenue_sharing_agreements_path
    add_crumb "New"
    @platform_revenue_sharing_agreement = build_agreement
    render :edit
  end
  
  def create
    @platform_revenue_sharing_agreement = build_agreement(params[:accounting_platform_revenue_sharing_agreement])
    if @platform_revenue_sharing_agreement.save
      flash[:notice] = "Created platform revenue sharing agreement."
      redirect_to_edit
    else
      render :edit
    end
  end
  
  def update
    if @platform_revenue_sharing_agreement.update_attributes(params[:accounting_platform_revenue_sharing_agreement])
      flash[:notice] = "Updated platform revenue sharing agreement."
      redirect_to_edit
    else
      render :edit
    end
  end
  
  def destroy
    if @platform_revenue_sharing_agreement.destroy
      flash[:notice] = "Deleted platform revenue sharing agreement."
      redirect_to platform_revenue_sharing_agreements_path
    else
      flash[:error] = "Unable to delete the revenue sharing agreement."
    end
  end
  
  private
  
  def redirect_to_edit
    if @publishing_group.present?
      redirect_to edit_publishing_group_platform_revenue_sharing_agreement_path(@publishing_group, @platform_revenue_sharing_agreement)
    elsif @publisher.present?
      redirect_to edit_publisher_platform_revenue_sharing_agreement_path(@publisher, @platform_revenue_sharing_agreement)
    else
      raise "Publishing Group or Publisher required."
    end
  end
  
  def assign_agreement
    if @publishing_group.present?
      @platform_revenue_sharing_agreement = @publishing_group.platform_revenue_sharing_agreements.find_by_id(params[:id])
    elsif @publisher.present?
      @platform_revenue_sharing_agreement = @publisher.platform_revenue_sharing_agreements.find_by_id(params[:id])
    else
      raise "Publishing Group or Publisher required."
    end
  end
  
  def build_agreement(attributes = nil)
    if @publishing_group.present?
      @publishing_group.platform_revenue_sharing_agreements.build(attributes)
    elsif @publisher.present?
      @publisher.platform_revenue_sharing_agreements.build(attributes)
    else
      raise "Publishing Group or Publisher required."
    end
  end
  
  def platform_revenue_sharing_agreements_path
    if @publishing_group.present?
      publishing_group_platform_revenue_sharing_agreements_path(@publishing_group)
    elsif @publisher.present?
      publisher_platform_revenue_sharing_agreements_path(@publisher)
    else
      raise "Publishing Group or Publisher required."
    end
  end
end