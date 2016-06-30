require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Reports::Publishers::DailyDealsTest

module Reports
  module Publishers
    class DailyDealsTest < ActionController::TestCase
      tests Reports::PublishersController

      test "daily deals with default dates as publishing group user by get" do
        group = Factory(:publishing_group)
        user = create_user_with_company :company => group
        publisher = Factory(:publisher, :publishing_group_id => group.id)

        Timecop.freeze(Time.zone.local(2008, 10, 4, 12, 34, 56)) do
          login_as user

          get :daily_deals

          assert_response :success
          assert_template :daily_deals
          assert_same_elements [publisher], assigns(:publishers), "@publishers assignment"
          assert_equal Date.new(2008, 9, 1) .. Date.new(2008, 9, 30), assigns(:dates), "@dates assignment"
        end
      end

      test "daily deals with default dates as publishing group user by xhr" do
        group = Factory(:publishing_group)
        user = create_user_with_company :company => group
        publisher = Factory(:publisher, :publishing_group_id => group.id)

        twitter_click_count = Factory(:click_count_daily_deal, :publisher => publisher)
        facebook_click_count = Factory(:click_count_daily_deal, :mode => "facebook", :publisher => publisher)

        Factory(:click_count_offer, :publisher => publisher)
        Factory(:click_count_offer, :mode => "facebook", :publisher => publisher)

        Timecop.freeze(Time.zone.local(2008, 10, 4, 12, 34, 56)) do
          login_as user
          xhr :get, :daily_deals, :format => "xml"

          assert_response :success
          assert_same_elements [publisher], assigns(:publishers), "@publishers assignment"
          assert_equal Date.new(2008, 9, 1) .. Date.new(2008, 9, 30), assigns(:dates), "@dates assignment"

          body = Hash.from_xml(@response.body)

          assert_equal facebook_click_count.count.to_s, body['publishers']['publisher']['facebooks_count']
          assert_equal twitter_click_count.count.to_s, body['publishers']['publisher']['twitters_count']
        end
      end

      test "daily deals with default dates as publishing group user by csv" do
        group = Factory(:publishing_group)
        user = create_user_with_company :company => group
        publisher = Factory(:publisher, :publishing_group_id => group.id)

        twitter_count = Factory(:click_count_daily_deal, :publisher => publisher).count
        facebook_count = Factory(:click_count_daily_deal, :mode => "facebook", :publisher => publisher).count

        Factory(:click_count_offer, :publisher => publisher)
        Factory(:click_count_offer, :mode => "facebook", :publisher => publisher)

        Timecop.freeze(Time.zone.local(2008, 10, 4, 12, 34, 56)) do
          login_as user

          get :daily_deals, :format => "csv"

          assert_response :success
          assert_same_elements [publisher], assigns(:publishers), "@publishers assignment"
          assert_equal Date.new(2008, 9, 1) .. Date.new(2008, 9, 30), assigns(:dates), "@dates assignment"

          csv = FasterCSV.new(@response.binary_content).to_a
          assert_equal 2, csv.length, "CSV should contain header and one data row"
          row = csv.shift
          row = csv.shift
          assert_equal [publisher.name, facebook_count.to_s, twitter_count.to_s], row
        end
      end

    end
  end
end

