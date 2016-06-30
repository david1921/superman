module DailyDealsTestHelper
  def stubbed_daily_deal
    publisher = Factory.stub(:publisher, :label => "laweekly", :publishing_group => Factory.stub(:publishing_group_with_theme))
    advertiser = Factory.stub(:advertiser, :publisher => publisher, :stores => [])
    daily_deal = Factory.stub(:daily_deal, :publisher => publisher, :advertiser => advertiser)

    daily_deal.stubs(:photo).returns(
      mock("photo") { 
        stubs("url").returns("http://photos.daily_deals.analoganalytics.com/production/12187/widget.png?1284066113")
        stubs("file?").returns(true)
      }
    )
    stub_counts daily_deal

    Publisher.stubs(:find_by_label!).returns(daily_deal.publisher)
    publisher.stubs(:deals_without_market).returns(mock("daily_deals", :current_or_previous => daily_deal))
    daily_deal
  end
  
  def stub_counts(daily_deal)
    daily_deal.stubs(:facebook_clicks).returns(0)
    daily_deal.stubs(:number_sold).returns(0)
    daily_deal.stubs(:twitter_clicks).returns(0)
  end
end
