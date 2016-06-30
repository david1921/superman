require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Reports::Advertisers::AdvertisersControllerTest

module Reports
  module Advertisers
    class AdvertisersControllerTest < ActionController::TestCase
      tests Reports::AdvertisersController

      def setup
        @publisher = publishers(:sdh_austin)
        @advertisers = @publisher.advertisers
        offers(:changos_buy_two_tacos).place_with(@publisher)
        @advertisers_with_placed_offers = @publisher.placed_offers.map(&:advertiser).uniq

        assert 0 < @advertisers.size, "Should have some advertiser fixtures"
        assert 0 < @advertisers_with_placed_offers.size, "Should have some advertiser with placed offers"
        assert_not_equal @advertisers.size, @advertisers_with_placed_offers.size, "Not all advertisers should have placed offers"
        TxtOffer.clear_cache
        GiftCertificateMailer.expects(:deliver_gift_certificate).at_least(0).returns(nil)
        super
      end

      test "should redirect if not on reports.analoganalytics.com in production mode" do
        stub_host_as_admin_server
        get :index
        assert_response :redirect
        assert_match /^https?:\/\/reports\.analoganalytics\.com/, @response.headers['Location']
      end

      test "should not redirect if on reports.analoganalytics.com in production mode" do
        stub_host_as_reports_server
        login_as Factory(:admin)
        get :index, :publisher_id => Factory(:publisher)
        assert_response :success
      end

      test "get index as admin user" do
        time = Time.zone.parse("Oct 4, 2008 12:34:56")
        dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

        get_index_with_default_or_given_dates(users(:aaron), time, dates) do |action, mode, dates|
          action.call
          assert_response :success, "HTTP response code for #{mode}"
          assert_equal @publisher, assigns(:publisher), "@publisher assignment for #{mode}"
          assert_equal dates, assigns(:dates), "@dates assignment for #{mode}"
        end
      end

      test "xhr index as admin user" do
        time = Time.zone.parse("Oct 4, 2008 12:34:56")
        dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

        xhr_index_with_default_or_given_dates(users(:aaron), time, dates) do |action, mode, dates|
          action.call
          assert_response :success, "HTTP response code for #{mode}"
          assert_equal @publisher, assigns(:publisher), "@publisher assignment for #{mode}"
          assert_equal @advertisers_with_placed_offers, assigns(:advertisers), "@advertisers assignment for #{mode}"
          assert_equal dates, assigns(:dates), "@dates assignment for #{mode}"
        end
      end

      test "get index as owning publishing group user" do
        group = @publisher.publishing_group
        assert_not_nil group, "Publisher fixture should belong to a publishing group"
        user = User.all.detect { |user| group == user.company }
        assert_not_nil user, "Publishing group should have a user"

        2.times { |i| @publisher.advertisers.create! :name => "Advertiser #{i}" }
        advertiser_ids = group.advertisers(true).map(&:id).sort
        assert 3 <= advertiser_ids.size, "Should have at least 3 advertisers in group"
        assert_not_nil Advertiser.all.detect { |a| !advertiser_ids.include?(a.id) }, "Should have some advertisers not in group"

        time = Time.zone.parse("Oct 4, 2008 12:34:56")
        dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

        get_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
          action.call
          assert_response :success, "HTTP response code for #{mode}"
          assert_equal @publisher, assigns(:publisher), "@publisher assignment for #{mode}"
          assert_equal dates, assigns(:dates), "@dates assignment for #{mode}"
        end
      end

      test "xhr index as owning publishing group user" do
        group = @publisher.publishing_group
        assert_not_nil group, "Publisher fixture should belong to a publishing group"
        user = User.all.detect { |user| group == user.company }
        assert_not_nil user, "Publishing group should have a user"

        2.times { |i| @publisher.advertisers.create! :name => "Advertiser #{i}" }
        advertiser_ids = group.advertisers(true).map(&:id).sort
        assert 3 <= advertiser_ids.size, "Should have at least 3 advertisers in group"
        assert_not_nil Advertiser.all.detect { |a| !advertiser_ids.include?(a.id) }, "Should have some advertisers not in group"

        time = Time.zone.parse("Oct 4, 2008 12:34:56")
        dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

        xhr_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
          action.call
          assert_response :success, "HTTP response code for #{mode}"
          assert_equal @publisher, assigns(:publisher), "@publisher assignment for #{mode}"
          assert_equal @advertisers_with_placed_offers, assigns(:advertisers), "@advertisers assignment for #{mode}"
          assert_equal dates, assigns(:dates), "@dates assignment for #{mode}"
        end
      end

      test "get index as other publishing group user" do
        group = @publisher.publishing_group
        assert_not_nil group, "Publisher fixture should belong to a publishing group"
        user = User.all.detect { |user| user.company.is_a?(PublishingGroup) && group != user.company }
        assert_not_nil user, "Should have a user for another publishing group"

        2.times { |i| @publisher.advertisers.create! :name => "Advertiser #{i}" }
        advertiser_ids = group.advertisers(true).map(&:id).sort
        assert 3 <= advertiser_ids.size, "Should have at least 3 advertisers in group"
        assert_not_nil Advertiser.all.detect { |a| !advertiser_ids.include?(a.id) }, "Should have some advertisers not in group"

        time = Time.zone.parse("Oct 4, 2008 12:34:56")
        dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

        get_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
          assert_raises ActiveRecord::RecordNotFound, "Should raise RecordNotFound for #{mode}" do
            action.call
          end
        end
      end

      test "xhr index as other publishing group user" do
        group = @publisher.publishing_group
        assert_not_nil group, "Publisher fixture should belong to a publishing group"
        user = User.all.detect { |user| user.company.is_a?(PublishingGroup) && group != user.company }
        assert_not_nil user, "Should have a user for another publishing group"

        2.times { |i| @publisher.advertisers.create! :name => "Advertiser #{i}" }
        advertiser_ids = group.advertisers(true).map(&:id).sort
        assert 3 <= advertiser_ids.size, "Should have at least 3 advertisers in group"
        assert_not_nil Advertiser.all.detect { |a| !advertiser_ids.include?(a.id) }, "Should have some advertisers not in group"

        time = Time.zone.parse("Oct 4, 2008 12:34:56")
        dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

        get_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
          assert_raises ActiveRecord::RecordNotFound, "Should raise RecordNotFound for #{mode}" do
            action.call
          end
        end
      end

      test "get index as owning publisher user" do
        user = @publisher.users.first
        assert_not_nil user, "Publisher should have a user fixture"

        time = Time.zone.parse("Oct 4, 2008 12:34:56")
        dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

        get_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
          action.call
          assert_response :success, "HTTP response code for #{mode}"
          assert_equal @publisher, assigns(:publisher), "@publisher assignment for #{mode}"
          assert_equal dates, assigns(:dates), "@dates assignment for #{mode}"
        end
      end

      test "xhr index as owning publisher user" do
        user = @publisher.users.first
        assert_not_nil user, "Publisher should have a user fixture"

        time = Time.zone.parse("Oct 4, 2008 12:34:56")
        dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

        xhr_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
          action.call
          assert_response :success, "HTTP response code for #{mode}"
          assert_equal @publisher, assigns(:publisher), "@publisher assignment for #{mode}"
          assert_equal @advertisers_with_placed_offers, assigns(:advertisers), "@advertisers assignment for #{mode}"
          assert_equal dates, assigns(:dates), "@dates assignment for #{mode}"
        end
      end

      test "get index as other publisher user" do
        user = User.all.detect { |user| user.company.is_a?(Publisher) && @publisher.id != user.company.id }
        assert_not_nil user, "Should have a user fixture for another publisher"

        time = Time.zone.parse("Oct 4, 2008 12:34:56")
        dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

        get_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
          assert_raises ActiveRecord::RecordNotFound, "Should raise exception for #{mode}" do
            action.call
          end
        end
      end

      test "xhr index as other publisher user" do
        user = User.all.detect { |user| user.company.is_a?(Publisher) && @publisher.id != user.company.id }
        assert_not_nil user, "Should have a user fixture for another publisher"

        time = Time.zone.parse("Oct 4, 2008 12:34:56")
        dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

        get_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
          assert_raises ActiveRecord::RecordNotFound, "Should raise exception for #{mode}" do
            action.call
          end
        end
      end

      test "get index as owned advertiser user" do
        user = User.all.detect { |user| user.company.is_a?(Advertiser) && @publisher == user.company.publisher }
        assert_not_nil user, "Should have a user fixture for an owned advertiser"

        time = Time.zone.parse("Oct 4, 2008 12:34:56")
        dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

        get_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
          assert_raises ActiveRecord::RecordNotFound, "Should raise exception for #{mode}" do
            action.call
          end
        end
      end

      test "xhr index as owned advertiser user" do
        user = User.all.detect { |user| user.company.is_a?(Advertiser) && @publisher == user.company.publisher }
        assert_not_nil user, "Should have a user fixture for an owned advertiser"

        time = Time.zone.parse("Oct 4, 2008 12:34:56")
        dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

        xhr_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
          assert_raises ActiveRecord::RecordNotFound, "Should raise exception for #{mode}" do
            action.call
          end
        end
      end

      test "get index as other advertiser user" do
        user = User.all.detect { |user| user.company.is_a?(Advertiser) && @publisher != user.company.publisher }
        assert_not_nil user, "Should have a user fixture for an unowned advertiser"

        time = Time.zone.parse("Oct 4, 2008 12:34:56")
        dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

        get_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
          assert_raises ActiveRecord::RecordNotFound, "Should raise exception for #{mode}" do
            action.call
          end
        end
      end

      test "xhr index as other advertiser user" do
        user = User.all.detect { |user| user.company.is_a?(Advertiser) && @publisher != user.company.publisher }
        assert_not_nil user, "Should have a user fixture for an unowned advertiser"

        time = Time.zone.parse("Oct 4, 2008 12:34:56")
        dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

        xhr_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
          assert_raises ActiveRecord::RecordNotFound, "Should raise exception for #{mode}" do
            action.call
          end
        end
      end

      test "xhr index with web filter as user for publisher" do
        dates = Date.parse("June 1, 2008") .. Date.parse("June 8, 2008")

        @publisher.advertisers.destroy_all

        advertiser_1 = @publisher.advertisers.create!(:name => "Advertiser 1")
        offer_1_1 = advertiser_1.offers.create!(:message => "Advertiser 1 Offer 1", :show_on => dates.begin + 1.day, :expires_on => dates.end - 1.day)
        offer_1_1.impression_counts.create! :publisher => @publisher, :count => 128, :created_at => Time.zone.parse("May 31, 2008 23:59:59")
        offer_1_1.impression_counts.create! :publisher => @publisher, :count =>  64, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00")
        offer_1_1.impression_counts.create! :publisher => @publisher, :count =>  32, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59")
        offer_1_1.impression_counts.create! :publisher => @publisher, :count =>  16, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00")

        offer_1_1.click_counts.create! :publisher => @publisher, :count => 8, :created_at => Time.zone.parse("May 31, 2008 23:59:59")
        offer_1_1.click_counts.create! :publisher => @publisher, :count => 4, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00")
        offer_1_1.click_counts.create! :publisher => @publisher, :count => 2, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59")
        offer_1_1.click_counts.create! :publisher => @publisher, :count => 1, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00")

        offer_1_1.click_counts.create! :publisher => @publisher, :count => 16, :created_at => Time.zone.parse("May 31, 2008 23:59:59"), :mode => "facebook"
        offer_1_1.click_counts.create! :publisher => @publisher, :count =>  8, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00"), :mode => "facebook"
        offer_1_1.click_counts.create! :publisher => @publisher, :count =>  4, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59"), :mode => "facebook"
        offer_1_1.click_counts.create! :publisher => @publisher, :count =>  2, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00"), :mode => "facebook"

        offer_1_1.click_counts.create! :publisher => @publisher, :count => 32, :created_at => Time.zone.parse("May 31, 2008 23:59:59"), :mode => "twitter"
        offer_1_1.click_counts.create! :publisher => @publisher, :count => 16, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00"), :mode => "twitter"
        offer_1_1.click_counts.create! :publisher => @publisher, :count =>  8, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59"), :mode => "twitter"
        offer_1_1.click_counts.create! :publisher => @publisher, :count =>  4, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00"), :mode => "twitter"

        offer_1_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("May 31, 2008 23:59:59")
        offer_1_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00")
        offer_1_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 02, 2008 12:34:56")
        offer_1_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 03, 2008 12:34:56")
        offer_1_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59")
        offer_1_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00")

        offer_1_1.leads.create!(
          :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("May 31, 2008 23:59:59"), :email => "joe@gmail.com"
        )
        offer_1_1.leads.create!(
          :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00"), :email => "jim@gmail.com"
        )
        offer_1_1.leads.create!(
          :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 02, 2008 12:34:56"), :email => "pip@gmail.com"
        )
        offer_1_1.leads.create!(
          :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59"), :email => "bif@gmail.com"
        )
        offer_1_1.leads.create!(
          :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00"), :email => "pat@gmail.com"
        )
        time = Time.zone.parse("May 31, 2008 23:59:59")
        lead = offer_1_1.leads.create!(:publisher => @publisher, :txt_me => true, :mobile_number => "858-882-8000", :created_at => time)
        lead.txts.first.update_attributes! :created_at => time, :status => "sent"

        time = Time.zone.parse("Jun 01, 2008 00:00:00")
        lead = offer_1_1.leads.create!(:publisher => @publisher, :txt_me => true, :mobile_number => "858-882-8001", :created_at => time)
        lead.txts.first.update_attributes! :created_at => time, :status => "sent"

        time = Time.zone.parse("Jun 02, 2008 12:34:56")
        lead = offer_1_1.leads.create!(:publisher => @publisher, :txt_me => true, :mobile_number => "858-882-8002", :created_at => time)
        lead.txts.first.update_attributes! :created_at => time, :status => "error"

        time = Time.zone.parse("Jun 08, 2008 12:34:56")
        lead = offer_1_1.leads.create!(:publisher => @publisher, :txt_me => true, :mobile_number => "858-882-8003", :created_at => time)
        lead.txts.first.update_attributes! :created_at => time, :status => "sent"

        time = Time.zone.parse("Jun 08, 2008 23:59:59")
        lead = offer_1_1.leads.create!(:publisher => @publisher, :txt_me => true, :mobile_number => "858-882-8004", :created_at => time)
        lead.txts.first.update_attributes! :created_at => time, :status => "sent"

        time = Time.zone.parse("Jun 09, 2008 00:00:00")
        lead = offer_1_1.leads.create!(:publisher => @publisher, :txt_me => true, :mobile_number => "858-882-8005", :created_at => time)
        lead.txts.first.update_attributes! :created_at => time, :status => "sent"

        offer_1_1.delete!

        offer_1_2 = advertiser_1.offers.create!(:message => "Advertiser 1 Offer 2", :show_on => dates.begin + 1.day, :expires_on => dates.end - 1.day)

        advertiser_2 = @publisher.advertisers.create!(:name => "Advertiser 2")
        txt_offer_2_1 = advertiser_2.txt_offers.create!(:short_code => "898411", :keyword => "SDHFOO", :message => "Advertiser 2 TXT Offer 1")
        txt_offer_2_1.inbound_txts.create!(
          :message => "FOO",
          :keyword => "SDHFOO", :subkeyword => "",
          :server_address => "898411",
          :originator_address => "16266745901",
          :accepted_time => Time.zone.parse("May 31, 2008 23:59:59")
        )
        txt_offer_2_1.inbound_txts.create!(
          :message => "SDHFOO",
          :keyword => "SDHFOO", :subkeyword => "",
          :server_address => "898411",
          :originator_address => "16266745902",
          :accepted_time => Time.zone.parse("Jun 01, 2008 00:00:00")
        )
        txt_offer_2_1.inbound_txts.create!(
          :message => "SDHFOO",
          :keyword => "SDHFOO", :subkeyword => "",
          :server_address => "898411",
          :originator_address => "16266745903",
          :accepted_time => Time.zone.parse("Jun 02, 2008 12:34:56")
        )
        txt_offer_2_1.inbound_txts.create!(
          :message => "SDHFOO",
          :keyword => "SDHFOO", :subkeyword => "",
          :server_address => "898411",
          :originator_address => "16266745904",
          :accepted_time => Time.zone.parse("Jun 05, 2008 12:34:56")
        )
        txt_offer_2_1.inbound_txts.create!(
          :message => "SDHFOO",
          :keyword => "SDHFOO", :subkeyword => "",
          :server_address => "898411",
          :originator_address => "16266745905",
          :accepted_time => Time.zone.parse("Jun 08, 2008 23:59:59")
        )
        txt_offer_2_1.inbound_txts.create!(
          :message => "SDHFOO",
          :keyword => "SDHFOO", :subkeyword => "",
          :server_address => "898411",
          :originator_address => "16266745906",
          :accepted_time => Time.zone.parse("Jun 09, 2008 00:00:00")
        )
        txt_offer_2_2 = advertiser_2.txt_offers.create!(:short_code => "898411", :keyword => "SDHBAR", :message => "Advertiser 2 TXT Offer 2")

        user = @publisher.users.first
        assert_not_nil user, "Publisher should have a user fixture"
        @request.session[:user_id] = user.try(:id)

        xhr :get, :index, {
          :publisher_id => @publisher.to_param,
          :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s,
          :summary => "web_offers",
          :format => "xml"
        }
        assert_response :success
        assert_equal @publisher, assigns(:publisher)
        assert_equal [advertiser_1], assigns(:advertisers)
        assert_equal dates, assigns(:dates)

        expected_response = { "advertisers" => { "advertiser" => {
          "id" => advertiser_1.id.to_s,
          "advertiser_name" => "Advertiser 1",
          "advertiser_href" => ERB::Util.html_escape(
            reports_advertiser_path(advertiser_1, :dates_begin => "2008-06-01", :dates_end => "2008-06-08", :summary => "web_offers")
          ),
          "coupons_count" => "1", # reduced to 1 because we don't count deleted offers
          "impressions_count" => "96",
          "clicks_count" => "14",
          "click_through_rate" => "14.5833333333333",
          "prints_count" => "4",
          "txts_count" => "3",
          "emails_count" => "3",
          "calls_count" => "0",
          "facebooks_count" => "12",
          "twitters_count" => "24"
        }}}
        assert_equal expected_response, Hash.from_xml(@response.body)
      end

      test "xhr index with txt filter as user for publisher" do
        @publisher.advertisers.destroy_all

        advertiser_1 = @publisher.advertisers.create!(:name => "Advertiser 1")
        offer_1_1 = advertiser_1.offers.create!(:message => "Advertiser 1 Offer 1")

        offer_1_1.impression_counts.create! :publisher => @publisher, :count => 128, :created_at => Time.zone.parse("May 31, 2008 23:59:59")
        offer_1_1.impression_counts.create! :publisher => @publisher, :count =>  64, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00")
        offer_1_1.impression_counts.create! :publisher => @publisher, :count =>  32, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59")
        offer_1_1.impression_counts.create! :publisher => @publisher, :count =>  16, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00")

        offer_1_1.click_counts.create! :publisher => @publisher, :count => 8, :created_at => Time.zone.parse("May 31, 2008 23:59:59")
        offer_1_1.click_counts.create! :publisher => @publisher, :count => 4, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00")
        offer_1_1.click_counts.create! :publisher => @publisher, :count => 2, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59")
        offer_1_1.click_counts.create! :publisher => @publisher, :count => 1, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00")

        offer_1_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("May 31, 2008 23:59:59")
        offer_1_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00")
        offer_1_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 02, 2008 12:34:56")
        offer_1_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 03, 2008 12:34:56")
        offer_1_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59")
        offer_1_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00")

        offer_1_1.leads.create!(
          :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("May 31, 2008 23:59:59"), :email => "joe@gmail.com"
        )
        offer_1_1.leads.create!(
          :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00"), :email => "jim@gmail.com"
        )
        offer_1_1.leads.create!(
          :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 02, 2008 12:34:56"), :email => "pip@gmail.com"
        )
        offer_1_1.leads.create!(
          :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59"), :email => "bif@gmail.com"
        )
        offer_1_1.leads.create!(
          :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00"), :email => "pat@gmail.com"
        )

        offer_1_2 = advertiser_1.offers.create!(:message => "Advertiser 1 Offer 2")

        advertiser_2 = @publisher.advertisers.create!(:name => "Advertiser 2")
        txt_offer_2_1 = advertiser_2.txt_offers.create!(:short_code => "898411", :keyword => "SDHFOO", :message => "Advertiser 2 TXT Offer 1")
        txt_offer_2_1.inbound_txts.create!(
          :message => "SDHFOO",
          :keyword => "SDHFOO", :subkeyword => "",
          :server_address => "898411",
          :originator_address => "16266745901",
          :accepted_time => Time.zone.parse("May 31, 2008 23:59:59")
        )
        txt_offer_2_1.inbound_txts.create!(
          :message => "SDHFOO",
          :keyword => "SDHFOO", :subkeyword => "",
          :server_address => "898411",
          :originator_address => "16266745902",
          :accepted_time => Time.zone.parse("Jun 01, 2008 00:00:00")
        )
        txt_offer_2_1.inbound_txts.create!(
          :message => "SDHFOO",
          :keyword => "SDHFOO", :subkeyword => "",
          :server_address => "898411",
          :originator_address => "16266745903",
          :accepted_time => Time.zone.parse("Jun 02, 2008 12:34:56")
        )
        txt_offer_2_1.inbound_txts.create!(
          :message => "SDHFOO",
          :keyword => "SDHFOO", :subkeyword => "",
          :server_address => "898411",
          :originator_address => "16266745904",
          :accepted_time => Time.zone.parse("Jun 05, 2008 12:34:56")
        )
        txt_offer_2_1.inbound_txts.create!(
          :message => "SDHFOO",
          :keyword => "SDHFOO", :subkeyword => "",
          :server_address => "898411",
          :originator_address => "16266745905",
          :accepted_time => Time.zone.parse("Jun 08, 2008 23:59:59")
        )
        txt_offer_2_1.inbound_txts.create!(
          :message => "SDHFOO",
          :keyword => "SDHFOO", :subkeyword => "",
          :server_address => "898411",
          :originator_address => "16266745906",
          :accepted_time => Time.zone.parse("Jun 09, 2008 00:00:00")
        )
        txt_offer_2_1.delete!

        txt_offer_2_2 = advertiser_2.txt_offers.create!(:short_code => "898411", :keyword => "SDHBAR", :message => "Advertiser 2 TXT Offer 2")

        user = @publisher.users.first
        assert_not_nil user, "Publisher should have a user fixture"
        @request.session[:user_id] = user.try(:id)

        dates = Date.parse("June 1, 2008") .. Date.parse("June 8, 2008")
        xhr :get, :index, {
          :publisher_id => @publisher.to_param,
          :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s,
          :summary => "txt_offers",
          :format => "xml"
        }
        assert_response :success
        assert_equal @publisher, assigns(:publisher)
        assert_equal [advertiser_2], assigns(:advertisers)
        assert_equal dates, assigns(:dates)

        expected_response = { "advertisers" => { "advertiser" => {
          "id" => advertiser_2.id.to_s,
          "advertiser_name" => "Advertiser 2",
          "advertiser_href" => ERB::Util.html_escape(
            reports_advertiser_path(advertiser_2, :dates_begin => "2008-06-01", :dates_end => "2008-06-08", :summary => "txt_offers")
          ),
          "txt_coupons_count"=>"2",
          "inbound_txts_count"=>"4"
        }}}
        assert_equal expected_response, Hash.from_xml(@response.body)
      end

      test "xhr index with deal certificates" do
        @publisher.advertisers.destroy_all

        a_1 = @publisher.advertisers.create(:name => "A1")
        g_1_1 = a_1.gift_certificates.create!(
          :message => "A1G1",
          :value => 40.00,
          :price => 19.99,
          :show_on => "Nov 13, 2008",
          :expires_on => "Nov 17, 2008",
          :number_allocated => 10
        )
        g_1_2 = a_1.gift_certificates.create!(
          :message => "A1G2",
          :value => 20.00,
          :price => 9.99,
          :show_on => "Nov 16, 2008",
          :expires_on => "Nov 19, 2008",
          :number_allocated => 20
        )
        a_2 = @publisher.advertisers.create(:name => "A2")
        g_2_1 = a_2.gift_certificates.create!(
          :message => "A2G1",
          :value => 30.00,
          :price => 14.99,
          :show_on => "Nov 18, 2008",
          :expires_on => "Nov 20, 2008",
          :number_allocated => 30
        )
        a_3 = publishers(:sdreader).advertisers.create(:name => "A3")
        g_3_1 = a_3.gift_certificates.create!(
          :message => "A3G1",
          :value => 40.00,
          :price => 19.99,
          :show_on => "Nov 13, 2008",
          :expires_on => "Nov 17, 2008",
          :number_allocated => 10
        )

        i = 10
        purchase = lambda do |gift_certificate, purchase_time, payment_status|
          i += 1
          gift_certificate.purchased_gift_certificates.create!(
            :gift_certificate => gift_certificate,
            :paypal_payment_date => purchase_time,
            :paypal_txn_id => "38D93468JC71666#{i}",
            :paypal_receipt_id => "3625-4706-3930-06#{i}",
            :paypal_invoice => "1234567#{i}",
            :paypal_payment_gross => "%.2f" % gift_certificate.price,
            :paypal_payer_email => "higgins@london.com",
            :payment_status => payment_status
          )
        end
        purchase.call(g_1_1, "00:00:00 Nov 15, 2008 PST", "completed")
        purchase.call(g_1_1, "00:00:01 Nov 15, 2008 PST", "reversed")
        purchase.call(g_1_1, "12:34:56 Nov 15, 2008 PST", "completed")
        purchase.call(g_1_1, "23:59:59 Nov 15, 2008 PST", "completed")
        purchase.call(g_1_1, "00:00:00 Nov 16, 2008 PST", "completed")
        purchase.call(g_1_1, "12:34:56 Nov 16, 2008 PST", "completed")
        purchase.call(g_1_1, "00:00:00 Nov 17, 2008 PST", "reversed")
        purchase.call(g_1_1, "23:59:59 Nov 17, 2008 PST", "completed")

        purchase.call(g_1_2, "00:00:00 Nov 16, 2008 PST", "completed")
        purchase.call(g_1_2, "00:00:01 Nov 16, 2008 PST", "reversed")
        purchase.call(g_1_2, "12:34:56 Nov 16, 2008 PST", "completed")
        purchase.call(g_1_2, "23:59:59 Nov 16, 2008 PST", "reversed")
        purchase.call(g_1_2, "00:00:00 Nov 17, 2008 PST", "completed")
        purchase.call(g_1_2, "12:34:56 Nov 17, 2008 PST", "completed")
        purchase.call(g_1_2, "00:00:00 Nov 18, 2008 PST", "completed")
        purchase.call(g_1_2, "23:59:59 Nov 18, 2008 PST", "completed")
        purchase.call(g_1_2, "00:00:00 Nov 19, 2008 PST", "refunded")
        purchase.call(g_1_2, "12:34:56 Nov 19, 2008 PST", "completed")
        purchase.call(g_1_2, "12:34:56 Nov 19, 2008 PST", "completed")
        purchase.call(g_1_2, "23:59:59 Nov 16, 2008 PST", "reversed")

        purchase.call(g_2_1, "00:00:00 Nov 18, 2008 PST", "completed")
        purchase.call(g_2_1, "00:00:01 Nov 18, 2008 PST", "reversed")
        purchase.call(g_2_1, "12:34:56 Nov 18, 2008 PST", "completed")
        purchase.call(g_2_1, "00:00:00 Nov 19, 2008 PST", "completed")
        purchase.call(g_2_1, "12:34:56 Nov 19, 2008 PST", "completed")
        purchase.call(g_2_1, "00:00:00 Nov 20, 2008 PST", "refunded")
        purchase.call(g_2_1, "23:59:59 Nov 20, 2008 PST", "completed")

        purchase.call(g_3_1, "00:00:00 Nov 15, 2008 PST", "completed")
        purchase.call(g_3_1, "12:34:56 Nov 15, 2008 PST", "completed")
        purchase.call(g_3_1, "23:59:59 Nov 15, 2008 PST", "completed")
        purchase.call(g_3_1, "00:00:00 Nov 16, 2008 PST", "completed")
        purchase.call(g_3_1, "12:34:56 Nov 16, 2008 PST", "completed")
        purchase.call(g_3_1, "23:59:59 Nov 17, 2008 PST", "completed")

        login_as @publisher.users.first
        dates = Date.parse("Nov 15, 2008")..Date.parse("Nov 20, 2008")
        xhr :get, :index, {
          :publisher_id => @publisher.to_param,
          :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s,
          :summary => "gift_certificates",
          :format => "xml"
        }
        expected_response = {
          "advertisers" => {
            "advertiser" => [{
                               "id" => a_1.id.to_s,
                               "advertiser_name" => "A1",
                               "advertiser_href" => ERB::Util.html_escape(
                                 reports_advertiser_path(a_1, :dates_begin => "2008-11-15", :dates_end => "2008-11-20", :summary => "gift_certificates")
                               ),
                               "available_count_begin" => "10",
                               "available_revenue_begin" => "199.90",
                               "purchased_count" => "14",
                               "purchased_revenue" => "199.86",
                               "available_count_end" => "0",
                               "currency_code" => "USD",
                               "currency_symbol" => "$",
                               "available_revenue_end" => "0.00"
                             }, {
              "id" => a_2.id.to_s,
              "advertiser_name" => "A2",
              "advertiser_href" => ERB::Util.html_escape(
                reports_advertiser_path(a_2, :dates_begin => "2008-11-15", :dates_end => "2008-11-20", :summary => "gift_certificates")
              ),
              "available_count_begin" => "0",
              "available_revenue_begin" => "0.00",
              "currency_code" => "USD",
              "currency_symbol" => "$",
              "purchased_count" => "5",
              "purchased_revenue" => "74.95",
              "available_count_end" => "0",
              "available_revenue_end" => "0.00"
            }]
          }
        }
        assert_equal expected_response, Hash.from_xml(@response.body)
      end

      test "xhr index with daily deals" do
        click_count = lambda do |mode, publisher, clickable|
          Factory(:click_count, :mode => mode, :publisher => publisher, :clickable => clickable)
        end

        advertiser = Factory(:daily_deal_advertiser, :name => "Bar")
        daily_deal = Factory(:daily_deal, :advertiser => advertiser)
        publisher  = advertiser.publisher
        facebook_click_count = click_count.call("facebook", publisher, daily_deal)
        twitter_click_count  = click_count.call("twitter", publisher, daily_deal)

        advertiser2 = Factory(:daily_deal_advertiser, :publisher => publisher, :name => "Foo")
        daily_deal2 = Factory(:daily_deal, :advertiser => advertiser2, :start_at => daily_deal.hide_at + 1.day, :hide_at => Time.zone.now.tomorrow + 10.days)
        facebook_click_count2 = click_count.call("facebook", publisher, daily_deal2)
        twitter_click_count2  = click_count.call("twitter", publisher, daily_deal2)

        dates = Date.parse(10.days.ago.to_s) .. Date.parse(Time.zone.now.to_s)

        login_as Factory(:user, :company => publisher)

        xhr :get, :index, {
          :publisher_id => publisher.to_param,
          :summary      => "daily_deals",
          :format       => "xml"
        }

        assert_template "index_with_daily_deals"
        assert_response :success

        response_hash = Hash.from_xml(@response.body)

        a1, a2 = response_hash['advertisers']['advertiser']

        assert_equal advertiser.name, a1['advertiser_name']
        assert_equal advertiser.id.to_s, a1['id']
        assert_equal facebook_click_count.count.to_s, a1['facebook_count']
        assert_equal twitter_click_count.count.to_s, a1['twitter_count']

        assert_equal daily_deal2.advertiser.name, a2['advertiser_name']
        assert_equal daily_deal2.advertiser.id.to_s, a2['id']
        assert_equal facebook_click_count2.count.to_s, a2['facebook_count']
        assert_equal twitter_click_count2.count.to_s, a2['twitter_count']
      end

      test "get index with daily deals" do
        daily_deal = Factory(:daily_deal)
        publisher  = daily_deal.advertiser.publisher

        login_as Factory(:user, :company => publisher)

        get :index, { :publisher_id => publisher.to_param, :summary => "daily_deals" }

        assert_template "index_with_daily_deals.html.erb"
        assert_response :success
      end

      test "csv index with daily deals" do
        click_count = lambda do |mode, publisher, clickable|
          Factory(:click_count, :mode => mode, :publisher => publisher, :clickable => clickable)
        end

        advertiser = Factory(:daily_deal_advertiser, :name => "Bar")
        daily_deal = Factory(:daily_deal, :advertiser => advertiser)
        publisher  = advertiser.publisher
        facebook_click_count = click_count.call("facebook", publisher, daily_deal)
        twitter_click_count  = click_count.call("twitter", publisher, daily_deal)

        advertiser2 = Factory(:daily_deal_advertiser, :publisher => publisher, :name => "Foo")
        daily_deal2 = Factory(:daily_deal, :advertiser => advertiser2, :start_at => daily_deal.hide_at + 1.day, :hide_at => Time.zone.now.tomorrow + 10.days)
        facebook_click_count2 = click_count.call("facebook", publisher, daily_deal2)
        twitter_click_count2  = click_count.call("twitter", publisher, daily_deal2)

        dates = Date.parse(10.days.ago.to_s) .. Date.parse(Time.zone.now.to_s)

        login_as Factory(:user, :company => publisher)

        get :index, {
          :publisher_id => publisher.to_param,
          :summary      => "daily_deals",
          :format       => "csv"
        }
        assert_response :success

        csv = FasterCSV.new(@response.binary_content)
        assert_equal [
                       "Advertiser",
                       "Facebook",
                       "Twitter",
                     ], csv.shift, "CSV headers"

        row = csv.shift
        assert_equal advertiser.name, row[0]
        assert_equal facebook_click_count.count.to_s, row[1]
        assert_equal twitter_click_count.count.to_s, row[2]

        row = csv.shift
        assert_equal daily_deal2.advertiser.name, row[0]
        assert_equal facebook_click_count2.count.to_s, row[1]
        assert_equal twitter_click_count2.count.to_s, row[2]

        assert_nil csv.shift, "Should have only 2 data rows in CSV output"
      end

      test "csv download of purchased deal certificates" do
        advertiser = @publisher.advertisers.create(:name => "A1")
        gift_certificate = advertiser.gift_certificates.create!(
          :message => "A1G1",
          :value => 40.00,
          :price => 19.99,
          :show_on => "Nov 13, 2008",
          :expires_on => "Nov 17, 2008",
          :number_allocated => 10
        )
        gift_certificate.purchased_gift_certificates.create!(
          :gift_certificate => gift_certificate,
          :paypal_payment_date => "00:00:01 Nov 15, 2008 PST",
          :paypal_txn_id => "38D93468JC7166612",
          :paypal_receipt_id => "3625-4706-3930-0612",
          :paypal_invoice => "123456712",
          :paypal_payment_gross => "%.2f" % gift_certificate.price,
          :paypal_payer_email => "higgins12@london.com",
          :paypal_address_name => "Henry Higgins",
          :paypal_address_street => "12 Penny Lane",
          :paypal_address_city => "London",
          :paypal_address_state => "KY",
          :paypal_address_zip => "123412",
          :payment_status => "completed"
        )

        dates = Date.parse("Nov 15, 2008")..Date.parse("Nov 17, 2008")

        login_as @publisher.users.first
        get :purchased_gift_certificates, {
          :publisher_id => @publisher.to_param, :id => advertiser.to_param,
          :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s,
          :format => "csv"
        }

        # This is required to actually execute the code that streams out
        # the CSV file. DO NOT REMOVE THIS LINE!
        @response.binary_content

        assert_response :success
      end

      test "xhr purchased deal certificates" do
        @publisher.advertisers.destroy_all

        a_1 = @publisher.advertisers.create(:name => "A1")
        g_1_1 = a_1.gift_certificates.create!(
          :message => "A1G1",
          :value => 40.00,
          :price => 19.99,
          :show_on => "Nov 13, 2008",
          :expires_on => "Nov 17, 2008",
          :number_allocated => 10
        )
        g_1_2 = a_1.gift_certificates.create!(
          :message => "A1G2",
          :value => 20.00,
          :price => 9.99,
          :show_on => "Nov 16, 2008",
          :expires_on => "Nov 19, 2008",
          :number_allocated => 20
        )
        purchase = lambda do |s, gift_certificate, purchase_time, payment_status|
          gift_certificate.purchased_gift_certificates.create!(
            :gift_certificate => gift_certificate,
            :paypal_payment_date => purchase_time,
            :paypal_txn_id => "38D93468JC71666#{s}",
            :paypal_receipt_id => "3625-4706-3930-06#{s}",
            :paypal_invoice => "1234567#{s}",
            :paypal_payment_gross => "%.2f" % gift_certificate.price,
            :paypal_payer_email => "higgins#{s}@london.com",
            :paypal_address_name => "Henry Higgins",
            :paypal_address_street => "#{s} Penny Lane",
            :paypal_address_city => "London",
            :paypal_address_state => "KY",
            :paypal_address_zip => "1234#{s}",
            :payment_status => payment_status
          )
        end
        purchase.call(11, g_1_1, "00:00:01 Nov 15, 2008 PST", "reversed")
        purchase.call(12, g_1_1, "12:34:56 Nov 15, 2008 PST", "completed")
        purchase.call(13, g_1_1, "23:59:59 Nov 15, 2008 PST", "completed")
        purchase.call(14, g_1_1, "12:34:56 Nov 16, 2008 PST", "completed")
        purchase.call(15, g_1_1, "00:00:00 Nov 17, 2008 PST", "reversed")
        purchase.call(16, g_1_1, "23:59:59 Nov 17, 2008 PST", "completed")

        purchase.call(17, g_1_2, "00:00:00 Nov 16, 2008 PST", "completed")
        purchase.call(18, g_1_2, "00:00:01 Nov 16, 2008 PST", "reversed")
        purchase.call(19, g_1_2, "12:34:56 Nov 16, 2008 PST", "completed")
        purchase.call(20, g_1_2, "23:59:59 Nov 16, 2008 PST", "refunded")
        purchase.call(21, g_1_2, "00:00:00 Nov 17, 2008 PST", "completed")
        purchase.call(22, g_1_2, "12:34:56 Nov 17, 2008 PST", "completed")
        purchase.call(23, g_1_2, "23:59:59 Nov 18, 2008 PST", "completed")

        login_as @publisher.users.first
        dates = Date.parse("Nov 15, 2008")..Date.parse("Nov 17, 2008")
        xhr :get, :purchased_gift_certificates, {
          :publisher_id => @publisher.to_param, :id => a_1.to_param,
          :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s,
          :format => "xml"
        }
        records = Hash.from_xml(@response.body).try(:fetch, "purchased_gift_certificates").try(:fetch, "purchased_gift_certificate")
        assert_not_nil records, "Should have a list of purchased deal certificates"
        assert_equal 7, records.size
        %w{ 12 13 17 14 19 21 22 }.each_with_index do |s, i|
          record = records[i]
          assert_not_nil purchased_gift_certificate = PurchasedGiftCertificate.find_by_id(record["purchased_gift_certificate_id"])

          assert_equal "Henry Higgins", record["recipient_name"]
          assert_equal "higgins#{s}@london.com", record["paypal_payer_email"]
          assert_equal purchased_gift_certificate.serial_number, record["serial_number"]
          assert_equal purchased_gift_certificate.paypal_payment_date.to_date.to_s, record["paypal_payment_date"]
          assert_equal purchased_gift_certificate.item_number, record["item_number"]
          assert_equal "%.2f" % purchased_gift_certificate.value, record["value"]
          assert_equal "%.2f" % purchased_gift_certificate.paypal_payment_gross, record["paypal_payment_gross"]
          assert_equal "open", record["status"]
        end
      end

      test "purchased daily deals as xml" do
        advertiser = Factory(:store).advertiser
        store = advertiser.stores.create!(:phone_number => "(212) 212-1212")
        daily_deal = Factory(:daily_deal, :advertiser => advertiser, :location_required => true)

        daily_deal_purchase = daily_deal.daily_deal_purchases.build
        daily_deal_purchase.consumer = Factory(:consumer, :publisher => advertiser.publisher)
        daily_deal_purchase.quantity = 2
        daily_deal_purchase.store = store
        daily_deal_purchase.save!

        braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
        daily_deal_purchase.handle_braintree_sale! braintree_transaction
        assert_equal 2, daily_deal_purchase.daily_deal_certificates.count

        login_as :aaron
        xhr :get, :purchased_daily_deals, :format => "xml", :id => advertiser.to_param, :dates_begin => 1.week.ago, :dates_end => 1.week.from_now
        assert_response :success
      end

      test "purchased daily deals as csv" do
        advertiser = Factory(:store).advertiser
        Factory(:store, :advertiser => advertiser)
        daily_deal = Factory(:daily_deal, :advertiser => advertiser.reload, :location_required => true)
        DailyDealCertificate.destroy_all

        daily_deal_purchase = daily_deal.daily_deal_purchases.build
        daily_deal_purchase.consumer = Factory(:consumer, :publisher => advertiser.publisher, :name => "John Public")
        daily_deal_purchase.quantity = 2
        daily_deal_purchase.store = advertiser.store
        daily_deal_purchase.save!

        braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
        daily_deal_purchase.handle_braintree_sale! braintree_transaction
        assert_equal 2, daily_deal_purchase.daily_deal_certificates.count

        login_as :aaron
        get :purchased_daily_deals, :format => "csv", :id => advertiser.to_param, :dates_begin => 1.week.ago, :dates_end => 1.week.from_now
        assert_response :success

        csv = FasterCSV.new(@response.binary_content)
        assert_equal [
                       "Purchaser Name",
                       #"Purchaser Email",
                       "Recipient Name",
                       "Redeemed On",
                       "Redeemed At",
                       "Serial Number",
                       "Deal",
                       "Value",
                       "Price",
                       "Purchase Price",
                       "Purchase Date"
                     ], csv.shift, "CSV headers"

        row = csv.shift
        assert_equal "John Public", row[0]
        #assert_equal daily_deal_purchase.consumer.email, row[1]
        assert_equal "John Public", row[1]
        assert_equal "3005 South Lamar, Austin, TX", row[3]
        assert_equal "$30.00 for only $15.00!", row[5]
        assert_equal "$30.00", row[6]
        assert_equal "$15.00", row[7]
        assert_equal "$15.00", row[8]
        assert_equal Time.zone.today.to_s, row[9]

        row = csv.shift
        assert_equal "John Public", row[0]
        #assert_equal daily_deal_purchase.consumer.email, row[1]
        assert_equal "John Public", row[1]
        assert_equal "3005 South Lamar, Austin, TX", row[3]
        assert_equal "$30.00 for only $15.00!", row[5]
        assert_equal "$30.00", row[6]
        assert_equal "$15.00", row[7]
        assert_equal "$15.00", row[8]
        assert_equal Time.zone.today.to_s, row[9]

        assert_nil csv.shift, "Should have only 2 data rows in CSV output"
      end

      test "xhr affiliated daily deals" do
        advertiser = Factory(:advertiser)

        deal_1 = Factory(:daily_deal,
                         :publisher => advertiser.publisher,
                         :advertiser => advertiser,
                         :price => 20.00,
                         :start_at => Time.zone.parse("Mar 04, 2011 07:00:00"),
                         :hide_at => Time.zone.parse("Mar 04, 2011 17:00:00"),
                         :affiliate_revenue_share_percentage => 20.0)

        deal_1_placement = Factory(:affiliate_placement, :placeable => deal_1)

        deal_1_purchase_1 = Factory(:captured_daily_deal_purchase_no_certs,
                                    :daily_deal => deal_1,
                                    :executed_at => deal_1.start_at + 1.minutes,
                                    :affiliate => deal_1_placement.affiliate)
        deal_1_certificate_1 = Factory(:daily_deal_certificate,
                                       :serial_number => "serial0",
                                       :daily_deal_purchase => deal_1_purchase_1)

        deal_1_purchase_2 = Factory(:captured_daily_deal_purchase_no_certs,
                                    :daily_deal => deal_1,
                                    :executed_at => deal_1.start_at + 5.minutes,
                                    :affiliate => deal_1_placement.affiliate,
                                    :quantity => 5)
        deal_1_certificate_2 = Factory(:daily_deal_certificate,
                                       :serial_number => "serial1",
                                       :daily_deal_purchase => deal_1_purchase_2)

        deal_1_purchase_3 = Factory(:captured_daily_deal_purchase_no_certs,
                                    :daily_deal => deal_1,
                                    :executed_at => deal_1.start_at + 9.minutes)
        deal_1_certificate_3 = Factory(:daily_deal_certificate,
                                       :serial_number => "serial2",
                                       :daily_deal_purchase => deal_1_purchase_3)

        deal_2 = Factory(:daily_deal,
                         :publisher => advertiser.publisher,
                         :advertiser => advertiser,
                         :price => 15.00,
                         :start_at => Time.zone.parse("Mar 05, 2011 07:00:00"),
                         :hide_at => Time.zone.parse("Mar 05, 2011 17:00:00"),
                         :affiliate_revenue_share_percentage => 10.0)

        deal_2_placement_1 = Factory(:affiliate_placement, :placeable => deal_2)
        deal_2_placement_2 = Factory(:affiliate_placement, :placeable => deal_2)

        deal_2_purchase = Factory(:captured_daily_deal_purchase_no_certs,
                                  :daily_deal => deal_2,
                                  :executed_at => deal_2.start_at + 2.minutes,
                                  :affiliate => deal_2_placement_2.affiliate)
        deal_2_certificate = Factory(:daily_deal_certificate,
                                     :serial_number => "serial3",
                                     :daily_deal_purchase => deal_2_purchase)

        deal_3 = Factory(:daily_deal,
                         :publisher => advertiser.publisher,
                         :advertiser => advertiser,
                         :price => 10.00,
                         :start_at => Time.zone.parse("Mar 06, 2011 07:00:00"),
                         :hide_at => Time.zone.parse("Mar 06, 2011 17:00:00"),
                         :affiliate_revenue_share_percentage => 5.0)

        Factory(:captured_daily_deal_purchase, :daily_deal => deal_2)

        user = Factory(:user, :company => advertiser.publisher)
        login_as user

        get :affiliated_daily_deals,
            :format => "xml",
            :id => advertiser.to_param,
            :dates_begin => Time.zone.parse("Mar 01, 2011 07:00:00").to_s,
            :dates_end => Time.zone.parse("Mar 10, 2011 17:00:00").to_s

        assert_response :success
        assert_template :affiliated_daily_deals

        assert_select "daily_deal_certificate[daily_deal_certificate_id='#{deal_1_certificate_1.id}']" do
          assert_select "customer_name", deal_1_purchase_1.consumer.name
          assert_select "recipient_name", deal_1_certificate_1.redeemer_name
          assert_select "serial_number", deal_1_certificate_1.serial_number
          assert_select "value_proposition", deal_1.value_proposition
          assert_select "accounting_id", deal_1.accounting_id
          assert_select "listing", deal_1.listing
          assert_select "affiliate_name", deal_1_placement.affiliate.name
          assert_select "price", "20.00"
          assert_select "purchased_price", "20.00"
          assert_select "currency_symbol", "$"
          assert_select "affiliate_rev_share", "20.00"
          assert_select "affiliate_payout", "4.00"
          assert_select "affiliate_total", "16.00"
          assert_select "purchased_date", "2011-03-04"
        end

        assert_select "daily_deal_certificate[daily_deal_certificate_id='#{deal_1_certificate_2.id}']" do
          assert_select "customer_name", deal_1_purchase_2.consumer.name
          assert_select "recipient_name", deal_1_certificate_2.redeemer_name
          assert_select "serial_number", deal_1_certificate_2.serial_number
          assert_select "value_proposition", deal_1.value_proposition
          assert_select "accounting_id", deal_1.accounting_id
          assert_select "listing", deal_1.listing
          assert_select "affiliate_name", deal_1_placement.affiliate.name
          assert_select "price", "20.00"
          assert_select "purchased_price", "20.00"
          assert_select "currency_symbol", "$"
          assert_select "affiliate_rev_share", "20.00"
          assert_select "affiliate_payout", "4.00"
          assert_select "affiliate_total", "16.00"
          assert_select "purchased_date", "2011-03-04"
        end

        assert_select "daily_deal_certificate[daily_deal_certificate_id='#{deal_2_certificate.id}']" do
          assert_select "customer_name", deal_2_purchase.consumer.name
          assert_select "recipient_name", deal_2_certificate.redeemer_name
          assert_select "serial_number", deal_2_certificate.serial_number
          assert_select "value_proposition", deal_2.value_proposition
          assert_select "accounting_id", deal_2.accounting_id
          assert_select "listing", deal_2.listing
          assert_select "affiliate_name", deal_2_placement_2.affiliate.name
          assert_select "price", "15.00"
          assert_select "purchased_price", "15.00"
          assert_select "currency_symbol", "$"
          assert_select "affiliate_rev_share", "10.00"
          assert_select "affiliate_payout", "1.50"
          assert_select "affiliate_total", "13.50"
          assert_select "purchased_date", "2011-03-05"
        end
      end

      test "affiliated daily deals csv" do
        advertiser = Factory(:advertiser)

        deal = Factory(:daily_deal,
                       :publisher => advertiser.publisher,
                       :advertiser => advertiser,
                       :price => 20.00,
                       :start_at => Time.zone.parse("Mar 04, 2011 07:00:00"),
                       :hide_at => Time.zone.parse("Mar 04, 2011 17:00:00"),
                       :affiliate_revenue_share_percentage => 20.0)

        placement = Factory(:affiliate_placement, :placeable => deal)

        purchase = Factory(:captured_daily_deal_purchase_no_certs,
                           :daily_deal => deal,
                           :executed_at => deal.start_at + 1.minutes,
                           :affiliate => placement.affiliate)
        certificate = Factory(:daily_deal_certificate,
                              :serial_number => "serial0",
                              :daily_deal_purchase => purchase)

        user = Factory(:user, :company => advertiser.publisher)
        login_as user

        get :affiliated_daily_deals,
            :format => "csv",
            :id => advertiser.to_param,
            :dates_begin => Time.zone.parse("Mar 01, 2011 07:00:00").to_s,
            :dates_end => Time.zone.parse("Mar 10, 2011 17:00:00").to_s

        assert_response :success

        csv = FasterCSV.new(@response.binary_content)

        row = csv.shift
        headers = [
          "Purchaser",
          "Recipient",
          "Affiliate",
          "Serial Number",
          "Deal",
          "Accounting ID",
          "Listing",
          "Price",
          "Purchase Price",
          "Affiliate Rev. Share",
          "Affiliate Payout",
          "Total",
          "Purchase Date"
        ]
        assert_equal headers, row

        row = csv.shift
        assert_equal certificate.consumer_name, row[0]
        assert_equal certificate.redeemer_name, row[1]
        assert_equal certificate.affiliate_name, row[2]
        assert_equal "serial0", row[3]
        assert_equal deal.value_proposition, row[4]
        assert_equal deal.accounting_id, row[5]
        assert_equal deal.listing, row[6]
        assert_equal "$20.00", row[7]
        assert_equal "$20.00", row[8]
        assert_equal "20.0%", row[9]
        assert_equal "$4.00", row[10]
        assert_equal "$16.00", row[11]
        assert_equal "2011-03-04", row[12]
      end

      test "affiliated daily deals" do
        advertiser = Factory(:advertiser)
        user = Factory(:user, :company => advertiser.publisher)
        login_as user

        get :affiliated_daily_deals,
            :id => advertiser.to_param,
            :dates_begin => Time.zone.parse("Mar 01, 2011 07:00:00").to_s,
            :dates_end => Time.zone.parse("Mar 10, 2011 17:00:00").to_s

        assert_response :success
        assert_template :affiliated_daily_deals
      end

      test "purchased daily deals with market should render xml with deals in market" do

        Timecop.freeze(Time.zone.now) do
          advertiser = Factory(:store).advertiser
          store = advertiser.stores.create!(:phone_number => "(212) 212-1212")
          daily_deal = Factory(:daily_deal, :advertiser => advertiser, :location_required => true)
          market = Factory(:market, :publisher => advertiser.publisher)
          daily_deal.markets << market

          daily_deal_purchase = daily_deal.daily_deal_purchases.build
          daily_deal_purchase.consumer = Factory(:consumer, :publisher => advertiser.publisher)
          daily_deal_purchase.quantity = 2
          daily_deal_purchase.store = store
          daily_deal_purchase.market = market
          daily_deal_purchase.save!

          braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
          daily_deal_purchase.handle_braintree_sale! braintree_transaction
          assert_equal 2, daily_deal_purchase.daily_deal_certificates.count
          ddc1 = daily_deal_purchase.daily_deal_certificates[0]
          ddc2 = daily_deal_purchase.daily_deal_certificates[1]

          login_as :aaron
          get  :purchased_daily_deals,
               :format => "xml",
               :id => advertiser.to_param,
               :market_id => market.to_param,
               :dates_begin => 1.week.ago,
               :dates_end => 1.week.from_now
          assert_response :success

          assert_select "daily_deal_certificate[daily_deal_certificate_id='#{ddc1.id}']" do
            assert_select "customer_name", daily_deal_purchase.consumer.name
            assert_select "recipient_name", ddc1.redeemer_name
            assert_select "serial_number", ddc1.serial_number
            assert_select "redeemed_at", ""
            assert_select "currency_symbol", "$"
            assert_select "store_name", ddc1.store_name
            assert_select "value_proposition", daily_deal.value_proposition
            assert_select "value", "30.00"
            assert_select "price", "15.00"
            assert_select "purchased_price", "15.00"
            assert_select "purchased_date", Time.zone.now.to_formatted_s(:db_date)
          end

          assert_select "daily_deal_certificate[daily_deal_certificate_id='#{ddc2.id}']" do
            assert_select "customer_name", daily_deal_purchase.consumer.name
            assert_select "recipient_name", ddc2.redeemer_name
            assert_select "serial_number", ddc2.serial_number
            assert_select "redeemed_at", ""
            assert_select "currency_symbol", "$"
            assert_select "store_name", ddc2.store_name
            assert_select "value_proposition", daily_deal.value_proposition
            assert_select "value", "30.00"
            assert_select "price", "15.00"
            assert_select "purchased_price", "15.00"
            assert_select "purchased_date", Time.zone.now.to_formatted_s(:db_date)
          end
        end
      end

      test "purchased daily deals with market should render csv with deals in market" do
        Timecop.freeze(Time.zone.now) do
          advertiser = Factory(:store).advertiser
          Factory(:store, :advertiser => advertiser)
          daily_deal = Factory(:daily_deal, :advertiser => advertiser.reload, :location_required => true)
          market = Factory(:market, :publisher => advertiser.publisher)
          daily_deal.markets << market
          DailyDealCertificate.destroy_all

          daily_deal_purchase = daily_deal.daily_deal_purchases.build
          daily_deal_purchase.consumer = Factory(:consumer, :publisher => advertiser.publisher, :name => "John Public")
          daily_deal_purchase.quantity = 2
          daily_deal_purchase.store = advertiser.store
          daily_deal_purchase.market = market
          daily_deal_purchase.save!

          braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
          daily_deal_purchase.handle_braintree_sale! braintree_transaction
          assert_equal 2, daily_deal_purchase.daily_deal_certificates.count

          login_as :aaron
          get :purchased_daily_deals,
              :format => "csv",
              :id => advertiser.to_param,
              :market_id => market.to_param,
              :dates_begin => 1.week.ago,
              :dates_end => 1.week.from_now
          assert_response :success

          csv = FasterCSV.new(@response.binary_content)
          assert_equal [
                         "Purchaser Name",
                         #"Purchaser Email",
                         "Recipient Name",
                         "Redeemed On",
                         "Redeemed At",
                         "Serial Number",
                         "Deal",
                         "Value",
                         "Price",
                         "Purchase Price",
                         "Purchase Date"
                       ], csv.shift, "CSV headers"

          row = csv.shift
          assert_equal "John Public", row[0]
          #assert_equal daily_deal_purchase.consumer.email, row[1]
          assert_equal "John Public", row[1]
          assert_equal "3005 South Lamar, Austin, TX", row[3]
          assert_equal "$30.00 for only $15.00!", row[5]
          assert_equal "$30.00", row[6]
          assert_equal "$15.00", row[7]
          assert_equal "$15.00", row[8]
          assert_equal Time.zone.today.to_s, row[9]

          row = csv.shift
          assert_equal "John Public", row[0]
          #assert_equal daily_deal_purchase.consumer.email, row[1]
          assert_equal "John Public", row[1]
          assert_equal "3005 South Lamar, Austin, TX", row[3]
          assert_equal "$30.00 for only $15.00!", row[5]
          assert_equal "$30.00", row[6]
          assert_equal "$15.00", row[7]
          assert_equal "$15.00", row[8]
          assert_equal Time.zone.today.to_s, row[9]

          assert_nil csv.shift, "Should have only 2 data rows in CSV output"
        end
      end

      context "refunded daily deal certificates for period with market" do
        setup do
          @report_date_begin = Time.zone.local(2011, 3, 1, 0, 0, 0)
          @report_date_end = Time.zone.local(2011, 3, 15, 0, 0, 0)

          @daily_deal_1 = Factory(:side_daily_deal, :value_proposition => "deal_1")
          @daily_deal_2 = Factory(:daily_deal, :value_proposition => "deal_2", :publisher => @daily_deal_1.publisher, :advertiser => @daily_deal_1.advertiser)
          @market_1 = Factory(:market, :publisher => @daily_deal_1.publisher);
          @market_2 = Factory(:market, :publisher => @daily_deal_1.publisher);
          @daily_deal_1.markets << @market_1
          @daily_deal_1.markets << @market_2
          @daily_deal_2.markets << @market_1

          @ddp_1 = Factory(:captured_daily_deal_purchase_no_certs,
                           :daily_deal => @daily_deal_1,
                           :quantity => 3,
                           :executed_at => @report_date_begin + 4.days,
                           :market => @market_1)

          @ddp_2 = Factory(:captured_daily_deal_purchase_no_certs,
                           :daily_deal => @daily_deal_1,
                           :quantity => 1,
                           :executed_at => @report_date_begin + 4.days,
                           :market => @market_2)

          Factory(:daily_deal_certificate, :serial_number => "serial1", :daily_deal_purchase => @ddp_1)
          Factory(:daily_deal_certificate, :serial_number => "serial2", :daily_deal_purchase => @ddp_1)
          Factory(:daily_deal_certificate, :serial_number => "serial3", :daily_deal_purchase => @ddp_1)
          Factory(:daily_deal_certificate, :serial_number => "serial4", :daily_deal_purchase => @ddp_2)
          @refunded_purchase_1 = Factory(:refunded_daily_deal_purchase,
                                         :daily_deal => @daily_deal_1,
                                         :executed_at => @report_date_begin + 1.days,
                                         :refunded_at => @report_date_begin + 1.days,
                                         :market => @market_1)
          @refunded_purchase_2 = Factory(:refunded_daily_deal_purchase,
                                         :daily_deal => @daily_deal_1,
                                         :executed_at => @report_date_begin + 2.days,
                                         :refunded_at => @report_date_begin + 1.days,
                                         :market => @market_1)
          @refunded_purchase_3 = Factory(:refunded_daily_deal_purchase,
                                         :daily_deal => @daily_deal_2,
                                         :executed_at => @report_date_begin + 2.days,
                                         :refunded_at => @report_date_begin + 1.days,
                                         :market => @market_1)
          @refunded_cert_1 = @refunded_purchase_1.daily_deal_certificates.first
          @refunded_cert_2 = @refunded_purchase_2.daily_deal_certificates.first
          @refunded_cert_3 = @refunded_purchase_3.daily_deal_certificates.first
          Factory(:refunded_daily_deal_purchase,
                  :daily_deal => @daily_deal_1                           ,
                  :executed_at => @report_date_begin + 2.days,
                  :refunded_at => @report_date_begin + 1.days)
        end

        should "should render xml with certificates in market" do

          login_as Factory(:admin)
          get  :refunded_daily_deals,
               :format => "xml",
               :id => @daily_deal_1.advertiser.to_param,
               :market_id => @market_1.to_param,
               :dates_begin => @report_date_begin.to_formatted_s(:db_date),
               :dates_end => @report_date_end.to_formatted_s(:db_date)
          assert_response :success

          assert_select "daily_deal_certificate[daily_deal_certificate_id='#{@refunded_cert_1.id}']" do
            assert_select "customer_name", @refunded_purchase_1.consumer.name
            assert_select "recipient_name", @refunded_cert_1.redeemer_name
            assert_select "serial_number", @refunded_cert_1.serial_number
            assert_select "currency_symbol", "$"
            assert_select "store_name", @refunded_cert_1.store_name
            assert_select "value_proposition", "deal_1"
            assert_select "value", "30.0"
            assert_select "price", "15.0"
            assert_select "refund_amount", "15.00"
            assert_select "refund_date", @refunded_purchase_1.refunded_at.to_formatted_s(:db_date)
          end

          assert_select "daily_deal_certificate[daily_deal_certificate_id='#{@refunded_cert_2.id}']" do
            assert_select "customer_name", @refunded_purchase_2.consumer.name
            assert_select "recipient_name", @refunded_cert_2.redeemer_name
            assert_select "serial_number", @refunded_cert_2.serial_number
            assert_select "currency_symbol", "$"
            assert_select "store_name", @refunded_cert_2.store_name
            assert_select "value_proposition", "deal_1"
            assert_select "value", "30.0"
            assert_select "price", "15.0"
            assert_select "refund_amount", "15.00"
            assert_select "refund_date", @refunded_purchase_2.refunded_at.to_formatted_s(:db_date)
          end

          assert_select "daily_deal_certificate[daily_deal_certificate_id='#{@refunded_cert_3.id}']" do
            assert_select "customer_name", @refunded_purchase_3.consumer.name
            assert_select "recipient_name", @refunded_cert_3.redeemer_name
            assert_select "serial_number", @refunded_cert_3.serial_number
            assert_select "currency_symbol", "$"
            assert_select "store_name", @refunded_cert_3.store_name
            assert_select "value_proposition", "deal_2"
            assert_select "value", "30.0"
            assert_select "price", "15.0"
            assert_select "refund_amount", "15.00"
            assert_select "refund_date", @refunded_purchase_3.refunded_at.to_formatted_s(:db_date)
          end

        end

        should "should render csv with certificates in market" do
          login_as Factory(:admin)
          get  :refunded_daily_deals,
               :format => "csv",
               :id => @daily_deal_1.advertiser.to_param,
               :market_id => @market_1.to_param,
               :dates_begin => @report_date_begin.to_formatted_s(:db_date),
               :dates_end => @report_date_end.to_formatted_s(:db_date)
          assert_response :success

          csv = FasterCSV.new(@response.binary_content)
          assert_equal [
                         "Purchaser Name",
                         "Recipient Name",
                         "Serial Number",
                         "Deal",
                         "Value",
                         "Price",
                         "Refund Amount",
                         "Refund Date"
                       ], csv.shift, "CSV headers"

          row = csv.shift
          assert_equal @refunded_purchase_1.consumer.name, row[0]
          assert_equal @refunded_cert_1.redeemer_name, row[1]
          assert_equal @refunded_cert_1.serial_number, row[2]
          assert_equal "deal_1", row[3]
          assert_equal "$30.00", row[4]
          assert_equal "$15.00", row[5]
          assert_equal "$15.00", row[6]
          assert_equal "03/02/11", row[7]

          row = csv.shift
          assert_equal @refunded_purchase_2.consumer.name, row[0]
          assert_equal @refunded_cert_2.redeemer_name, row[1]
          assert_equal @refunded_cert_2.serial_number, row[2]
          assert_equal "deal_1", row[3]
          assert_equal "$30.00", row[4]
          assert_equal "$15.00", row[5]
          assert_equal "$15.00", row[6]
          assert_equal "03/02/11", row[7]

          row = csv.shift
          assert_equal @refunded_purchase_3.consumer.name, row[0]
          assert_equal @refunded_cert_3.redeemer_name, row[1]
          assert_equal @refunded_cert_3.serial_number, row[2]
          assert_equal "deal_2", row[3]
          assert_equal "$30.00", row[4]
          assert_equal "$15.00", row[5]
          assert_equal "$15.00", row[6]
          assert_equal "03/02/11", row[7]
        end

      end

      private

      def setup_with_user(user)
        @controller = nil
        setup_controller_request_and_response
        @request.session[:user_id] = user.try(:id)
      end

      def get_index_with_default_or_given_dates(user, time, dates)
        db, de = [dates.begin, dates.end].map { |date| date.strftime("%B %d, %Y") }
        params = { :publisher_id => @publisher.to_param }
        default_dates = (time.to_date - 7.days) .. time.to_date

        Time.zone.expects(:now).at_least_once.returns(time)

        setup_with_user user
        action = proc { get :index, params }
        yield action, "get with default dates", default_dates

        setup_with_user user
        action = proc { get :index, params.merge(:dates_begin => db, :dates_end => de) }
        yield action, "get with given dates", dates
      end

      def xhr_index_with_default_or_given_dates(user, time, dates)
        db, de = [dates.begin, dates.end].map { |date| date.strftime("%B %d, %Y") }
        params = { :publisher_id => @publisher.to_param, :format => "xml", :filter => "web" }
        default_dates = (time.to_date - 7.days) .. time.to_date

        Time.zone.expects(:now).at_least_once.returns(time)

        setup_with_user user
        action = proc { xhr :get, :index, params }
        yield action, "xhr with default dates", default_dates

        setup_with_user user
        action = proc { xhr :get, :index, params.merge(:dates_begin => db, :dates_end => de) }
        yield action, "xhr with given dates", dates
      end

    end
  end
end

