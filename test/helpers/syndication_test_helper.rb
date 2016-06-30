module SyndicationTestHelper
  
  private
  
  def syndicate(daily_deal, distributing_publisher)
    daily_deal.syndicated_deals.build(:publisher_id => distributing_publisher.id)
    daily_deal.save!
    daily_deal.syndicated_deals.last
  end

end