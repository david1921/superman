require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::UpdateTest < ActionController::TestCase
  tests DailyDealsController
  include DailyDealHelper

  def setup
    @valid_attributes = self.class.get_valid_attributes
  end

  def teardown
    User.current = nil unless User.current.nil?
  end

  def self.get_valid_attributes
    {
        :value_proposition => "$25 value for $12.99",
        :description => "This is a daily deal. Enjoy!",
        :terms => "These are the terms. Obey!",
        :quantity => 100,
        :min_quantity => 1,
        :price => 12.99,
        :value => 25.00,
        :start_at => 10.days.ago,
        :hide_at => Time.zone.now.tomorrow,
        :upcoming => true,
        :account_executive => "Bob Mann"
    }
  end

  test "update with valid attributes" do
    advertiser = advertisers(:changos)
    daily_deal = advertiser.daily_deals.create!(@valid_attributes.merge(:affiliate_revenue_share_percentage => 23))
    user = Factory(:admin)
    login_as user
    post :update, :advertiser_id => advertiser.to_param, :id => daily_deal.to_param,
      :daily_deal => {
        :description => "New Description",
        :affiliate_revenue_share_percentage => "",
        :advertiser_credit_percentage => 2
      }
    assert_redirected_to edit_daily_deal_path(daily_deal)
    daily_deal.reload
    assert_equal "New Description", daily_deal.description_plain
    assert_nil daily_deal.affiliate_revenue_share_percentage
    assert_equal 2.0, daily_deal.advertiser_credit_percentage
    assert_equal true, daily_deal.upcoming
    assert_equal advertiser, daily_deal.advertiser

  end

  test "update with invalid attributes" do
    advertiser = advertisers(:changos)
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)
    user = Factory(:admin)
    login_as user
    post :update, :id => daily_deal.to_param, :daily_deal => {:price => ""}
    assert_template :edit
    assert !assigns(:daily_deal).errors.empty?
  end

  test "update without bit ly url" do
    advertiser = advertisers(:changos)
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)
    DailyDeal.connection.execute "update daily_deals set bit_ly_url=NULL where id=#{daily_deal.id}"
    daily_deal = DailyDeal.find(daily_deal.id)
    assert_nil daily_deal.bit_ly_url, "bit_ly_url"
    user = Factory(:admin)
    login_as user
    post :update, :id => daily_deal.to_param, :daily_deal => {:description => "New Description"}
    assert_redirected_to edit_daily_deal_path(daily_deal)
    assert_equal "New Description", daily_deal.reload.description_plain
    assert_equal advertiser, daily_deal.reload.advertiser
  end

  test "update with new bar codes assigned and existing unassigned bar codes not deleted" do
    daily_deal = Factory(:daily_deal, :quantity => 2)
    daily_deal.bar_codes.create!(:code => "0123", :assigned => true)
    daily_deal.bar_codes.create!(:code => "4567")
    assert_equal 2, daily_deal.bar_codes.count, "Should have two bar codes assigned"
    assert daily_deal.valid?, "Should be valid with quantity two and two bar codes"

    login_as :aaron
    csv_stream = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/bar_codes.csv", 'text/csv')
    put :update, :advertiser_id => daily_deal.advertiser.to_param, :id => daily_deal.to_param, :daily_deal => {
      :bar_codes_csv => csv_stream,
      :delete_existing_unassigned_bar_codes => "0",
      :allow_duplicate_bar_codes => "0"
    }
    assert_redirected_to edit_daily_deal_path(daily_deal)

    assert daily_deal.reload.valid?
    assert_equal 4, daily_deal.bar_codes.count, "Should have two new bar codes"
    assert_equal 4, daily_deal.quantity, "Quantity should include new bar codes"
    assert_equal %w{ 0123 4567 89ab cdef }, daily_deal.bar_codes(true).map(&:code).sort
  end

  test "update with new bar codes assigned and existing unassigned bar codes deleted" do
    daily_deal = Factory(:daily_deal, :quantity => 2)
    daily_deal.bar_codes.create!(:code => "0123", :assigned => true)
    daily_deal.bar_codes.create!(:code => "4567")
    assert_equal 2, daily_deal.bar_codes.count, "Should have two bar codes assigned"
    assert daily_deal.valid?, "Should be valid with quantity two and two bar codes"

    login_as :aaron
    csv_stream = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/bar_codes.csv", 'text/csv')
    put :update, :advertiser_id => daily_deal.advertiser.to_param, :id => daily_deal.to_param, :daily_deal => {
      :bar_codes_csv => csv_stream,
      :delete_existing_unassigned_bar_codes => "1",
      :allow_duplicate_bar_codes => "0"
    }
    assert_redirected_to edit_daily_deal_path(daily_deal)

    assert daily_deal.reload.valid?
    assert_equal 3, daily_deal.bar_codes.count, "Should have two new bar codes and one deleted"
    assert_equal 3, daily_deal.quantity, "Quantity should include new and deleted bar codes"
    assert_equal %w{ 0123 89ab cdef }, daily_deal.bar_codes(true).map(&:code).sort
  end

  test "update with new bar codes assigned and not allowing duplicates" do
    daily_deal = Factory(:daily_deal, :quantity => 2)
    daily_deal.bar_codes.create!(:code => "89ab", :assigned => true)
    daily_deal.bar_codes.create!(:code => "cdef")
    assert_equal 2, daily_deal.bar_codes.count, "Should have two bar codes assigned"
    assert daily_deal.valid?, "Should be valid with quantity two and two bar codes"

    login_as :aaron
    csv_stream = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/bar_codes.csv", 'text/csv')
    put :update, :advertiser_id => daily_deal.advertiser.to_param, :id => daily_deal.to_param, :daily_deal => {
      :bar_codes_csv => csv_stream,
      :delete_existing_unassigned_bar_codes => "0",
      :allow_duplicate_bar_codes => "0"
    }
    assert_redirected_to edit_daily_deal_path(daily_deal)

    assert daily_deal.reload.valid?
    assert_equal 2, daily_deal.bar_codes.count, "Should not have any new bar codes"
    assert_equal 2, daily_deal.quantity, "Quantity should not change"
    assert_equal %w{ 89ab cdef }, daily_deal.bar_codes(true).map(&:code).sort
  end

  test "update with new bar codes assigned and allowing duplicates" do
    daily_deal = Factory(:daily_deal, :quantity => 2)
    daily_deal.bar_codes.create!(:code => "89ab", :assigned => true)
    daily_deal.bar_codes.create!(:code => "cdef")
    assert_equal 2, daily_deal.bar_codes.count, "Should have two bar codes assigned"
    assert daily_deal.valid?, "Should be valid with quantity two and two bar codes"

    login_as :aaron
    csv_stream = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/bar_codes.csv", 'text/csv')
    put :update, :advertiser_id => daily_deal.advertiser.to_param, :id => daily_deal.to_param, :daily_deal => {
      :bar_codes_csv => csv_stream,
      :delete_existing_unassigned_bar_codes => "0",
      :allow_duplicate_bar_codes => "1"
    }
    assert_redirected_to edit_daily_deal_path(daily_deal)

    assert daily_deal.reload.valid?
    assert_equal 4, daily_deal.bar_codes.count, "Should have two new bar codes"
    assert_equal 4, daily_deal.quantity, "Quantity should reflect new bar codes"
    assert_equal %w{ 89ab 89ab cdef cdef }, daily_deal.bar_codes(true).map(&:code).sort
  end

  context "updating a daily deal's start_at whose publisher is in the Eastern time zone" do

    setup do
      save_current_time_zone
      Time.zone = nil
      setup_deal_with_publisher_in_time_zone
      @daily_deal.update_attribute(:start_at, 2.days.from_now) # to avoid the lock on start_at date
      put :update, :advertiser_id => @advertiser.id, :id => @daily_deal.to_param, :daily_deal => { :start_at => "June 12, 2010 09:00 AM" }
    end

    should respond_with :redirect

    should "update the deal start_at value in the publisher's time zone" do
      @daily_deal.reload
      assert_equal "2010-06-12 13:00:00", @daily_deal.start_at_before_type_cast
    end

    teardown do
      restore_saved_time_zone
    end

  end

  context "updating a daily deal's hide_at whose publisher is in the Eastern time zone" do

    setup do
      save_current_time_zone
      Time.zone = nil
      setup_deal_with_publisher_in_time_zone
      put :update, :advertiser_id => @advertiser.id, :id => @daily_deal.to_param, :daily_deal => { :hide_at => "June 20, 2010 09:00 PM" }
    end

    should respond_with :redirect

    should "update the hide_at value in the publisher's time zone" do
      @daily_deal.reload
      assert_equal "2010-06-21 01:00:00", @daily_deal.hide_at_before_type_cast
    end

    teardown do
      restore_saved_time_zone
    end

  end

  context "syndication restricted to publishing group" do
    setup do
      publishing_group = Factory(:publishing_group, :restrict_syndication_to_publishing_group => true)
      @publisher1 = Factory(:publisher, :publishing_group => publishing_group)
      @publisher2 = Factory(:publisher, :publishing_group => publishing_group)
      @daily_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher1)
    end

    should "syndicate to publishers given syndicated_deal_publisher_ids" do
      assert_equal [], @daily_deal.syndicated_deal_publisher_ids

      login_as Factory(:admin)
      put :update, :advertiser_id => @daily_deal.advertiser_id, :id => @daily_deal.to_param,
        :daily_deal => {:syndicated_deal_publisher_ids => [@publisher2.id]}

      assert_equal [@publisher2.id], @daily_deal.reload.syndicated_deal_publisher_ids
    end

    should "set syndicated_deal_publisher_ids to [] if not found in params" do
      @daily_deal.syndicated_deals.build(:publisher_id => @publisher2.id)
      @daily_deal.save!

      assert_equal [@publisher2.id], @daily_deal.syndicated_deal_publisher_ids

      login_as Factory(:admin)
      put :update, :advertiser_id => @daily_deal.advertiser_id, :id => @daily_deal.to_param, :daily_deal => {}

      assert_equal [], @daily_deal.reload.syndicated_deal_publisher_ids
    end
  end

  context "syndication not restricted to publishing group" do
    should "NOT set syndicated_deal_publisher_ids to [] if not found in params" do
      publisher1 = Factory(:publisher)
      publisher2 = Factory(:publisher)
      daily_deal = Factory(:daily_deal_for_syndication, :publisher => publisher1)

      daily_deal.syndicated_deals.build(:publisher_id => publisher2.id)
      daily_deal.save!

      assert_equal [publisher2.id], daily_deal.syndicated_deal_publisher_ids

      login_as Factory(:admin)
      put :update, :advertiser_id => daily_deal.advertiser_id, :id => daily_deal.to_param, :daily_deal => {}

      assert_equal [publisher2.id], daily_deal.reload.syndicated_deal_publisher_ids
    end
  end

  test "updates email_voucher_offer" do
    dd = Factory(:daily_deal)
    offer = Factory(:offer, :advertiser => dd.advertiser)
    assert_nil dd.email_voucher_offer

    login_as Factory(:admin)
    put :update, :advertiser_id => dd.advertiser_id, :id => dd.id, :daily_deal => { :email_voucher_offer_id => offer.id }
    assert_redirected_to edit_daily_deal_path(dd)

    dd.reload
    assert_equal offer, dd.email_voucher_offer
  end

  private

  def setup_deal_with_publisher_in_time_zone(time_zone = "Eastern Time (US & Canada)")
    @publisher_in_time_zone = Factory(:publisher, :time_zone => time_zone)
    @advertiser = Factory(:advertiser, :publisher_id => @publisher_in_time_zone.id)
    @daily_deal = Factory(:daily_deal,
                          :advertiser_id => @advertiser.id,
                          :start_at => "2010-06-14 07:00:00 UTC",
                          :hide_at => "2010-06-15 02:00:00 UTC",
                          :expires_on => "2010-12-31")
    @admin_user = Factory(:admin)
    @controller.stubs(:current_user).returns(@admin_user)
  end

  def save_current_time_zone
    @original_tz = Time.zone
  end

  def restore_saved_time_zone
    Time.zone = @original_tz
  end

end
