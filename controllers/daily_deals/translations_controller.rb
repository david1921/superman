class DailyDeals::TranslationsController < ApplicationController
  before_filter :user_required

  def edit
    @daily_deal = ::DailyDeal.find(params[:daily_deal_id])
  end

  def update
    editing_locale = params[:editing_locale] || I18n.default_locale
    @daily_deal = ::DailyDeal.find(params[:daily_deal_id])

    ::DailyDeal.with_locale(editing_locale) do
      if @daily_deal.update_attributes(params[:daily_deal])
        flash[:notice] = "Daily deal successfully updated for the '#{editing_locale}' locale"
        redirect_to edit_daily_deal_translations_for_locale_url(@daily_deal, editing_locale)
      else
        render :edit
      end
    end
  end
end
