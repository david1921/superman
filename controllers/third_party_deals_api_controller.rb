class ThirdPartyDealsApiController < ApplicationController
  before_filter :user_required
  before_filter :admin_privilege_required
  
  def activity_log
    @recent_activity_logs = ApiActivityLog.recent
  end
  
end
