class Publishers::SyndicationPreferencesController < ApplicationController
  before_filter :admin_privilege_required

  def edit
    @publisher = Publisher.find_by_id!(params[:publisher_id])
  end

  def update
    @publisher = Publisher.find_by_id!(params[:publisher_id])

    if @publisher.update_attributes(params[:publisher])
      flash[:notice] = 'Syndication Preferences were saved.'
      redirect_to edit_publisher_url(@publisher)
    else
      flash[:error] = 'The preferences could not be saved.'
      render :edit
    end
  end
end
