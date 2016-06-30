module Publishers::Hosts

  def host
    if use_production_host?
      production_host.present? ? production_host : "#{production_subdomain}.analoganalytics.com"
    else
      AppConfig.default_host
    end
  end

  def daily_deal_host
    if use_production_host?
      production_daily_deal_host.present? ? production_daily_deal_host : host
    else
      AppConfig.default_host
    end
  end

  def asset_host
    #
    # For assets potentially served via HTTPS.
    #
    if use_production_host?
      "#{production_subdomain.present? ? production_subdomain : 'sb1'}.analoganalytics.com"
    else
      AppConfig.default_host
    end
  end

  private

  def use_production_host?
    Rails.env.production? || Rails.env.test? || Rails.env.acceptance?
  end

end
