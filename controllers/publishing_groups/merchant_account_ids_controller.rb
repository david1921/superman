class PublishingGroups::MerchantAccountIdsController < ApplicationController
  before_filter :admin_privilege_required

  def edit
    @publishing_group = PublishingGroup.find(params[:publishing_group_id])
  end

  def update
    @publishing_group = PublishingGroup.find(params[:publishing_group_id])

    if @publishing_group.update_attributes(params[:publishing_group])
      flash[:notice] = "Merchant account ID was updated."
      redirect_to edit_publishing_group_url(@publishing_group)
    else
      render :edit
    end
  end
end
