class DailyDeals::AdminController < ApplicationController
	include Publishers::Themes

	layout with_theme_unless_admin_user("application")

	before_filter :user_required
	before_filter :load_daily_deal
	before_filter :can_manage?

	private

	def load_daily_deal
		@daily_deal = DailyDeal.find_by_id(params[:daily_deal_id])
	end

	def can_manage?
    unless current_user.can_manage? @daily_deal.publisher
      return access_denied
    end
  end
  	
end