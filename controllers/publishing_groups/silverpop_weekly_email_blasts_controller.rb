class PublishingGroups::SilverpopWeeklyEmailBlastsController < ApplicationController
  before_filter :admin_privilege_required

  def index
    @publishing_group = PublishingGroup.find(params[:publishing_group_id])
  end

end

