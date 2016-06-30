module SuggestedDailyDealsHelper
  def suggested_daily_deals_login_path
    return_to = public_deal_of_day_path(@publisher.label, :suggested_daily_deals_lightbox => true)
    new_publisher_daily_deal_session_path(@publisher, :return_to => return_to)
  end
end
