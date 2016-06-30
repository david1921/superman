class Syndication::UsersController < Syndication::ApplicationController
  
  before_filter :user_required
  before_filter :assign_user
  before_filter :assign_publisher
  before_filter :assign_publisher_attributes
  
  ssl_allowed :edit, :update
  
  def edit
    render :edit
  end
  
  def update
    success = false

    if params[:user].present?
      @user.require_password = true
      if @user.save
        flash[:notice] = "Updated login information."
        success = true
      else
        flash[:error] = "Could not update login information."
      end
    elsif params[:publisher].present?
      if @publisher.save
        flash[:notice] = "Updated contact information."
        success = true
      else
        flash[:error] = "Could not update contact information."
      end
    end
    success ? redirect_to(edit_syndication_user_path(@user.id, :publisher_id => @publisher.id)) : render(:edit)
  end
  
  private 
  
  def assign_user
    if params[:id].present?
      @user = User.find(params[:id])
    else
      @user = current_user
    end
    @user.attributes = params[:user] if params[:user].present?
  end
  
  def assign_publisher_attributes
    @publisher.attributes = params[:publisher] if params[:publisher].present?
  end
  
end
