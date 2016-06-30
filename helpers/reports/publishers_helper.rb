module Reports::PublishersHelper
  
  def publisher_purchased_daily_deals_data_source_path(publisher, market = nil, url_options = {})
    if market.present?
      market_purchased_daily_deals_reports_publisher_path(publisher.to_param, market.to_param, url_options)
    else
      purchased_daily_deals_reports_publisher_path(publisher.to_param, url_options)
    end
  end
  
  def publisher_purchased_daily_deals_data_source_url(publisher, market = nil, url_options = {})
    if market.present?
      market_purchased_daily_deals_reports_publisher_url(publisher.to_param, market.to_param, url_options)
    else
      purchased_daily_deals_reports_publisher_url(publisher.to_param, url_options)
    end
  end
  
  def advertiser_purchased_daily_deals_data_source_path(advertiser, market = nil, url_options = {})
    if market.present?
      market_purchased_daily_deals_reports_advertiser_path(advertiser.to_param, market.to_param, url_options)
    else
      purchased_daily_deals_reports_advertiser_path(advertiser.to_param, url_options)
    end
  end
  
  def advertiser_purchased_daily_deals_data_source_url(advertiser, market = nil, url_options = {})
    if market.present?
      market_purchased_daily_deals_reports_advertiser_url(advertiser.to_param, market.to_param, url_options)
    else
      purchased_daily_deals_reports_advertiser_url(advertiser.to_param, url_options)
    end
  end
  
  def publisher_refunded_daily_deals_data_source_path(publisher, market = nil, url_options = {})
    if market.present?
      market_refunded_daily_deals_reports_publisher_path(publisher.to_param, market.to_param, url_options)
    else
      refunded_daily_deals_reports_publisher_path(publisher.to_param, url_options)
    end
  end
  
  def publisher_refunded_daily_deals_data_source_url(publisher, market = nil, url_options = {})
    if market.present?
      market_refunded_daily_deals_reports_publisher_url(publisher.to_param, market.to_param, url_options)
    else
      refunded_daily_deals_reports_publisher_url(publisher.to_param, url_options)
    end
  end
  
  def advertiser_refunded_daily_deals_data_source_path(advertiser, market = nil, url_options = {})
    if market.present?
      market_refunded_daily_deals_reports_advertiser_path(advertiser.to_param, market.to_param, url_options)
    else
      refunded_daily_deals_reports_advertiser_path(advertiser.to_param, url_options)
    end
  end
  
  def advertiser_refunded_daily_deals_data_source_url(advertiser, market = nil, url_options = {})
    if market.present?
      market_refunded_daily_deals_reports_advertiser_url(advertiser.to_param, market.to_param, url_options)
    else
      refunded_daily_deals_reports_advertiser_url(advertiser.to_param, url_options)
    end
  end
  
end