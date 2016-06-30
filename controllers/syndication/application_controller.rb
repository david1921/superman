class Syndication::ApplicationController < ApplicationController
  
  before_filter :user_required
  before_filter :require_syndication_ui_access

  layout "syndication"
  
  protected

  def require_syndication_ui_access
    if current_user.company.is_a?(PublishingGroup)
      unless current_user.company.self_serve? && current_user.allow_syndication_access?
        access_denied
      end
    else
      unless current_user.self_serve? && current_user.allow_syndication_access? && current_user.in_syndication_network?
        access_denied
      end
    end
  end

  def assign_publisher
    if current_user.company.is_a?(PublishingGroup)
      @publishing_group = current_user.company
      @publishing_group_publishers_in_network = @publishing_group.publishers.in_syndication_network.manageable_by(current_user)
      if params[:publisher_id].present?
        @publisher = @publishing_group_publishers_in_network.find_by_id(params[:publisher_id])
        access_denied unless @publisher.present?
      else
        @publisher = @publishing_group_publishers_in_network.try(:first)
        access_denied_no_publishers unless @publisher.present?
      end
    else
      @publishing_group = nil
      @publisher = current_user.company
    end
  end
  
  private
  
  def access_denied
    store_location
    flash[:notice] = "Unauthorized access"
    redirect_to syndication_login_path
  end
  
  def access_denied_no_publishers
    store_location
    logout_keeping_session!
    flash[:notice] = "#{@publishing_group.name} doesn't have publishers in the syndication network."
    redirect_to syndication_login_path
  end
end
