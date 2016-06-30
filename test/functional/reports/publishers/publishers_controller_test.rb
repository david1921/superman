require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Reports::Publishers::PublishersControllerTest

module Reports
  module Publishers
    class PublishersControllerTest < ActionController::TestCase
      tests Reports::PublishersController

      def setup
        GiftCertificateMailer.expects(:deliver_gift_certificate).at_least(0).returns(nil)
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

      test "billing summary with default dates by get" do
        Time.zone.expects(:now).at_least_once.returns Time.zone.parse("Nov 4, 2008 12:34:56")

        with_admin_user_required(:quentin, :aaron) do
          get :index, :summary => "billing"
        end
        assert_response :success
        assert_layout 'reports'
        assert_application_page_title "Reports: Billing Summary"

        assert_select "form#dates[method=get][action='']", 1 do
          assert_select "input[name=dates_begin][value='October 01, 2008']", 1
          assert_select "input[name=dates_end][value='October 31, 2008']", 1
        end
        assert_select "div#billing_summary", 1
      end

      test "billing summary with explicit dates by get" do
        Time.expects(:now).at_least_once.returns(Time.parse("Nov 02 18:12:34 GMT 2009"))

        with_admin_user_required(:quentin, :aaron) do
          get :index, :summary => "billing", :dates_begin => "August 15, 2009", :dates_end => "September 14, 2009"
        end
        assert_response :success
        assert_layout 'reports'
        assert_application_page_title "Reports: Billing Summary"
        assert_equal Date.new(2009, 8, 15) .. Date.new(2009, 9, 14), assigns(:dates), "@dates assignment"

        assert_select "form#dates[method=get][action='']", 1 do |forms|
          form = forms.first
          assert_select form, "input[name=dates_begin][value='August 15, 2009']", 1
          assert_select form, "input[name=dates_end][value='September 14, 2009']", 1
        end
        assert_select "div#billing_summary", 1
      end

      test "billing summary with explicit dates by xhr" do
        assert Publisher.count > 0, "Should have at least one publisher fixture"
        Time.expects(:now).at_least_once.returns(Time.parse("Nov 02 18:12:34 GMT 2009"))

        with_admin_user_required(:quentin, :aaron, :format => :xml) do
          xhr :get, :index, :summary => "billing", :format => "xml", :dates_begin => "August 15, 2009", :dates_end => "September 14, 2009"
        end
        assert_response :success
        assert assigns(:publishers)
        assert_equal Date.new(2009, 8, 15) .. Date.new(2009, 9, 14), assigns(:dates), "@dates assignment"

        root = REXML::Document.new(@response.body).root
        returned_publishers = returning({}) do |hash|
          root.each_element do |elem|
            assert_equal "publisher", elem.name
            publisher_id = elem.attributes["publisher_id"]
            hash[publisher_id] = returning({}) do |stats|
              elem.each_element do |child|
                type = child.name
                data = child.text
                stats[type] = data
              end
            end
          end
        end
        Publisher.all.each do |publisher|
          returned = returned_publishers[publisher.id.to_s]
          assert returned, "Should have publisher_id for #{publisher.name}"
          assert_equal publisher.name, returned["publisher_name"], "Should have publisher_name for #{publisher.name}"
          %w{ prints_count txts_count emails_count calls_count }.each do |elem|
            assert_match(/^\d+$/, returned[elem], "Should have integer #{elem} for #{publisher.name}")
          end
          assert_match(/^\d+\.\d$/, returned["calls_minutes"], "Should have decimal voice_message_minutes for #{publisher.name}")
        end
      end

      test "csv download of purchased deal certificates" do
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

        login_as publisher.users.first
        get :purchased_gift_certificates, {
          :id => publisher.to_param, :dates_begin => dates.begin.to_s,
          :dates_end => dates.end.to_s, :format => "csv"
        }

        # This is required to actually execute the code that streams out
        # the CSV file. DO NOT REMOVE THIS LINE!
        @response.binary_content

        assert_response :success
      end

      test "xhr purchased deal certificates" do
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

        login_as publisher.users.first
        dates = Date.parse("Nov 16, 2008")..Date.parse("Nov 18, 2008")
        xhr :get, :purchased_gift_certificates, {
          :id => publisher.to_param,
          :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s,
          :format => "xml"
        }
        records = Hash.from_xml(@response.body).try(:fetch, "purchased_gift_certificates").try(:fetch, "purchased_gift_certificate")
        assert_not_nil records, "Should have a list of purchased deal certificates"
        assert_equal 9, records.size
        %w{ 13 17 14 19 21 22 16 24 26 }.each_with_index do |s, i|
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

      test "xhr affiliated_daily_deals" do
        publisher = Factory(:publisher, :name => "Publisher 1")

        a_1 = Factory(:advertiser, :publisher => publisher)
        a_2 = Factory(:advertiser, :publisher => publisher)

        a_1_d_1 = Factory(:daily_deal,
                          :publisher => publisher,
                          :advertiser => a_1,
                          :price => 20.00,
                          :start_at => Time.zone.parse("Mar 04, 2011 07:00:00"),
                          :hide_at => Time.zone.parse("Mar 04, 2011 17:00:00"),
                          :affiliate_revenue_share_percentage => 20.0)

        a_1_d_1_placement_1 = Factory(:affiliate_placement, :placeable => a_1_d_1)

        Factory(:captured_daily_deal_purchase,
                :daily_deal => a_1_d_1,
                :executed_at => a_1_d_1.start_at + 1.minutes,
                :affiliate => a_1_d_1_placement_1.affiliate)
        Factory(:captured_daily_deal_purchase,
                :daily_deal => a_1_d_1,
                :executed_at => a_1_d_1.start_at + 5.minutes,
                :affiliate => a_1_d_1_placement_1.affiliate,
                :quantity => 5)
        Factory(:captured_daily_deal_purchase,
                :daily_deal => a_1_d_1,
                :executed_at => a_1_d_1.start_at + 9.minutes)

        a_1_d_2 = Factory(:daily_deal,
                          :publisher => publisher,
                          :advertiser => a_1,
                          :price => 15.00,
                          :start_at => Time.zone.parse("Mar 05, 2011 07:00:00"),
                          :hide_at => Time.zone.parse("Mar 05, 2011 17:00:00"),
                          :affiliate_revenue_share_percentage => 10.0)

        a_1_d_2_placement_1 = Factory(:affiliate_placement, :placeable => a_1_d_2)
        a_1_d_2_placement_2 = Factory(:affiliate_placement, :placeable => a_1_d_2)

        Factory(:captured_daily_deal_purchase,
                :daily_deal => a_1_d_2,
                :executed_at => a_1_d_2.start_at + 2.minutes,
                :affiliate => a_1_d_2_placement_2.affiliate)

        a_2_d_1 = Factory(:daily_deal,
                          :publisher => publisher,
                          :advertiser => a_2,
                          :price => 10.00,
                          :start_at => Time.zone.parse("Mar 06, 2011 07:00:00"),
                          :hide_at => Time.zone.parse("Mar 06, 2011 17:00:00"),
                          :affiliate_revenue_share_percentage => 5.0)

        Factory(:captured_daily_deal_purchase, :daily_deal => a_2_d_1)

        login_as Factory(:admin)

        dates = Time.zone.parse("Mar 01, 2011")..Time.zone.parse("Mar 09, 2011")

        xhr :get, :affiliated_daily_deals,
            :dates_begin => dates.begin.to_s,
            :dates_end => dates.end.to_s,
            :format => "xml",
            :id => publisher.id

        assert_select "daily_deals daily_deal##{a_1_d_1.id}" do
          assert_select "advertiser_name", a_1.name
          assert_select "value_proposition", :text => a_1_d_1.value_proposition
          assert_select "accounting_id", :text => a_1_d_1.accounting_id
          assert_select "listing", :text => a_1_d_1.listing
          assert_select "started_at", :text => "03/04/11"
          assert_select "purchases_count", :text => "6"
          assert_select "purchasers_count", :text => "2"
          assert_select "affiliate_gross", :text => "120.0"
          assert_select "affiliate_rev_share", :text => "20.0"
          assert_select "affiliate_payout", :text => "24.0"
          assert_select "affiliate_total", :text => "96.0"
        end

        assert_select "daily_deals daily_deal##{a_1_d_2.id}" do
          assert_select "advertiser_name", a_1.name
          assert_select "value_proposition", :text => a_1_d_2.value_proposition
          assert_select "accounting_id", :text => a_1_d_2.accounting_id
          assert_select "listing", :text => a_1_d_2.listing
          assert_select "started_at", :text => "03/05/11"
          assert_select "purchases_count", :text => "1"
          assert_select "purchasers_count", :text => "1"
          assert_select "affiliate_gross", :text => "15.0"
          assert_select "affiliate_rev_share", :text => "10.0"
          assert_select "affiliate_payout", :text => "1.5"
          assert_select "affiliate_total", :text => "13.5"
        end

        assert_select "daily_deals daily_deal##{a_2_d_1.id}", false
      end

      test "csv affiliated_daily_deals" do
        publisher = Factory(:publisher, :name => "Publisher 1")
        advertiser = Factory(:advertiser, :publisher => publisher)

        deal = Factory(:daily_deal,
                       :publisher => publisher,
                       :advertiser => advertiser,
                       :price => 20.00,
                       :start_at => Time.zone.parse("Mar 04, 2011 07:00:00"),
                       :hide_at => Time.zone.parse("Mar 04, 2011 17:00:00"),
                       :affiliate_revenue_share_percentage => 20.0,
                       :custom_1 => "custom one",
                       :custom_2 => "custom two",
                       :custom_3 => "custom three"
        )

        placement = Factory(:affiliate_placement, :placeable => deal)

        Factory(:captured_daily_deal_purchase,
                :daily_deal => deal,
                :executed_at => deal.start_at + 1.minutes,
                :quantity => 3,
                :affiliate => placement.affiliate)

        user = Factory(:user, :company => publisher)
        login_as user

        dates = Time.zone.parse("Mar 01, 2011")..Time.zone.parse("Mar 09, 2011")

        get :affiliated_daily_deals,
            :id => publisher.to_param,
            :format => "csv",
            :dates_begin => dates.begin.to_s,
            :dates_end => dates.end.to_s

        assert_response :success

        csv = FasterCSV.new(@response.binary_content)

        row = csv.shift
        assert_equal "Started At", row[0]
        assert_equal "Advertiser", row[1]
        assert_equal "Accounting ID", row[2]
        assert_equal "Listing", row[3]
        assert_equal "Value Proposition", row[4]
        assert_equal "Purchases", row[5]
        assert_equal "Purchasers", row[6]
        assert_equal "Currency Code", row[7]
        assert_equal "Affiliate Gross", row[8]
        assert_equal "Affiliate Rev. Share", row[9]
        assert_equal "Affiliate Payout", row[10]
        assert_equal "Affiliate Total", row[11]
        assert_equal "Custom 1", row[12]
        assert_equal "Custom 2", row[13]
        assert_equal "Custom 3", row[14]

        row = csv.shift
        assert_equal "03/04/11 07:00AM", row[0]
        assert_equal advertiser.name, row[1]
        assert_equal deal.accounting_id, row[2]
        assert_equal deal.listing, row[3]
        assert_equal deal.value_proposition, row[4]
        assert_equal "3", row[5]
        assert_equal "1", row[6]
        assert_equal "60.0", row[8]
        assert_equal "20.0", row[9]
        assert_equal "12.0", row[10]
        assert_equal "48.0", row[11]
        assert_equal "custom one", row[12]
        assert_equal "custom two", row[13]
        assert_equal "custom three", row[14]
      end

      test "affiliated_daily_deals" do
        publisher = Factory(:publisher, :name => "Publisher 1")
        advertiser = Factory(:advertiser, :publisher => publisher)

        deal = Factory(:daily_deal,
                       :publisher => publisher,
                       :advertiser => advertiser,
                       :price => 20.00,
                       :start_at => Time.zone.parse("Mar 04, 2011 07:00:00"),
                       :hide_at => Time.zone.parse("Mar 04, 2011 17:00:00"),
                       :affiliate_revenue_share_percentage => 20.0)

        placement = Factory(:affiliate_placement, :placeable => deal)

        Factory(:captured_daily_deal_purchase,
                :daily_deal => deal,
                :executed_at => deal.start_at + 1.minutes,
                :affiliate => placement.affiliate)

        user = Factory(:user, :company => publisher)
        login_as user

        get :affiliated_daily_deals,
            :id => publisher.to_param,
            :dates_begin => Time.zone.parse("Mar 1, 2011 07:00:00"),
            :dates_end => Time.zone.parse("Mar 30, 2011 17:00:00")

        assert_response :success
        assert_template :affiliated_daily_deals
      end

      test "subscribers" do
        subscriber = Factory(:subscriber)
        publisher  = subscriber.publisher
        user       = Factory(:user, :company => publisher)

        login_as user

        get :subscribers,
            :id          => publisher.id,
            :dates_begin => Time.zone.now.beginning_of_month.to_s,
            :dates_end   => Time.zone.now.end_of_month.to_s

        assert_response :success
      end

      test "xhr subscribers" do
        subscriber  = Factory(:subscriber)
        subscriber2 = Factory(:subscriber, :publisher => subscriber.publisher, :created_at => 3.months.ago)
        subscriber3 = Factory(:subscriber, :publisher => subscriber.publisher)
        subscriber4 = Factory(:subscriber)
        publisher   = subscriber.publisher
        user        = Factory(:user, :company => publisher)

        login_as user

        xhr :get, :subscribers, :format => "xml",
            :id          => publisher.id,
            :dates_begin => Time.zone.now.beginning_of_month.to_s,
            :dates_end   => Time.zone.now.end_of_month.to_s

        assert_response :success

        response_xml   = Hash.from_xml(@response.body)
        subscriber_xml = response_xml['subscribers']['subscriber']

        assert_equal 2, subscriber_xml.size

        assert_select "subscribers subscriber##{subscriber.id}" do
          assert_select "email", subscriber.email
          assert_select "zip_code", subscriber.zip_code
          assert_select "first_name", subscriber.first_name
          assert_select "last_name", subscriber.last_name
        end
      end

      test "csv subscribers" do
        subscriber = Factory(:subscriber)
        publisher  = subscriber.publisher
        user       = Factory(:user, :company => publisher)
        Factory(:subscriber, :publisher => publisher, :created_at => 4.months.ago)

        login_as user

        get :subscribers, :format => "csv",
            :id          => publisher.id,
            :dates_begin => Time.zone.now.beginning_of_month.to_s,
            :dates_end   => Time.zone.now.end_of_month.to_s

        assert_response :success

        csv = FasterCSV.new(@response.binary_content)
        row = csv.shift

        assert_equal "Email", row[0], row.join(", ")
        assert_equal "Zip Code", row[1], row.join(", ")
        assert_equal "First Name", row[2], row.join(", ")
        assert_equal "Last Name", row[3], row.join(", ")

        row = csv.shift

        assert_equal subscriber.email, row[0], row.join(", ")
        assert_equal subscriber.zip_code, row[1], row.join(", ")
        assert_equal subscriber.first_name, row[2], row.join(", ")
        assert_equal subscriber.last_name, row[3], row.join(", ")
      end

      test "referrals" do
        publisher = Factory(:publisher)
        user = Factory(:user, :company => publisher)

        login_as user

        get :referrals,
            :id          => publisher.id,
            :dates_begin => Time.zone.now.beginning_of_month.to_s,
            :dates_end   => Time.zone.now.end_of_month.to_s

        assert_response :success
      end

      test "referrals xml" do
        consumer  = Factory(:consumer, :referrer_code => "834jj2")
        publisher = consumer.publisher
        # throwaway consumer to make sure we are not grabbing consumers that have no referrals
        Factory(:consumer, :publisher => publisher)

        2.times do
          Factory(:consumer, :referral_code => consumer.referrer_code, :publisher => publisher)
          Factory(:credit, :consumer => consumer, :amount => 10.00)
        end
        daily_deal = Factory(:daily_deal, :publisher => publisher)
        Factory(:daily_deal_purchase, :consumer => consumer, :credit_used => 10.00, :daily_deal => daily_deal)

        user = Factory(:user, :company => publisher)


        login_as user

        xhr :get, :referrals, :format => "xml",
            :id          => publisher.id,
            :dates_begin => Time.zone.now.beginning_of_month.to_s,
            :dates_end   => Time.zone.now.end_of_month.to_s

        assert_response :success

        assert_select "referrals referrer##{consumer.id}" do
          assert_select "email", consumer.email
          assert_select "referral_count", "2"
          assert_select "credits_given", "20.00"
          assert_select "credit_used", "10.00"
        end
      end

      test "referrals csv" do
        consumer  = Factory(:consumer, :referrer_code => "834jj2")
        publisher = consumer.publisher
        # throwaway consumer to make sure we are not grabbing consumers that have no referrals
        Factory(:consumer, :publisher => publisher)

        2.times do
          Factory(:consumer, :referral_code => consumer.referrer_code, :publisher => publisher)
          Factory(:credit, :consumer => consumer, :amount => 10.00)
        end
        daily_deal = Factory(:daily_deal, :publisher => publisher)
        Factory(:daily_deal_purchase, :consumer => consumer, :credit_used => 10.00, :daily_deal => daily_deal)

        user = Factory(:user, :company => publisher)
        login_as user

        get :referrals, :format => "csv",
            :id          => publisher.id,
            :dates_begin => Time.zone.now.beginning_of_month.to_s,
            :dates_end   => Time.zone.now.end_of_month.to_s

        assert_response :success

        csv = FasterCSV.new(@response.binary_content)
        row = csv.shift

        assert_equal "Email", row[0]
        assert_equal "Referral Count", row[1]
        assert_equal "Credits Given", row[2]
        assert_equal "Credit Used", row[3]

        row = csv.shift

        assert_equal consumer.email, row[0]
        assert_equal "2", row[1]
        assert_equal "20.00", row[2]
        assert_equal "10.00", row[3]
      end
      
    end
  end
end
