module Consumers::Cookies::LastSeenDeal

  def set_last_seen_deal_cookie(daily_deal)
    if daily_deal.publisher.enable_redirect_to_last_seen_deal_on_login?
      cookies["#{daily_deal.publisher.publishing_group.label}_last_seen_deal_id"] = { :value => daily_deal.id, :expires => Time.zone.now + AppConfig.last_seen_deal_cookie_expires_in }
    end
  end

  def last_seen_deal_id
    cookies["#{@publisher.publishing_group.label}_last_seen_deal_id"]
  end

end