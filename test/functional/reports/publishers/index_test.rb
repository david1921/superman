require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Reports::Publishers::IndexTest

module Reports
  module Publishers
    class IndexTest < ActionController::TestCase
      tests Reports::PublishersController

      test "index with default dates as admin user by get" do
        publishers = Publisher.all
        assert 0 < publishers.size, "Should have some publisher fixtures"

        Time.expects(:now).at_least_once.returns Time.parse("Oct 4, 2008 12:34:56")

        with_user_required(:aaron) do
          get :index, :summary => "web_offers"
        end
        assert_response :success
        assert_equal publishers, assigns(:publishers), "@publishers assignment"
        assert_equal Date.new(2008, 9, 1) .. Date.new(2008, 9, 30), assigns(:dates), "@dates assignment"
      end

      test "index with default dates as admin user by xhr" do
        publishers = Publisher.all
        assert 0 < publishers.size, "Should have some publisher fixtures"

        Time.expects(:now).at_least_once.returns Time.parse("Oct 4, 2008 12:34:56")

        with_user_required(:aaron, :format => :xml) do
          xhr :get, :index, :format => "xml", :summary => "web_offers"
        end
        assert_response :success
        assert_equal publishers, assigns(:publishers), "@publishers assignment"
        assert_equal Date.new(2008, 9, 1) .. Date.new(2008, 9, 30), assigns(:dates), "@dates assignment"
      end

      test "index with given dates as admin user by get" do
        publishers = Publisher.all
        assert 0 < publishers.size, "Should have some publisher fixtures"

        Time.expects(:now).at_least(0).returns Time.parse("Oct 4, 2008 12:34:56")

        with_user_required(:aaron) do
          get :index, :dates_begin => "July 1, 2008", :dates_end => "July 31, 2008", :summary => "web_offers"
        end
        assert_response :success
        assert_equal publishers, assigns(:publishers), "@publishers assignment"
        assert_equal Date.new(2008, 7, 1) .. Date.new(2008, 7, 31), assigns(:dates), "@dates assignment"
      end

      test "index with given dates as admin user by xhr" do
        publishers = Publisher.all
        assert 0 < publishers.size, "Should have some publisher fixtures"

        Time.expects(:now).at_least(0).returns Time.parse("Oct 4, 2008 12:34:56")

        with_user_required(:aaron, :format => :xml) do
          xhr :get, :index, :dates_begin => "July 1, 2008", :dates_end => "July 31, 2008", :summary => "web_offers"
        end
        assert_response :success
        assert_equal publishers, assigns(:publishers), "@publishers assignment"
        assert_equal Date.new(2008, 7, 1) .. Date.new(2008, 7, 31), assigns(:dates), "@dates assignment"
      end

      test "index with default dates as publishing group user by get" do
        group = publishing_groups(:student_discount_handbook)
        user = User.all.detect { |user| group == user.company }
        assert_not_nil user, "Publishing group fixture should have a user"

        2.times { |i| group.publishers.create! :name => "Publisher #{i}" }
        publisher_ids = group.publishers(true).map(&:id).sort
        assert 2 <= publisher_ids.size, "Should have at least 2 publishers in group"
        assert_not_nil Publisher.all.detect { |p| !publisher_ids.include?(p.id) }, "Should have some publishers not in group"

        Time.expects(:now).at_least_once.returns Time.parse("Oct 4, 2008 12:34:56")

        @request.session[:user_id] = user
        get :index, :summary => "web_offers"

        assert_response :success
        assert_equal publisher_ids, assigns(:publishers).map(&:id).sort, "@publishers assignment"
        assert_equal Date.new(2008, 9, 1) .. Date.new(2008, 9, 30), assigns(:dates), "@dates assignment"
      end

      test "index with default dates as publishing group user by xhr" do
        group = Factory(:publishing_group)
        user = create_user_with_company :company => group

        publisher = Factory(:publisher, :publishing_group_id => group.id)
        publisher2 = Factory(:publisher, :publishing_group_id => group.id)
        advertiser = Factory(:advertiser, :publisher => publisher)
        advertiser2 = Factory(:advertiser, :publisher => publisher2)

        Factory(:click_count_daily_deal, :publisher => publisher)
        Factory(:click_count_daily_deal, :mode => "facebook", :publisher => publisher)

        offer = Factory(:offer, :advertiser => advertiser, :show_on => Date.new(2008, 9, 5), :expires_on => Date.new(2008, 9, 20))
        twitter_click_count = Factory(:click_count_offer, :publisher => publisher, :clickable => offer)
        facebook_click_count = Factory(:click_count_offer, :mode => "facebook", :publisher => publisher)

        Factory(:placement, :publisher => publisher, :offer => twitter_click_count.clickable)

        Timecop.freeze(Time.zone.local(2008, 10, 4, 12, 34, 56)) do
          login_as user
          xhr :get, :index, :format => "xml", :summary => "web_offers"

          assert_response :success
          assert_same_elements [publisher, publisher2], assigns(:publishers), "@publishers assignment"
          assert_equal Date.new(2008, 9, 1) .. Date.new(2008, 9, 30), assigns(:dates), "@dates assignment"

          body = Hash.from_xml(@response.body)

          assert_equal facebook_click_count.count.to_s, body['publishers']['publisher']['facebooks_count']
          assert_equal twitter_click_count.count.to_s, body['publishers']['publisher']['twitters_count']
        end
      end

      test "index with given dates as publishing group user by get" do
        group = publishing_groups(:student_discount_handbook)
        user = User.all.detect { |user| group == user.company }
        assert_not_nil user, "Publishing group fixture should have a user"

        2.times { |i| group.publishers.create! :name => "Publisher #{i}" }
        publisher_ids = group.publishers(true).map(&:id).sort
        assert 2 <= publisher_ids.size, "Should have at least 2 publishers in group"
        assert_not_nil Publisher.all.detect { |p| !publisher_ids.include?(p.id) }, "Should have some publishers not in group"

        Time.expects(:now).at_least(0).returns Time.parse("Oct 4, 2008 12:34:56")

        @request.session[:user_id] = user
        get :index, :dates_begin => "July 1, 2008", :dates_end => "July 31, 2008", :summary => "web_offers"

        assert_response :success
        assert_equal publisher_ids, assigns(:publishers).map(&:id).sort, "@publishers assignment"
        assert_equal Date.new(2008, 7, 1) .. Date.new(2008, 7, 31), assigns(:dates), "@dates assignment"
      end

      test "index with given dates as publishing group user by xhr" do
        group = publishing_groups(:student_discount_handbook)
        user = User.all.detect { |user| group == user.company }
        assert_not_nil user, "Publishing group fixture should have a user"

        2.times { |i| group.publishers.create! :name => "Publisher #{i}" }
        publisher_ids = group.publishers(true).map(&:id).sort
        assert 2 <= publisher_ids.size, "Should have at least 2 publishers in group"
        assert_not_nil Publisher.all.detect { |p| !publisher_ids.include?(p.id) }, "Should have some publishers not in group"

        Time.expects(:now).at_least(0).returns Time.parse("Oct 4, 2008 12:34:56")

        @request.session[:user_id] = user
        xhr :get, :index, :dates_begin => "July 1, 2008", :dates_end => "July 31, 2008", :summary => "web_offers"

        assert_response :success
        assert_equal publisher_ids, assigns(:publishers).map(&:id).sort, "@publishers assignment"
        assert_equal Date.new(2008, 7, 1) .. Date.new(2008, 7, 31), assigns(:dates), "@dates assignment"
      end

      test "index as publisher user" do
        Time.expects(:now).at_least_once.returns Time.parse("Oct 4, 2008 12:34:56")

        with_user_required(:pam) do
          get :index, :summary => "web_offers"
        end
        assert_redirected_to root_path
      end

      test "index as advertiser user" do
        Time.expects(:now).at_least_once.returns Time.parse("Oct 4, 2008 12:34:56")

        with_user_required(:jorge) do
          get :index, :summary => "web_offers"
        end
        assert_redirected_to root_path
      end

    end
  end
end

