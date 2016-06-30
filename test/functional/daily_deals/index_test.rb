require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::IndexTest < ActionController::TestCase
  tests DailyDealsController
  include DailyDealHelper

  context "daily deals index" do

    should "display the side start- and end-at dates" do
      Timecop.freeze(Time.zone.local(2012, 1, 3, 8, 0, 0)) do
        publisher = Factory(:publisher)
        daily_deal = Factory(:daily_deal,
                             :publisher => publisher,
                             :start_at => 2.weeks.ago,
                             :hide_at => 2.weeks.from_now,
                             :side_start_at => 1.week.ago,
                             :side_end_at => 1.week.from_now)
        login_as Factory(:admin)
        get :index, :publisher_id => publisher.to_param
        assert_select("th", :text => "Side Starts At / Side Ends At")
        assert_select("td", :text => "12/20/11 08:00AM PST / 01/17/12 08:00AM PST")
        assert_select("td", :text => "12/27/11 08:00AM PST / 01/10/12 08:00AM PST")
      end
    end

  end
end
