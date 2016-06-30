class Advertisers::AdminController < ApplicationController
	include Publishers::Themes

	layout with_theme_unless_admin_user("application")

	before_filter :user_required
	before_filter :load_advertiser
	before_filter :can_manage?

	private

	def load_advertiser
		@advertiser = Advertiser.find_by_id(params[:advertiser_id])
	end

	def can_manage?
    unless current_user.can_manage? @advertiser
      return access_denied
    end
  end
  	
end