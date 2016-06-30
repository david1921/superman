class AffiliatePlacementsController < ApplicationController
  
  before_filter :admin_privilege_required
  before_filter :user_required
  
  def destroy
    affiliate_placement = AffiliatePlacement.not_deleted.find(params[:id])
    affiliate_placement.soft_delete!
    respond_to do |format|
      format.json { render :json => affiliate_placement }
    end
  end
  
end
