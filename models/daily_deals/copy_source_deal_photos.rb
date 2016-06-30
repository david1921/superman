class DailyDeals::CopySourceDealPhotos

  # this is the resque queue
  @queue = :copy_source_deal_photos

  def self.perform(daily_deal_id)
    daily_deal = DailyDeal.find(daily_deal_id)
    source_deal = daily_deal.source

    if source_deal.present?
      daily_deal.photo = source_deal.photo if source_deal.photo?
      daily_deal.secondary_photo = source_deal.secondary_photo if source_deal.secondary_photo?
      daily_deal.save
    end
  end

end
