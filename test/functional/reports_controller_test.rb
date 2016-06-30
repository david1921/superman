require File.dirname(__FILE__) + "/../test_helper"

class ReportsControllerTest < ActionController::TestCase
  setup :setup_mailer_expectation
  
  def setup_mailer_expectation
    GiftCertificateMailer.expects(:deliver_gift_certificate).at_least(0).returns(nil)    
  end

  context "when on admin.aa.com" do
    setup do
      stub_host_as_admin_server
      login_as Factory(:admin)
    end

    should_redirect_to_reports_server_for :purchased_gift_certificates
    should_redirect_to_reports_server_for :purchased_daily_deals
    should_redirect_to_reports_server_for :affiliated_daily_deals
    should_redirect_to_reports_server_for :refunded_daily_deals
  end

  context "#show" do
    should "require a login" do
      get :show
      assert_redirected_to new_session_path
    end

    should "redirect to reports publishers path when admin" do
      user = User.all.detect { |user| user.has_admin_privilege? }
      assert user, "Should have a user fixture with admin"
      @request.session[:user_id] = user

      get :show
      assert_redirected_to reports_publishers_path
    end

    should "redirect to reports publishers path when publishing group user" do
      user = User.all.detect { |user| user.company.is_a?(PublishingGroup) }
      assert user, "Should have a user fixture belonging to a publishing group"
      @request.session[:user_id] = user

      get :show
      assert_redirected_to reports_publishers_path
    end

    should "redirect to reports publishers path for user's company when a publisher user" do
      user = User.all.detect { |user| user.company.is_a?(Publisher) }
      assert user, "Should have a user fixture belonging to a publisher"
      @request.session[:user_id] = user

      get :show
      assert_redirected_to reports_publisher_path(user.company)
    end

    should "redirect to reports advertisers path when user is an advertiser" do
      user = User.all.detect { |user| user.company.is_a?(Advertiser) }
      assert user, "Should have a user fixture belonging to an advertiser"
      @request.session[:user_id] = user

      get :show
      assert_redirected_to reports_advertiser_path(user.company)
    end
  end

  context "#purchased_gift_certificates" do
    should "render csv of purchased deal certificates" do
      publisher = publishers(:sdh_austin)
      advertiser = publisher.advertisers.create(:name => "A1")
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

      login_as Factory.create(:admin)
      get :purchased_gift_certificates, {
        :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s,
        :format => "csv"
      }

      # This is required to actually execute the code that streams out
      # the CSV file. DO NOT REMOVE THIS LINE!
      @response.binary_content

      assert_response :success
    end

    should "render xml of purchased deal certificates with default begin and end dates" do
      login_as :aaron
      xhr :get, :purchased_gift_certificates, :format => "xml"

      # should default to last month
      last_month = Time.zone.now.prev_month
      assert_equal last_month.beginning_of_month, assigns(:dates).first
      assert_equal last_month.end_of_month, assigns(:dates).last
    end

    should "render xml of purchased deal certificates" do
      publisher = publishers(:sdh_austin)
      publisher.advertisers.destroy_all

      a_1 = publisher.advertisers.create(:name => "A1")
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
      a_2 = publisher.advertisers.create(:name => "A2")
      g_2_1 = a_2.gift_certificates.create!(
        :message => "A2G1",
        :value => 30.00,
        :price => 14.99,
        :show_on => "Nov 18, 2008",
        :expires_on => "Nov 20, 2008",
        :number_allocated => 30
      )

      publisher = publishers(:sdreader)
      publisher.advertisers.destroy_all

      a_3 = publisher.advertisers.create(:name => "A3")
      g_3_1 = a_3.gift_certificates.create!(
        :message => "A3G1",
        :value => 20.00,
        :price => 9.99,
        :show_on => "Nov 1, 2008",
        :expires_on => "Nov 30, 2008",
        :number_allocated => 20
      )
      g_3_2 = a_3.gift_certificates.create!(
        :message => "A3G2",
        :value => 100.00,
        :price => 49.99,
        :show_on => "Nov 15, 2008",
        :expires_on => "Nov 30, 2008",
        :number_allocated => 5
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

      purchase.call(24, g_2_1, "00:00:00 Nov 18, 2008 PST", "completed")
      purchase.call(25, g_2_1, "00:00:01 Nov 18, 2008 PST", "reversed")
      purchase.call(26, g_2_1, "12:34:56 Nov 18, 2008 PST", "completed")
      purchase.call(27, g_2_1, "00:00:00 Nov 19, 2008 PST", "completed")
      purchase.call(28, g_2_1, "12:34:56 Nov 19, 2008 PST", "completed")

      purchase.call(29, g_3_1, "00:00:00 Nov 15, 2008 PST", "completed")
      purchase.call(30, g_3_1, "12:34:56 Nov 15, 2008 PST", "reversed")
      purchase.call(31, g_3_1, "23:59:59 Nov 16, 2008 PST", "completed")
      purchase.call(32, g_3_1, "12:34:56 Nov 16, 2008 PST", "reversed")
      purchase.call(33, g_3_1, "23:59:59 Nov 17, 2008 PST", "completed")

      purchase.call(34, g_3_2, "00:00:00 Nov 16, 2008 PST", "reversed")
      purchase.call(35, g_3_2, "00:00:01 Nov 16, 2008 PST", "reversed")
      purchase.call(36, g_3_2, "12:34:56 Nov 16, 2008 PST", "completed")
      purchase.call(37, g_3_2, "23:59:59 Nov 16, 2008 PST", "refunded")
      purchase.call(38, g_3_2, "00:00:00 Nov 17, 2008 PST", "completed")
      purchase.call(39, g_3_2, "12:34:56 Nov 17, 2008 PST", "completed")
      purchase.call(40, g_3_2, "23:59:59 Nov 18, 2008 PST", "completed")

      login_as :aaron
      dates = Date.parse("Nov 16, 2008")..Date.parse("Nov 18, 2008")
      xhr :get, :purchased_gift_certificates, :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s, :format => "xml"

      records = Hash.from_xml(@response.body).try(:fetch, "purchased_gift_certificates").try(:fetch, "purchased_gift_certificate")
      assert_not_nil records, "Should have a list of purchased deal certificates"
      assert_equal 14, records.size
      %w{ 13 14 16 17 19 21 22 24 26 31 33 36 38 39 }.each_with_index do |s, i|
        record = records[i]
        assert_not_nil purchased_gift_certificate = PurchasedGiftCertificate.find_by_id(record["id"])

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
  end

  context "#purchased_daily_deals" do
    should "render xml with default begin and end dates" do
      login_as :aaron
      xhr :get, :purchased_daily_deals, :format => "xml"

      # should default to last 30 days
      now = Time.zone.now
      assert_equal((now - 30.days).beginning_of_day, assigns(:dates).first)
      assert_equal now.end_of_day, assigns(:dates).last
    end

    should "render xml" do
      sdh_austin = publishers(:sdh_austin)
      sdh_austin.advertisers.destroy_all

      ConsumerMailer.stubs(:deliver_activation_request)
      valid_user_attributes = {
        :email => "joe@blow.com",
        :name => "Joe Blow",
        :password => "secret",
        :password_confirmation => "secret",
        :agree_to_terms => "1"
      }
      c_1 = sdh_austin.consumers.create!( valid_user_attributes.merge(:email => "jon@hello.com", :name => "Jon Smith") )
      c_2 = sdh_austin.consumers.create!( valid_user_attributes.merge(:email => "jill@hello.com", :name => "Jill Smith") )
      c_3 = sdh_austin.consumers.create!( valid_user_attributes.merge(:email => "cheap@hello.com", :name => "Cheap Skate") )

      a_1 = sdh_austin.advertisers.create(:name => "A1")
      d_1_1 = a_1.daily_deals.create!(
        :value_proposition => "Daily Deal 1 For A1",
        :price => 39.00,
        :value => 81.00,
        :quantity => 100,
        :terms => "these are my terms",
        :description => "this is my description",
        :start_at => Time.zone.parse("Mar 02, 2009 12:00:00"),
        :hide_at  => Time.zone.parse("Mar 02, 2009 22:00:00")
      )

      p_1 = d_1_1.daily_deal_purchases.build
      p_1.discount = sdh_austin.discounts.create!(:amount => 10, :code => "yyz")
      p_1.quantity = 1
      p_1.consumer = c_1
      p_1.save!
      p_1.payment_status = "captured"
      p_1.executed_at = "Mar 02, 2009 14:34:56 PST"
      p_1.daily_deal_payment = BraintreePayment.new
      p_1.daily_deal_payment.payment_at = p_1.executed_at
      p_1.daily_deal_payment.payment_gateway_id = "301181650"
      p_1.daily_deal_payment.amount = "29.00"
      p_1.daily_deal_payment.credit_card_last_4 = "5555"
      p_1.daily_deal_payment.save!
      p_1.save!
      p_1.create_certificates!

      p_2 = d_1_1.daily_deal_purchases.build
      p_2.quantity = 3
      p_2.consumer = c_2
      p_2.save!
      p_2.payment_status = "captured"
      p_2.executed_at ="Mar 02, 2009 14:34:56 PST"
      p_2.daily_deal_payment = BraintreePayment.new
      p_2.daily_deal_payment.payment_gateway_id = "301181651"
      p_2.daily_deal_payment.amount = "117.00"
      p_2.daily_deal_payment.credit_card_last_4 = "5555"
      p_2.daily_deal_payment.payment_at = p_2.executed_at
      p_2.daily_deal_payment.save!
      p_2.save!
      p_2.create_certificates!

      d_1_2 = a_1.daily_deals.create!(
        :value_proposition => "Daily Deal 2 For A1",
        :price => 25.00,
        :value => 74.00,
        :quantity => 100,
        :terms => "these are my terms",
        :description => "this is my description",
        :start_at => Time.zone.parse("Mar 06, 2009 10:00:00"),
        :hide_at  => Time.zone.parse("Mar 06, 2009 23:00:00")
      )
      d_1_3 = a_1.daily_deals.create!(
        :value_proposition => "Daily Deal 3 For A1",
        :price => 35.00,
        :value => 50.00,
        :quantity => 100,
        :terms => "these are my terms",
        :description => "this is my description",
        :start_at => Time.zone.parse("Mar 08, 2009 09:00:00"),
        :hide_at => Time.zone.parse("Mar 08, 2009 19:00:00")
      )
      a_2 = sdh_austin.advertisers.create!(:name => "A2")
      d_2_1 = a_2.daily_deals.create!(
        :value_proposition => "Daily Deal 1 For A2",
        :price => 35.00,
        :value => 50.00,
        :quantity => 100,
        :terms => "these are my terms",
        :description => "this is my description",
        :start_at => Time.zone.parse("Mar 03, 2009 09:00:00"),
        :hide_at => Time.zone.parse("Mar 03, 2009 23:00:00")
      )

      sdreader = publishers(:sdreader)
      sdreader.advertisers.destroy_all

      a_3 = sdreader.advertisers.create!( :name => "A3" )
      d_3_1 = a_3.daily_deals.create!(
        :value_proposition => "Daily Deal 2 For A1",
        :price => 25.00,
        :value => 74.00,
        :quantity => 100,
        :terms => "these are my terms",
        :description => "this is my description",
        :start_at => Time.zone.parse("Feb 28, 2009 06:00:00"),
        :hide_at  => Time.zone.parse("Feb 28, 2009 23:00:00")
      )
      d_3_2 = a_3.daily_deals.create!(
        :value_proposition => "Daily Deal 2 For A1",
        :price => 25.00,
        :value => 74.00,
        :quantity => 100,
        :terms => "these are my terms",
        :description => "this is my description",
        :start_at => Time.zone.parse("Mar 04, 2009 07:00:00"),
        :hide_at => Time.zone.parse("Mar 04, 2009 17:00:00")
      )

      @non_voucher_deal = a_1.daily_deals.create!(
          :value_proposition => "Daily Deal 1 For A1",
          :price => 0.00,
          :value => 81.00,
          :quantity => 1,
          :min_quantity => 1,
          :max_quantity => 1,
          :terms => "these are my terms",
          :description => "this is my description",
          :start_at => Time.zone.parse("Mar 02, 2009 12:00:00"),
          :hide_at  => Time.zone.parse("Mar 02, 2009 22:00:00"),
          :expires_on => Date.parse("Mar 03, 2009 22:00:00"),
          :advertiser_credit_percentage => 2
      )

      non_voucher_purchase = NonVoucherDailyDealPurchase.new
      non_voucher_purchase.daily_deal = @non_voucher_deal
      non_voucher_purchase.quantity = 1
      non_voucher_purchase.consumer = c_2
      non_voucher_purchase.payment_status = "captured"
      non_voucher_purchase.executed_at = "Mar 02, 2009 00:00:01"
      non_voucher_purchase.save!
      non_voucher_purchase.create_certificates!

      login_as :aaron
      dates = Time.zone.parse("Mar 01, 2009")..Time.zone.parse("Mar 09, 2009")
      xhr :get, :purchased_daily_deals, :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s, :format => "xml"

      assert !assigns(:publishers).empty?
      assert_select "publishers publisher##{sdh_austin.id}" do
        assert_select "publisher_name", sdh_austin.name
        assert_select "deals_count", :text => "2"
        assert_select "purchased_deals_count", :text => "5"
        assert_select "deal_purchasers_count", :text => "2"
        assert_select "purchased_deals_gross", :text => "156.0"
        assert_select "purchased_deals_discount", :text => "10.0"
        assert_select "purchased_deals_amount", :text => "146.0"
      end

      assert_select "publishers publisher##{sdreader.id}", false
    end

    should "render csv" do
      daily_deal_purchase = Factory(:captured_daily_deal_purchase)
      user = Factory(:user, :company => daily_deal_purchase.publisher)
      login_as user
      get(:purchased_daily_deals,
          :dates_begin => Time.zone.now.beginning_of_month.to_s,
          :dates_end => Time.zone.now.end_of_month.to_s,
          :format => "csv"
      )
      assert_response :success
      csv = FasterCSV.new(@response.binary_content)
      row = csv.shift
      assert_equal "Currency Code", row[4], row.join(", ")
      assert_equal "Gross", row[5], row.join(", ")
      row = csv.shift
      assert_equal "USD", row[4], row.join(", ")
      assert_equal "15.0", row[5], row.join(", ")
    end

    should "be successful as non-admin" do
      daily_deal_purchase = Factory(:captured_daily_deal_purchase)
      user = Factory(:user, :company => daily_deal_purchase.publisher)
      login_as user
      get(:purchased_daily_deals,
          :dates_begin => Time.zone.now.beginning_of_month.to_s,
          :dates_end => Time.zone.now.end_of_month.to_s
      )
      assert_response :success
    end

    should "be successful as admin" do
      daily_deal_purchase = Factory(:captured_daily_deal_purchase)
      login_as Factory(:admin)
      get(:purchased_daily_deals,
          :dates_begin => Time.zone.now.beginning_of_month.to_s,
          :dates_end => Time.zone.now.end_of_month.to_s
      )
      assert_response :success
    end
  end

  context "#affiliated_daily_deals" do
    should "render xml" do
      p_1 = Factory(:publisher, :name => "Publisher 1")
      p_2 = Factory(:publisher, :name => "Publisher 2")
      p_3 = Factory(:publisher, :name => "Publisher 3")

      p_1_d_1 = Factory(:daily_deal,
                        :publisher => p_1,
                        :price => 20.00,
                        :start_at => Time.zone.parse("Mar 04, 2011 07:00:00"),
                        :hide_at => Time.zone.parse("Mar 04, 2011 17:00:00"),
                        :affiliate_revenue_share_percentage => 20.0)

      p_1_d_1_placement_1 = Factory(:affiliate_placement, :placeable => p_1_d_1)

      Factory(:captured_daily_deal_purchase,
              :daily_deal => p_1_d_1,
              :executed_at => p_1_d_1.start_at + 1.minutes,
              :affiliate => p_1_d_1_placement_1.affiliate)
      Factory(:captured_daily_deal_purchase,
              :daily_deal => p_1_d_1,
              :executed_at => p_1_d_1.start_at + 5.minutes,
              :affiliate => p_1_d_1_placement_1.affiliate,
              :quantity => 5)
      Factory(:captured_daily_deal_purchase,
              :daily_deal => p_1_d_1,
              :executed_at => p_1_d_1.start_at + 9.minutes)

      p_1_d_2 = Factory(:daily_deal,
                        :publisher => p_1,
                        :price => 15.00,
                        :start_at => Time.zone.parse("Mar 05, 2011 07:00:00"),
                        :hide_at => Time.zone.parse("Mar 05, 2011 17:00:00"),
                        :affiliate_revenue_share_percentage => 10.0)

      p_1_d_2_placement_1 = Factory(:affiliate_placement, :placeable => p_1_d_2)
      p_1_d_2_placement_2 = Factory(:affiliate_placement, :placeable => p_1_d_2)

      Factory(:captured_daily_deal_purchase,
              :daily_deal => p_1_d_2,
              :executed_at => p_1_d_2.start_at + 2.minutes,
              :affiliate => p_1_d_2_placement_2.affiliate)

      p_1_d_3 = Factory(:daily_deal,
                        :publisher => p_1,
                        :price => 10.00,
                        :start_at => Time.zone.parse("Mar 06, 2011 07:00:00"),
                        :hide_at => Time.zone.parse("Mar 06, 2011 17:00:00"),
                        :affiliate_revenue_share_percentage => 5.0)

      Factory(:captured_daily_deal_purchase, :daily_deal => p_1_d_3)

      p_2_d_1 = Factory(:daily_deal,
                        :publisher => p_2,
                        :start_at => Time.zone.parse("Mar 04, 2011 07:00:00"),
                        :hide_at => Time.zone.parse("Mar 04, 2011 17:00:00"),
                        :price => 50.00)

      Factory(:captured_daily_deal_purchase,
              :daily_deal => p_2_d_1,
              :executed_at => p_2_d_1.start_at + 5.minutes)

      p_2_d_2 = Factory(:daily_deal,
                        :publisher => p_2,
                        :price => 10.00,
                        :start_at => Time.zone.parse("Mar 05, 2011 07:00:00"),
                        :hide_at => Time.zone.parse("Mar 05, 2011 17:00:00"),
                        :affiliate_revenue_share_percentage => 5.0)

      Factory(:affiliate_placement, :placeable => p_2_d_2)

      login_as Factory(:admin)

      dates = Time.zone.parse("Mar 01, 2011")..Time.zone.parse("Mar 09, 2011")
      xhr :get, :affiliated_daily_deals, :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s, :format => "xml"

      assert !assigns(:publishers).empty?
      assert_select "publishers publisher##{p_1.id}" do
        assert_select "publisher_name", p_1.name
        assert_select "deals_count", :text => "2"
        assert_select "currency_code", :text => "USD"
        assert_select "currency_symbol", :text => "$"
        assert_select "deal_purchasers_count", :text => "3"
        assert_select "affiliated_deals_count", :text => "7"
        assert_select "affiliated_deals_gross", :text => "135.0"
        assert_select "affiliated_deals_payout", :text => "25.5"
        assert_select "affiliated_deals_amount", :text => "109.5"
      end

      # publisher 2 should not show up because its deals have no affiliate placements with purchased deals
      assert_select "publishers publisher##{p_2.id}", false
      # publisher 3 should not show because it has no purchased affiliated deals
      assert_select "publishers publisher##{p_3.id}", false
    end

    should "render csv" do
      publisher = Factory(:publisher, :name => "Publisher 1")

      deal = Factory(:daily_deal,
                     :publisher => publisher,
                     :price => 20.00,
                     :start_at => Time.zone.parse("Mar 04, 2011 07:00:00"),
                     :hide_at => Time.zone.parse("Mar 04, 2011 17:00:00"),
                     :affiliate_revenue_share_percentage => 10.0)

      placement = Factory(:affiliate_placement, :placeable => deal)

      Factory(:captured_daily_deal_purchase,
              :daily_deal => deal,
              :executed_at => deal.start_at + 1.minutes,
              :quantity => 2,
              :affiliate => placement.affiliate)

      login_as Factory(:admin)

      dates = Time.zone.parse("Mar 01, 2011")..Time.zone.parse("Mar 09, 2011")
      get :affiliated_daily_deals,
          :dates_begin => dates.begin.to_s,
          :dates_end => dates.end.to_s,
          :format => "csv"

      assert_response :success
      csv = FasterCSV.new(@response.binary_content)
      row = csv.shift

      assert_equal "Publisher", row[0]
      assert_equal "Affiliated Deals", row[1]
      assert_equal "Purchased", row[2]
      assert_equal "Purchasers", row[3]
      assert_equal "Currency Code", row[4]
      assert_equal "Gross", row[5]
      assert_equal "Payout", row[6]
      assert_equal "Total", row[7]

      row = csv.shift
      assert_equal "Publisher 1", row[0]
      assert_equal "1", row[1]
      assert_equal "2", row[2]
      assert_equal "1", row[3]
      assert_equal "USD", row[4]
      assert_equal "40.0", row[5]
      assert_equal "4.0", row[6]
      assert_equal "36.0", row[7]
    end

    should "be successful" do
      publisher = Factory(:publisher, :name => "Publisher 1")

      deal = Factory(:daily_deal,
                     :publisher => publisher,
                     :price => 20.00,
                     :start_at => Time.zone.parse("Mar 04, 2011 07:00:00"),
                     :hide_at => Time.zone.parse("Mar 04, 2011 17:00:00"),
                     :affiliate_revenue_share_percentage => 10.0)

      placement = Factory(:affiliate_placement, :placeable => deal)

      Factory(:captured_daily_deal_purchase,
              :daily_deal => deal,
              :executed_at => deal.start_at + 1.minutes,
              :quantity => 2,
              :affiliate => placement.affiliate)

      login_as Factory(:admin)

      dates = Time.zone.parse("Mar 01, 2011")..Time.zone.parse("Mar 09, 2011")
      get :affiliated_daily_deals,
          :dates_begin => dates.begin.to_s,
          :dates_end => dates.end.to_s

      assert_response :success
    end
  end
end
