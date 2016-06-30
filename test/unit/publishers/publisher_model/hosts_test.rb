require File.dirname(__FILE__) + "/../../../test_helper"

class Publishers::HostsTest < ActiveSupport::TestCase
  context "#host" do
    should "return default production host when production_host == nil" do
      Rails.env.stubs(:production?).returns(true)
      publisher = Factory(:publisher, :name => "Publisher", :production_subdomain => "sb1")
      assert_equal "sb1", publisher.production_subdomain
      assert_equal "sb1.analoganalytics.com", publisher.host
    end

    should "return production_host in production when production_host != nil" do
      Rails.env.expects(:production?).returns(true)
      publisher = Factory(:publisher, :name => "Publisher", :production_subdomain => "sb1", :production_host => "coupons.publisher.com")
      assert_equal "sb1", publisher.production_subdomain
      assert_equal "coupons.publisher.com", publisher.host
    end
  end

  context "#daily_deal_host" do
    should "return default daily deal host in production when production_daily_deal_host == nil" do
      Rails.env.stubs(:production?).returns(true)
      publisher = Factory(:publisher, :name => "Publisher", :production_subdomain => "sb1")
      assert_equal "sb1", publisher.production_subdomain
      assert_equal "sb1.analoganalytics.com", publisher.host
      assert_equal "sb1.analoganalytics.com", publisher.daily_deal_host
    end

    should "return production_daily_deal_host in production when production_daily_deal_host != nil" do
      Rails.env.stubs(:production?).returns(true)
      publisher = Factory(:publisher, 
          :name => "Publisher",
          :production_subdomain => "sb1",
          :production_host => "coupons.publisher.com",
          :production_daily_deal_host => "deals.publisher.com"
      )
      assert_equal "sb1", publisher.production_subdomain
      assert_equal "coupons.publisher.com", publisher.host
      assert_equal "deals.publisher.com", publisher.daily_deal_host
    end
  end

  context "#asset_host" do

    should "return AA host with production_subdomain in production" do
      publisher = publishers(:sdh_austin)

      publisher.production_subdomain = nil
      assert_equal "sb1.analoganalytics.com", publisher.asset_host

      publisher.production_subdomain = "sb2"
      assert_equal "sb2.analoganalytics.com", publisher.asset_host

      publisher.production_host = "coupons.sdhaustin.com"
      assert_equal "sb2.analoganalytics.com", publisher.asset_host
    end
  end
end
