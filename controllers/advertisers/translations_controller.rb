class Advertisers::TranslationsController < ApplicationController
  before_filter :user_required

  def edit
    @advertiser = Advertiser.find(params[:advertiser_id])
  end

  def update
    editing_locale = params[:editing_locale] || I18n.default_locale
    @advertiser = Advertiser.find(params[:advertiser_id])

    Advertiser.with_locale(editing_locale) do
      if @advertiser.update_attributes(params[:advertiser])
        flash[:notice] = "Advertiser successfully updated for the '#{editing_locale}' locale"
        redirect_to edit_advertiser_translations_for_locale_url(@advertiser, editing_locale)
      else
        render :edit
      end
    end
  end
end
