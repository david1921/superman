class Accounting::ApplicationController < ApplicationController
  
  before_filter :accountant_privilege_required

  layout "application"
  
  protected
  
  def accountant_privilege_required
    return access_denied unless authorized?
  end
  
  def authorized?(action=nil, resource=nil, *args)
    if logged_in? && current_user.has_admin_privilege? && current_user.has_accountant_privilege?
      return true
    else
      logout_keeping_session!
      return false
    end
  end
  
  def assign_publishing_group_or_publisher
    if params[:publishing_group_id].present?
      @publishing_group = PublishingGroup.find_by_id(params[:publishing_group_id])
    elsif params[:publisher_id].present?
      @publisher = Publisher.find_by_id(params[:publisher_id])
    else
      access_denied
    end
  end

end