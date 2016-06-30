module TranslationsHelper
  def locale_paths_json(model)
    locales = {}

    I18n.available_locales.each do |locale|
      path = case model
             when DailyDeal
               edit_daily_deal_translations_for_locale_path(model, locale)
             when Advertiser
               edit_advertiser_translations_for_locale_path(:advertiser_id => model, :editing_locale => locale)
             end

      locales[locale.to_s] = path
    end

    locales.to_json
  end
end
