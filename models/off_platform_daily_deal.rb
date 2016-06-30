class OffPlatformDailyDeal < DailyDeal

  has_one :off_platform_purchase_summary, :foreign_key => :daily_deal_id

  accepts_nested_attributes_for :off_platform_purchase_summary

  def off_platform
    true
  end

  def item_code
    "OP-#{id}"
  end

end

