module ReportsTestHelper
  def self.included(base)
    base.send :extend,  ClassMethods
    base.send :include, InstanceMethods
  end

  module InstanceMethods
    def stub_host_as_admin_server
      Rails.env.stubs(:production?).returns(true)
      @request.stubs(:subdomains).returns(['admin'])
      @request.stubs(:host_with_port).returns('admin.analoganalytics.com')
    end

    def stub_host_as_reports_server
      Rails.env.stubs(:production?).returns(true)
      @request.stubs(:subdomains).returns(['reports'])
      @request.stubs(:host_with_port).returns('reports.analoganalytics.com')
    end

    # used to assert the correct data for a row in the 
    # Publisher#daily_deals_summary report.
    def assert_daily_deals_summary_row(row, data = {})
      assert_equal data[:start_at], row.start_at.strftime("%Y-%m-%d"), "start_at"
      assert_equal data[:hide_at], row.hide_at.strftime("%Y-%m-%d"), "hide_at"        
      assert_equal data[:source_publisher], row.source_publisher.try(:name), "source_publisher"
      assert_equal data[:advertiser], row.advertiser_name, "advertiser"
      assert_equal data[:advertiser_listing], row.advertiser.try(:listing), "advertiser_listing"
      assert_equal data[:value_proposition], row.daily_deal_or_variation_value_proposition, "value_proposition"
      assert_equal data[:listing], row.daily_deal_or_variation_listing, "listing"
      assert_equal data[:total_purchases], row.daily_deal_purchases_total_quantity.to_i, "total_purchases"
      assert_equal data[:total_purchasers], row.daily_deal_purchasers_count.to_i, "total_purchasers"
      assert_equal data[:purchases_gross], row.daily_deal_purchases_gross.to_i, "purchase_gross"
      assert_equal data[:discount], row.daily_deal_purchases_gross - row.daily_deal_purchases_amount, "discount"
      assert_equal data[:refunds_quantity], row.daily_deal_refunded_voucher_count, "refunds_quantity"
      assert_equal data[:refunds_amount], row.daily_deal_refunds_total_amount, "refunds_amount"
      assert_equal data[:purchases_amount], row.daily_deal_purchases_amount.to_i, "purchases_amount"
      assert_equal data[:account_executive], row.account_executive, "account_executive"
      assert_equal data[:advertiser_revenue_share_percentage], row.advertiser_revenue_share_percentage, "advertiser_revenue_share_percentage"
      assert_equal data[:advertiser_credit_percentage], row.advertiser_credit_percentage, "advertiser_credit_percentage"
      assert_equal data[:custom_1], row.custom_1
      assert_equal data[:custom_2], row.custom_2
      assert_equal data[:custom_3], row.custom_3
    end  
      
  end

  module ClassMethods
    def should_redirect_to_reports_server_for(action)
      should "redirect #{action} report to reports.aa.com" do
        get action
        assert_response :redirect
        assert_match /^https?:\/\/reports\.analoganalytics\.com/, @response.headers['Location']
      end
    end

    def should_redirect_to_admin_server_for(action)
      should "redirect #{action} to admin.aa.com" do
        get action
        assert_response :redirect
        assert_match /^https?:\/\/admin\.analoganalytics\.com/, @response.headers['Location']
      end
    end
  end
end
