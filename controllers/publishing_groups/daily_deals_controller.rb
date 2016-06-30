class PublishingGroups::DailyDealsController < ApplicationController
  before_filter :load_publishing_group_by_id, :only => [:active]
  before_filter :login_via_http_basic_auth, :only => [:active]

  def active
    if can_access?
      @daily_deals = @publishing_group.daily_deals.active.in_order
      respond_to do |format|
        format.xml
      end
    else
      access_denied
    end
  end
  
  private 
  
  def can_access?
    return true unless @publishing_group.require_login_for_active_daily_deal_feed?
    return false unless current_user
    (current_user.has_admin_privilege? || current_user.company == @publishing_group)
  end
  
  def login_via_http_basic_auth
    return unless @publishing_group.require_login_for_active_daily_deal_feed?
    authenticate_or_request_with_http_basic do |login, password| 
      auth_result = User.authenticate(login, password)
      if auth_result.is_a?(User)
        set_up_session(auth_result, false) 
        true
      else
        false
      end
    end  
  end
  
  def load_publishing_group_by_id
    @publishing_group = PublishingGroup.find(params[:publishing_group_id])
  end
  
end
