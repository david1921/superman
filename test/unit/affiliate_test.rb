require File.dirname(__FILE__) + "/../test_helper"

class AffiliateTest < ActiveSupport::TestCase
  should belong_to(:publisher)
  should validate_presence_of(:publisher)

  test "cannot create administrator" do
    affiliate = Factory(:affiliate)
    publisher = affiliate.publisher

    assert !affiliate.administrator?, "Affiliate should not be an administrator"
    
    affiliate.attributes = { :company => publisher, :admin_privilege => User::FULL_ADMIN }
    assert_nil affiliate.company, "Should not be able to set company via mass assignment"
    assert !affiliate.has_admin_privilege?, "Should not be able to set admin privilege via mass assignment"
    assert !affiliate.administrator?, "Affiliate should not be an administrator"
    
    affiliate.company = publisher
    affiliate.admin_privilege = User::FULL_ADMIN
    assert_nil affiliate.company, "Should not be able to set company via assignment"
    assert !affiliate.has_admin_privilege?, "Should not be able to set admin privilege via assignment"
    assert !affiliate.administrator?, "Affiliate should not be an administrator"
  end

  test "create affiliate_code before save" do
    affiliate = Factory.build(:affiliate)
    assert !affiliate.affiliate_code, "Affiliate should not have an affiliate code before create"
    affiliate.save
    assert affiliate.affiliate_code, "Affiliate should have an affiliate code"
  end

  test "url_for_daily_deal" do
    publisher  = Factory(:publisher, :production_daily_deal_host => "deals.test.com")
    affiliate  = Factory(:affiliate, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :publisher => publisher)

    url = "http://deals.test.com/daily_deals/#{daily_deal.id}?affiliate_code=#{affiliate.affiliate_code}"

    assert_equal url, affiliate.url_for_daily_deal(daily_deal)
  end

  test "daily_deals" do
    daily_deal = Factory(:daily_deal, :affiliate_revenue_share_percentage => 2)
    publisher = daily_deal.publisher
    daily_deal2 = Factory(:daily_deal, :publisher => publisher, :start_at => 3.days.ago, :hide_at => 2.days.ago)
    affiliate  = Factory(:affiliate, :publisher => publisher)

    assert_equal [daily_deal], affiliate.daily_deals
  end

end
