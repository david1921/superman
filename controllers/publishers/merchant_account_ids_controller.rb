class Publishers::MerchantAccountIdsController < ApplicationController
  before_filter :admin_privilege_required
  
  def edit
    @publisher = Publisher.find(params[:publisher_id])
  end

  def update
    @publisher = Publisher.find(params[:publisher_id])

    if @publisher.update_attributes(params[:publisher])
      flash[:notice] = "Merchant account ID was updated."
      redirect_to edit_publisher_url(@publisher)
    else
      render :edit
    end
  end
end
