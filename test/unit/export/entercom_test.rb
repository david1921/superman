require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Export::EntercomTest

module Export

  class EntercomTest < ActiveSupport::TestCase

    def setup
      Timecop.freeze(Time.parse("2011-09-13T11:33:56Z")) do
        @dining = Factory :daily_deal_category, :name => "Dining", :abbreviation => "D"
        @entercom = Factory :publishing_group, :label => "entercomnew"

        @entercom_providence = Factory :publisher, :label => "entercom-providence", :publishing_group => @entercom
        @entercom_newengland = Factory :publisher, :label => "entercom-newengland", :publishing_group => @entercom
        @entercom_sacramento = Factory :publisher, :label => "entercom-sacramento", :publishing_group => @entercom
        @nydn = Factory :publisher, :label => "nydailynews"

        @entercom_providence_c1 = Factory :consumer, :created_at => Time.parse("2011-09-08T10:14:22Z"), :email => "ep_c1@example.com", :publisher => @entercom_providence, :name => "Boris Spassky", :remote_record_id => "remote-id-ep-c1"
        @entercom_providence_c2 = Factory :consumer, :created_at => Time.parse("2011-09-09T09:12:12Z"), :email => "ep_c2@example.com", :publisher => @entercom_providence, :name => "Bobby Fischer", :remote_record_id => "remote-id-ep-c2"
        @entercom_newengland_c1 = Factory :consumer, :created_at => Time.parse("2011-09-10T08:33:50Z"), :email => "en_c1@example.com", :publisher => @entercom_newengland, :name => "Anatoly Karpov",
                                          :address_line_1 => "100 Test Road", :billing_city => "Testville", :state => "AL", :remote_record_id => "remote-id-en-c1"
        @entercom_sacramento_c1 = Factory :consumer, :created_at => Time.parse("2011-09-12T11:12:10Z"), :email => "es_c1@example.com", :publisher => @entercom_sacramento, :name => "Garry Kasparov"
        @nydn_c1 = Factory :consumer, :publisher => @nydn

        @entercom_providence_a1 = Factory :advertiser, :publisher => @entercom_providence, :merchant_contact_name => "ep a1 mcn", :email_address => "epa1@example.com"
        @entercom_newengland_a1 = Factory :advertiser, :publisher => @entercom_newengland, :merchant_contact_name => "en a1 mcn"
        @entercom_newengland_a1_s1 = Factory :store, :advertiser => @entercom_newengland_a1, :zip => "90210"
        @entercom_sacramento_a1 = Factory :advertiser, :publisher => @entercom_sacramento
        @nydn_a1 = Factory :advertiser, :publisher => @nydn

        @entercom_providence_discount = Factory :discount, :publisher => @entercom_providence,
                                                :code => "GOODDEAL", :amount => 5,
                                                :first_usable_at => Time.parse("2011-07-13T11:33:56Z"),
                                                :last_usable_at => Time.parse("2012-07-13T11:33:56Z")

        @entercom_providence_a1_d1 = Factory :daily_deal_for_syndication, :value_proposition => "ep a1 d1", :price => 42,
                                             :advertiser => @entercom_providence_a1,
                                             :analytics_category_id => @dining.id,
                                             :advertiser_revenue_share_percentage => 25,
                                             :account_executive => "Phil Ivey", 
                                             :start_at => Time.parse("2011-09-10T11:33:56Z"),
                                             :hide_at => Time.parse("2011-09-15T11:33:56Z")
        @entercom_providence_a1_d2 = Factory :side_daily_deal, :value_proposition => "ep a1 d2", :price => 3.14,
                                             :advertiser => @entercom_providence_a1, :min_quantity => 1,
                                             :start_at => Time.parse("2011-09-10T12:30:00Z"),
                                             :hide_at => Time.parse("2011-09-14T12:30:00Z")
        @entercom_newengland_a1_d1 = Factory :daily_deal, :value_proposition => "en a1 d1", :price => 256,
                                             :advertiser => @entercom_newengland_a1,
                                             :start_at => Time.parse("2011-09-11T11:00:15Z"),
                                             :hide_at => Time.parse("2011-09-16T11:00:00Z")
        @entercom_sacramento_a1_d1 = Factory :daily_deal, :value_proposition => "es a1 d1", :price => 361,
                                             :advertiser => @entercom_sacramento_a1,
                                             :start_at => Time.parse("2011-09-09T10:00:00Z"),
                                             :hide_at => Time.parse("2011-09-15T10:00:00Z")
        @nydn_a1_d1 = Factory :side_daily_deal_for_syndication, :value_proposition => "ny a1 d1", :price => 8, :advertiser => @nydn_a1, :min_quantity => 1
        @nydn_syndicated_deal = syndicate(@entercom_providence_a1_d1, @nydn)
        @nydn_deal_syndicated_to_entercom_providence = syndicate(@nydn_a1_d1, @entercom_providence)

        @entercom_providence_a1_d1_p1 = Factory :captured_daily_deal_purchase, :daily_deal => @entercom_providence_a1_d1,
                                                :executed_at => Time.parse("2011-08-10T12:53:50Z"), :consumer => @entercom_providence_c1,
                                                :quantity => 3, :discount => @entercom_providence_discount
        @entercom_providence_a1_d1_p1.daily_deal_payment.update_attribute :payer_postal_code, "12345"
        @entercom_providence_a1_d1_p2 = Factory :captured_daily_deal_purchase, :daily_deal => @entercom_providence_a1_d1,
                                                :executed_at => Time.parse("2011-09-10T17:12:19Z"), :consumer => @entercom_providence_c1,
                                                :quantity => 1
        @nydn_syndicated_deal_p1 = Factory :captured_daily_deal_purchase, :daily_deal => @nydn_syndicated_deal,
                                                :executed_at => Time.parse("2011-09-10T22:10:17Z"), :consumer => @nydn_c1,
                                                :quantity => 4
        @entercom_providence_a1_d2_p1 = Factory :captured_daily_deal_purchase, :daily_deal => @entercom_providence_a1_d2,
                                                :executed_at => Time.parse("2011-09-11T10:00:00Z"), :consumer => @entercom_providence_c2,
                                                :quantity => 2
        @entercom_newengland_a1_d1_p1 = Factory :captured_daily_deal_purchase, :daily_deal => @entercom_newengland_a1_d1,
                                                :executed_at => Time.parse("2011-09-12T11:09:14Z"), :consumer => @entercom_newengland_c1,
                                                :quantity => 1, :store => @entercom_newengland_a1_s1
        @entercom_sacramento_a1_d1_r1 = Factory :refunded_daily_deal_purchase, :daily_deal => @entercom_sacramento_a1_d1,
                                                :executed_at => Time.parse("2011-09-12T12:10:13Z"), :consumer => @entercom_sacramento_c1,
                                                :quantity => 2, :refunded_at => Time.parse("2011-09-12T17:10:13Z")
        @nydn_a1_d1_p1 = Factory :captured_daily_deal_purchase, :daily_deal => @nydn_deal_syndicated_to_entercom_providence,
                                 :executed_at => Time.parse("2011-09-12T19:10:15Z"), :consumer => @entercom_providence_c1, :quantity => 1
        @nydn_a1_d1_r1 = Factory :refunded_daily_deal_purchase, :daily_deal => @nydn_deal_syndicated_to_entercom_providence,
                                 :executed_at => Time.parse("2011-09-12T20:11:12Z"), :consumer => @entercom_providence_c1,
                                 :quantity => 1, :refunded_at => Time.parse("2011-09-12T23:11:12Z")

        @ignored_purchase_1 = Factory :daily_deal_purchase, :consumer => @entercom_newengland_c1, :daily_deal => @entercom_newengland_a1_d1
        @ignored_purchase_2 = Factory :daily_deal_purchase, :consumer => @entercom_providence_c1, :daily_deal => @entercom_providence_a1_d2
      end
    end

    context "Export::Entercom::PurchasesAndRefunds.export_to_csv!" do

      context "job logging" do

        teardown do
          ENV['INCREMENTAL'] = nil
        end

        should "create a Job record to log a full run, leaving the increment_timestamp blank" do
          begin
            assert_difference "Job.count", 1 do
              @csv_filename = Export::Entercom::PurchasesAndRefunds.export_to_csv!
            end

            assert_equal 1, Job.count
            job = Job.first
            assert_equal "entercom:generate_purchases_and_refunds_csv", job.key
            assert_equal @csv_filename, job.file_name
            assert job.increment_timestamp.blank?
            assert job.publisher.blank?
          ensure
            remove_file(@csv_filename)
          end
        end

        should "create a Job record to log an incremental run, and popuplate the increment_timestamp" do
          ENV['INCREMENTAL'] = "1"
          begin
            assert_difference "Job.count", 1 do
              @csv_filename = Export::Entercom::PurchasesAndRefunds.export_to_csv!
            end

            assert_equal 1, Job.count
            job = Job.first
            assert_equal "entercom:generate_purchases_and_refunds_csv", job.key
            assert_equal @csv_filename, job.file_name
            assert job.increment_timestamp.present?
            assert job.publisher.blank?
          ensure
            remove_file(@csv_filename)
          end
        end

      end

      context "when run in cumulative mode" do

        setup do
          Timecop.freeze(Time.parse("2011-09-13T11:33:56Z")) do
            @csv_filename = Export::Entercom::PurchasesAndRefunds.export_to_csv!
          end
          @csv_data = FasterCSV.read(@csv_filename)
        end

        teardown do
          remove_file(@csv_filename)
        end

        should "return a String that is the filename of the generated CSV file" do
          assert @csv_filename.is_a?(String)
          assert_equal Rails.root.join("tmp", "entercomnew-purchases-20110913113356.csv").to_s,
                       @csv_filename
        end

        context "the data written to the CSV file" do

          should "contain the relevant purchase data, less rows for consumers that don't have remote_record_ids" do
            assert_equal expected_purchase_and_refunds_headers, @csv_data[0]

            assert_equal 6, @csv_data[1..-1].size
            assert @csv_data.all? { |row| row.size == 21 }

            od_col_num = purchase_column_number_for("Order Date")
            assert_equal "2011-08-10", @csv_data[1][od_col_num]
            assert_equal "2011-09-10", @csv_data[2][od_col_num]
            assert_equal "2011-09-11", @csv_data[3][od_col_num]
            assert_equal "2011-09-12", @csv_data[4][od_col_num]
            
            oid_col_num = purchase_column_number_for("Order ID")
            assert_equal @entercom_providence_a1_d1_p1.uuid, @csv_data[1][oid_col_num]
            assert_equal @entercom_providence_a1_d1_p2.uuid, @csv_data[2][oid_col_num]
            assert_equal @entercom_providence_a1_d2_p1.uuid, @csv_data[3][oid_col_num]
            assert_equal @entercom_newengland_a1_d1_p1.uuid, @csv_data[4][oid_col_num]

            tx_type_col_num = purchase_column_number_for("Type")
            assert_equal "P", @csv_data[1][tx_type_col_num]
            assert_equal "P", @csv_data[2][tx_type_col_num]
            assert_equal "P", @csv_data[3][tx_type_col_num]
            assert_equal "P", @csv_data[4][tx_type_col_num]
            assert_equal "P", @csv_data[5][tx_type_col_num]
            assert_equal "P", @csv_data[6][tx_type_col_num]

            consumer_id_col_num = purchase_column_number_for("Consumer ID")
            assert_equal @entercom_providence_c1.id.to_s, @csv_data[1][consumer_id_col_num]
            assert_equal @entercom_providence_c1.id.to_s, @csv_data[2][consumer_id_col_num]
            assert_equal @entercom_providence_c2.id.to_s, @csv_data[3][consumer_id_col_num]
            assert_equal @entercom_newengland_c1.id.to_s, @csv_data[4][consumer_id_col_num]
            assert_equal @entercom_providence_c1.id.to_s, @csv_data[5][consumer_id_col_num]
            assert_equal @entercom_providence_c1.id.to_s, @csv_data[6][consumer_id_col_num]

            member_id_col_num = purchase_column_number_for("Member ID")
            assert_equal "remote-id-ep-c1", @csv_data[1][member_id_col_num]
            assert_equal "remote-id-ep-c1", @csv_data[2][member_id_col_num]
            assert_equal "remote-id-ep-c2", @csv_data[3][member_id_col_num]
            assert_equal "remote-id-en-c1", @csv_data[4][member_id_col_num]
            assert_equal "remote-id-ep-c1", @csv_data[5][member_id_col_num]
            assert_equal "remote-id-ep-c1", @csv_data[6][member_id_col_num]

            email_col_num = purchase_column_number_for("Email")
            assert_equal @entercom_providence_c1.email, @csv_data[1][email_col_num]
            assert_equal @entercom_providence_c1.email, @csv_data[2][email_col_num]
            assert_equal @entercom_providence_c2.email, @csv_data[3][email_col_num]
            assert_equal @entercom_newengland_c1.email, @csv_data[4][email_col_num]
            assert_equal @entercom_providence_c1.email, @csv_data[5][email_col_num]
            assert_equal @entercom_providence_c1.email, @csv_data[6][email_col_num]

            market_col_num = purchase_column_number_for("Market")
            assert_equal "entercom-providence", @csv_data[1][market_col_num]
            assert_equal "entercom-providence", @csv_data[2][market_col_num]
            assert_equal "entercom-providence", @csv_data[3][market_col_num]
            assert_equal "entercom-newengland", @csv_data[4][market_col_num]
            assert_equal "entercom-providence", @csv_data[5][market_col_num]
            assert_equal "entercom-providence", @csv_data[6][market_col_num]

            deal_id_col_num = purchase_column_number_for("Deal ID")
            assert_equal @entercom_providence_a1_d1.id.to_s, @csv_data[1][deal_id_col_num]
            assert_equal @entercom_providence_a1_d1.id.to_s, @csv_data[2][deal_id_col_num]
            assert_equal @entercom_providence_a1_d2.id.to_s, @csv_data[3][deal_id_col_num]
            assert_equal @entercom_newengland_a1_d1.id.to_s, @csv_data[4][deal_id_col_num]
            assert_equal @nydn_deal_syndicated_to_entercom_providence.id.to_s, @csv_data[5][deal_id_col_num]
            assert_equal @nydn_deal_syndicated_to_entercom_providence.id.to_s, @csv_data[6][deal_id_col_num]

            advertiser_id_col_num = purchase_column_number_for("Advertiser ID")
            assert_equal @entercom_providence_a1.id.to_s, @csv_data[1][advertiser_id_col_num]
            assert_equal @entercom_providence_a1.id.to_s, @csv_data[2][advertiser_id_col_num]
            assert_equal @entercom_providence_a1.id.to_s, @csv_data[3][advertiser_id_col_num]
            assert_equal @entercom_newengland_a1.id.to_s, @csv_data[4][advertiser_id_col_num]

            advertiser_name_col_num = purchase_column_number_for("Advertiser")
            assert_equal @entercom_providence_a1.name, @csv_data[1][advertiser_name_col_num]
            assert_equal @entercom_providence_a1.name, @csv_data[2][advertiser_name_col_num]
            assert_equal @entercom_providence_a1.name, @csv_data[3][advertiser_name_col_num]
            assert_equal @entercom_newengland_a1.name, @csv_data[4][advertiser_name_col_num]

            value_prop_col_num = purchase_column_number_for("Value Prop")
            assert_equal "ep a1 d1", @csv_data[1][value_prop_col_num]
            assert_equal "ep a1 d1", @csv_data[2][value_prop_col_num]
            assert_equal "ep a1 d2", @csv_data[3][value_prop_col_num]
            assert_equal "en a1 d1", @csv_data[4][value_prop_col_num]
            assert_equal "ny a1 d1", @csv_data[5][value_prop_col_num]
            assert_equal "ny a1 d1", @csv_data[6][value_prop_col_num]

            category_col_num = purchase_column_number_for("Category")
            assert_equal "D", @csv_data[1][category_col_num]
            assert_equal "D", @csv_data[2][category_col_num]
            assert_nil @csv_data[3][category_col_num]
            assert_nil @csv_data[4][category_col_num]
            assert_nil @csv_data[5][category_col_num]
            assert_nil @csv_data[6][category_col_num]

            price_col_num = purchase_column_number_for("Price")
            assert_equal "42.00", @csv_data[1][price_col_num]
            assert_equal "42.00", @csv_data[2][price_col_num]
            assert_equal "3.14", @csv_data[3][price_col_num]
            assert_equal "256.00", @csv_data[4][price_col_num]
            assert_equal "8.00", @csv_data[5][price_col_num]
            assert_equal "8.00", @csv_data[6][price_col_num]

            qty_col_num = purchase_column_number_for("Deals Purchased")
            assert_equal "3", @csv_data[1][qty_col_num]
            assert_equal "1", @csv_data[2][qty_col_num]
            assert_equal "2", @csv_data[3][qty_col_num]
            assert_equal "1", @csv_data[4][qty_col_num]
            assert_equal "1", @csv_data[5][qty_col_num]
            assert_equal "1", @csv_data[6][qty_col_num]

            order_value_col_num = purchase_column_number_for("Order Value")
            assert_equal "121.00", @csv_data[1][order_value_col_num]
            assert_equal "42.00", @csv_data[2][order_value_col_num]
            assert_equal "6.28", @csv_data[3][order_value_col_num]
            assert_equal "256.00", @csv_data[4][order_value_col_num]
            assert_equal "8.00", @csv_data[5][order_value_col_num]
            assert_equal "8.00", @csv_data[6][order_value_col_num]

            rev_share_col_num = purchase_column_number_for("Advertiser Rev Share")
            assert_equal "25.00", @csv_data[1][rev_share_col_num]
            assert_equal "25.00", @csv_data[2][rev_share_col_num]
            assert_nil @csv_data[3][rev_share_col_num]
            assert_nil @csv_data[4][rev_share_col_num]
            assert_nil @csv_data[5][rev_share_col_num]
            assert_nil @csv_data[6][rev_share_col_num]

            promo_code_col_num = purchase_column_number_for("Promo Code Name")
            assert_equal "GOODDEAL", @csv_data[1][promo_code_col_num]
            assert_nil @csv_data[2][promo_code_col_num]
            assert_nil @csv_data[3][promo_code_col_num]
            assert_nil @csv_data[4][promo_code_col_num]
            assert_nil @csv_data[5][promo_code_col_num]
            assert_nil @csv_data[6][promo_code_col_num]

            promo_amt_col_num = purchase_column_number_for("Promo Code Amount")
            assert_equal "5.00", @csv_data[1][promo_amt_col_num]
            assert_nil @csv_data[2][promo_amt_col_num]
            assert_nil @csv_data[3][promo_amt_col_num]
            assert_nil @csv_data[4][promo_amt_col_num]
            assert_nil @csv_data[5][promo_amt_col_num]
            assert_nil @csv_data[6][promo_amt_col_num]
            
            promo_exp_date_col_num = purchase_column_number_for("Promo Code Expiry Date")
            assert_equal "2012-07-13", @csv_data[1][promo_exp_date_col_num]
            assert_nil @csv_data[2][promo_exp_date_col_num]
            assert_nil @csv_data[3][promo_exp_date_col_num]
            assert_nil @csv_data[4][promo_exp_date_col_num]
            assert_nil @csv_data[5][promo_exp_date_col_num]
            assert_nil @csv_data[6][promo_exp_date_col_num]

            merchant_zip_col_num = purchase_column_number_for("Merchant Zip")
            assert_nil @csv_data[1][merchant_zip_col_num]
            assert_nil @csv_data[2][merchant_zip_col_num]
            assert_nil @csv_data[3][merchant_zip_col_num]
            assert_equal "90210", @csv_data[4][merchant_zip_col_num]
            assert_nil @csv_data[5][merchant_zip_col_num]
            assert_nil @csv_data[6][merchant_zip_col_num]
          end

        end

      end

      context "when run in incremental mode (ENV['INCREMENTAL'] non-blank)" do

        setup do
          ENV['INCREMENTAL'] = "1"

          Factory :job, :key => "entercom:generate_purchases_and_refunds_csv",
                  :started_at => Time.parse("2011-08-10T12:53:50Z"),
                  :finished_at => Time.parse("2011-08-10T12:58:50Z"),
                  :increment_timestamp => Time.parse("2011-08-10T12:53:50Z"),
                  :file_name => "/some/file/name"

          Timecop.freeze(Time.parse("2011-09-12T12:10:19Z")) do
            @csv_filename = Export::Entercom::PurchasesAndRefunds.export_to_csv!
            @csv_data = FasterCSV.read(@csv_filename)
          end
        end

        teardown do
          ENV['INCREMENTAL'] = nil
          remove_file(@csv_filename)
        end

        should "return only rows whose executed_at is > the last " +
               "increment_timestamp and <= the current increment_timestamp" do
          assert_equal 3, @csv_data[1..-1].size
          order_date_col_num = purchase_column_number_for("Order Date")

          assert_equal "2011-09-10", @csv_data[1][order_date_col_num], @csv_data[1]
          assert_equal "2011-09-11", @csv_data[2][order_date_col_num], @csv_data[2]
          assert_equal "2011-09-12", @csv_data[3][order_date_col_num], @csv_data[3]

          tx_type_col_num = purchase_column_number_for("Type")
          assert_equal "P", @csv_data[1][tx_type_col_num]
          assert_equal "P", @csv_data[2][tx_type_col_num]
          assert_equal "P", @csv_data[3][tx_type_col_num]
        end

      end

    end

    context "Export::Entercom::Signups.export_to_csv!" do

      setup do
        @entercom_providence_s1 = Factory :subscriber, :publisher => @entercom_providence, :email => "ep_s1@example.com",
                                          :created_at => Time.parse("2011-09-10T11:33:56Z")
        @entercom_providence_s2 = Factory :subscriber, :publisher => @entercom_providence, :email => "ep_s2@example.com",
                                          :created_at => Time.parse("2011-09-11T11:33:56Z"), :address_line_1 => "1 Infinite Loop",
                                          :state => "CA"
        @entercom_sacramento_s1 = Factory :subscriber, :publisher => @entercom_sacramento, :email => "es_s1@example.com",
                                          :created_at => Time.parse("2011-09-12T11:33:56Z")
        
        @nydn_s1 = Factory :subscriber, :publisher => @nydn, :created_at => Time.parse("2011-09-13T11:33:56Z")
      end

      context "job logging" do

        teardown do
          ENV['INCREMENTAL'] = nil
        end

        should "create a Job record to log a full run, leaving the increment_timestamp blank" do
          begin
            assert_difference "Job.count", 1 do
              @csv_filename = Export::Entercom::Signups.export_to_csv!
            end

            assert_equal 1, Job.count
            job = Job.first
            assert_equal "entercom:generate_signups_csv", job.key
            assert_equal @csv_filename, job.file_name
            assert job.increment_timestamp.blank?
            assert job.publisher.blank?
          ensure
            remove_file(@csv_filename)
          end
        end

        should "create a Job record to log an incremental run, and populate the increment_timestamp" do
          ENV['INCREMENTAL'] = "1"
          
          begin
            assert_difference "Job.count", 1 do
              @csv_filename = Export::Entercom::Signups.export_to_csv!
            end

            assert_equal 1, Job.count
            job = Job.first
            assert_equal "entercom:generate_signups_csv", job.key
            assert_equal @csv_filename, job.file_name
            assert job.increment_timestamp.present?
            assert job.publisher.blank?
          ensure
            remove_file(@csv_filename)
          end
        end

      end

      context "when run in cumulative mode" do

        setup do
          add_zip_code_for_consumer_without_remote_record_id
          Timecop.freeze(Time.parse("2011-09-13T11:33:56Z")) do
            @csv_filename = Export::Entercom::Signups.export_to_csv!
          end
          @csv_data = FasterCSV.read(@csv_filename)
        end

        teardown do
          remove_file(@csv_filename)
        end

        should "return a String that is the filename of the generated CSV file" do
          assert @csv_filename.is_a?(String)
          assert_equal Rails.root.join("tmp", "entercomnew-subs-and-consumers-20110913113356.csv").to_s,
                       @csv_filename
        end

        context "the data written to the CSV file" do

          should "contain only consumers that have zip codes *and* remote record IDs" do
            assert_equal expected_signups_headers, @csv_data[0]
            assert_equal 1, @csv_data[1..-1].size
            assert @csv_data.all? { |row| row.size == 3 }

            member_id_col_num = signup_column_for("Member ID")
            assert_equal "remote-id-ep-c1", @csv_data[1][member_id_col_num]
            
            email_col_num = signup_column_for("Email")
            assert_equal "ep_c1@example.com", @csv_data[1][email_col_num]
            
            zip_code_col_num = signup_column_for("Zip")
            assert_equal "12345", @csv_data[1][zip_code_col_num]
          end
          
        end
        
      end

    end
    
    context "Export::Entercom::Merchants.export_to_csv!" do

      context "job logging" do

        should "create a Job record to log a full run, leaving the increment_timestamp blank" do
          begin
            assert_difference "Job.count", 1 do
              @csv_filename = Export::Entercom::Merchants.export_to_csv!
            end

            assert_equal 1, Job.count
            job = Job.first
            assert_equal "entercom:generate_merchants_csv", job.key
            assert_equal @csv_filename, job.file_name
            assert job.increment_timestamp.blank?
            assert job.publisher.blank?
          ensure
            remove_file(@csv_filename)
          end
        end

      end

      context "when run in cumulative mode" do

        setup do
          ENV["INCREMENTAL"] = nil
          
          Timecop.freeze(Time.parse("2011-09-13T11:33:56Z")) do
            @csv_filename = Export::Entercom::Merchants.export_to_csv!
          end
          @csv_data = FasterCSV.read(@csv_filename)
        end

        teardown do
          remove_file(@csv_filename)
        end

        should "return a String that is the filename of the generated CSV file" do
          assert @csv_filename.is_a?(String)
          assert_equal Rails.root.join("tmp", "entercom-merchants-20110913113356.csv").to_s,
                       @csv_filename
        end

        context "the data written to the CSV file" do

          should "contain the merchant data, ordered by deal start at ASC" do
            assert_equal expected_merchants_headers, @csv_data[0]

            assert_equal 5, @csv_data[1..-1].size
            assert @csv_data.all? { |row| row.size == 16 }
            
            start_date_col_num = merchants_column_for("Deal Start Date")
            assert_equal "2011-09-09", @csv_data[1][start_date_col_num]
            assert_equal "2011-09-10", @csv_data[2][start_date_col_num]
            assert_equal "2011-09-10", @csv_data[3][start_date_col_num]
            assert_equal "2011-09-11", @csv_data[4][start_date_col_num]
            assert_equal "2011-09-11", @csv_data[5][start_date_col_num]
            
            deal_id_col_num = merchants_column_for("Deal ID")
            assert_equal @entercom_sacramento_a1_d1.id.to_s, @csv_data[1][deal_id_col_num]
            assert_equal @entercom_providence_a1_d1.id.to_s, @csv_data[2][deal_id_col_num]
            assert_equal @entercom_providence_a1_d2.id.to_s, @csv_data[3][deal_id_col_num]
            assert_equal @entercom_newengland_a1_d1.id.to_s, @csv_data[4][deal_id_col_num]
            assert_equal @entercom_newengland_a1_d1.id.to_s, @csv_data[5][deal_id_col_num]
            
            market_col_num = merchants_column_for("Market")
            assert_equal "entercom-sacramento", @csv_data[1][market_col_num]
            assert_equal "entercom-providence", @csv_data[2][market_col_num]
            assert_equal "entercom-providence", @csv_data[3][market_col_num]
            assert_equal "entercom-newengland", @csv_data[4][market_col_num]
            assert_equal "entercom-newengland", @csv_data[5][market_col_num]

            advertiser_id_col_num = merchants_column_for("Advertiser ID")
            assert_equal @entercom_sacramento_a1.id.to_s, @csv_data[1][advertiser_id_col_num]
            assert_equal @entercom_providence_a1.id.to_s, @csv_data[2][advertiser_id_col_num]
            assert_equal @entercom_providence_a1.id.to_s, @csv_data[3][advertiser_id_col_num]
            assert_equal @entercom_newengland_a1.id.to_s, @csv_data[4][advertiser_id_col_num]
            assert_equal @entercom_newengland_a1.id.to_s, @csv_data[5][advertiser_id_col_num]

            advertiser_col_num = merchants_column_for("Advertiser")
            assert_equal @entercom_sacramento_a1.name, @csv_data[1][advertiser_col_num]
            assert_equal @entercom_providence_a1.name, @csv_data[2][advertiser_col_num]
            assert_equal @entercom_providence_a1.name, @csv_data[3][advertiser_col_num]
            assert_equal @entercom_newengland_a1.name, @csv_data[4][advertiser_col_num]
            assert_equal @entercom_newengland_a1.name, @csv_data[5][advertiser_col_num]

            value_prop_col_num = merchants_column_for("Value Prop")
            assert_equal "es a1 d1", @csv_data[1][value_prop_col_num]
            assert_equal "ep a1 d1", @csv_data[2][value_prop_col_num]
            assert_equal "ep a1 d2", @csv_data[3][value_prop_col_num]
            assert_equal "en a1 d1", @csv_data[4][value_prop_col_num]
            assert_equal "en a1 d1", @csv_data[5][value_prop_col_num]

            rev_share_col_num = merchants_column_for("Advertiser Rev Share")
            assert_nil @csv_data[1][rev_share_col_num]
            assert_equal "25.00", @csv_data[2][rev_share_col_num]
            assert_nil @csv_data[3][rev_share_col_num]
            assert_nil @csv_data[4][rev_share_col_num]
            assert_nil @csv_data[5][rev_share_col_num]

            merchant_contact_col_num = merchants_column_for("Merchant Contact")
            assert_nil @csv_data[1][merchant_contact_col_num]
            assert_equal "ep a1 mcn", @csv_data[2][merchant_contact_col_num]
            assert_equal "ep a1 mcn", @csv_data[3][merchant_contact_col_num]
            assert_equal "en a1 mcn", @csv_data[4][merchant_contact_col_num]
            assert_equal "en a1 mcn", @csv_data[5][merchant_contact_col_num]

            merchant_email_col_num = merchants_column_for("Merchant Email Address")
            assert_nil @csv_data[1][merchant_email_col_num]
            assert_equal "epa1@example.com", @csv_data[2][merchant_email_col_num]
            assert_equal "epa1@example.com", @csv_data[3][merchant_email_col_num]
            assert_nil @csv_data[4][merchant_email_col_num]
            assert_nil @csv_data[5][merchant_email_col_num]

            phone_col_num = merchants_column_for("Phone #")
            assert_equal "15124161500", @csv_data[1][phone_col_num]
            assert_equal "15124161500", @csv_data[2][phone_col_num]
            assert_equal "15124161500", @csv_data[3][phone_col_num]
            assert_equal "15124161500", @csv_data[4][phone_col_num]
            assert_equal "15124161500", @csv_data[5][phone_col_num]

            address_1_col_num = merchants_column_for("Address 1")
            assert_equal "3005 South Lamar", @csv_data[1][address_1_col_num]
            assert_equal "3005 South Lamar", @csv_data[2][address_1_col_num]
            assert_equal "3005 South Lamar", @csv_data[3][address_1_col_num]
            assert_equal "3005 South Lamar", @csv_data[4][address_1_col_num]
            assert_equal "3005 South Lamar", @csv_data[5][address_1_col_num]

            address_2_col_num = merchants_column_for("Address 2")
            assert_equal "Apt 1", @csv_data[1][address_2_col_num]
            assert_equal "Apt 1", @csv_data[2][address_2_col_num]
            assert_equal "Apt 1", @csv_data[3][address_2_col_num]
            assert_equal "Apt 1", @csv_data[4][address_2_col_num]
            assert_equal "Apt 1", @csv_data[5][address_2_col_num]

            city_col_num = merchants_column_for("City")
            assert_equal "Austin", @csv_data[1][city_col_num]
            assert_equal "Austin", @csv_data[2][city_col_num]
            assert_equal "Austin", @csv_data[3][city_col_num]
            assert_equal "Austin", @csv_data[4][city_col_num]
            assert_equal "Austin", @csv_data[5][city_col_num]

            state_col_num = merchants_column_for("State")
            assert_equal "TX", @csv_data[1][state_col_num]
            assert_equal "TX", @csv_data[2][state_col_num]
            assert_equal "TX", @csv_data[3][state_col_num]
            assert_equal "TX", @csv_data[4][state_col_num]
            assert_equal "TX", @csv_data[5][state_col_num]

            zip_col_num = merchants_column_for("Zip")
            assert_equal "78704", @csv_data[1][zip_col_num]
            assert_equal "78704", @csv_data[2][zip_col_num]
            assert_equal "78704", @csv_data[3][zip_col_num]
            assert_equal "78704", @csv_data[4][zip_col_num]
            assert_equal "90210", @csv_data[5][zip_col_num]

            ae_col_num = merchants_column_for("AE")
            assert_nil @csv_data[1][ae_col_num]
            assert_equal "Phil Ivey", @csv_data[2][ae_col_num]
            assert_nil @csv_data[3][ae_col_num]
            assert_nil @csv_data[4][ae_col_num]
            assert_nil @csv_data[5][ae_col_num]
          end

        end

      end
      
    end
    
    context "Export::Entercom::Merchants.export_to_csv!, with multiple batch selects" do
      
      setup do
        Export::Entercom::Merchants.stubs(:default_batch_size).returns(2)
      end
      
      should "call process_batch three times" do
        begin
          Export::Entercom::Merchants.expects(:process_batch).times(3)
          csv_filename = Export::Entercom::Merchants.export_to_csv!
        ensure
          remove_file(csv_filename) if defined?(csv_filename)
        end
      end
      
      should "return all the expected rows" do
        begin
          csv_filename = Export::Entercom::Merchants.export_to_csv!
          csv_data = FasterCSV.read(csv_filename)

          value_prop_col_num = merchants_column_for("Value Prop")
          assert_equal "es a1 d1", csv_data[1][value_prop_col_num]
          assert_equal "ep a1 d1", csv_data[2][value_prop_col_num]
          assert_equal "ep a1 d2", csv_data[3][value_prop_col_num]
          assert_equal "en a1 d1", csv_data[4][value_prop_col_num]
          assert_equal "en a1 d1", csv_data[5][value_prop_col_num]
        ensure
          remove_file(csv_filename) if defined?(csv_filename)
        end
      end
      
    end
    
    context "Export::Entercom::PurchasesAndRefunds.upload_csv!" do
      
      should "call export_to_csv! and Uploader methods with relevant config" do
        Export::Entercom::PurchasesAndRefunds.expects(:export_to_csv!).once.returns("/some/test/file.csv")
        Export::Entercom::PurchasesAndRefunds.stubs(:ensure_file_exists!).returns(nil)
        Export::Entercom::PurchasesAndRefunds.stubs(:gzip_file).returns("/some/test/file.csv.gz")
        
        fake_uploader = Object.new
        fake_uploader.expects(:upload).with("entercom", "/some/test/file.csv.gz")
        Uploader.
          expects(:new).
          with({ "entercom" => { :protocol => "sftp", :host => "209.208.243.10", :user => "analoganalytics", :pass => "1muIs8DLCt" } }).
          returns(fake_uploader)
        
        Export::Entercom::PurchasesAndRefunds.upload_csv!
      end
      
    end
    
    context "Export::Entercom::Signups.upload_csv!" do
      
      should "call export_to_csv! and Uploader methods with relevant config" do
        Export::Entercom::Signups.expects(:export_to_csv!).once.returns("/some/test/file.csv")
        Export::Entercom::Signups.stubs(:ensure_file_exists!).returns(nil)
        Export::Entercom::Signups.stubs(:gzip_file).returns("/some/test/file.csv.gz")
        
        fake_uploader = Object.new
        fake_uploader.expects(:upload).with("entercom", "/some/test/file.csv.gz")
        Uploader.
          expects(:new).
          with({ "entercom" => { :protocol => "sftp", :host => "209.208.243.10", :user => "analoganalytics", :pass => "1muIs8DLCt" } }).
          returns(fake_uploader)
        
        Export::Entercom::Signups.upload_csv!
      end
      
    end
    
    context "Export::Entercom::Merchants.upload_csv!" do
      
      should "call export_to_csv! and Uploader methods with relevant config" do
        Export::Entercom::Merchants.expects(:export_to_csv!).once.returns("/some/test/file.csv")
        Export::Entercom::Merchants.stubs(:ensure_file_exists!).returns(nil)
        Export::Entercom::Merchants.stubs(:gzip_file).returns("/some/test/file.csv.gz")
        
        fake_uploader = Object.new
        fake_uploader.expects(:upload).with("entercom", "/some/test/file.csv.gz")
        Uploader.
          expects(:new).
          with({ "entercom" => { :protocol => "sftp", :host => "209.208.243.10", :user => "analoganalytics", :pass => "1muIs8DLCt" } }).
          returns(fake_uploader)
        
        Export::Entercom::Merchants.upload_csv!
      end
      
    end
    
    def expected_purchase_and_refunds_headers
      ["Type", "Order ID", "Order Date", "Consumer ID", "Member ID", "Email",
       "Market", "Deal ID", "Advertiser ID", "Advertiser", "Value Prop", "Category",
       "Price", "Deals Purchased", "Order Value", "Advertiser Rev Share", "Promo Code Name",
       "Promo Code Amount", "Promo Code Expiry Date", "Merchant Name", "Merchant Zip"]
    end

    def expected_signups_headers
      ["Zip", "Email", "Member ID"]
    end
    
    def expected_merchants_headers
      ["Deal Start Date", "Deal ID", "Market", "Advertiser ID", "Advertiser", "Value Prop",
       "Advertiser Rev Share", "Merchant Contact", "Merchant Email Address", "Phone #",
       "Address 1", "Address 2", "City", "State", "Zip", "AE"]
    end

    def purchase_column_number_for(column_label)
      Export::Entercom::PurchasesAndRefunds::get_column_label_index(column_label)
    end

    def signup_column_for(column_label)
      Export::Entercom::Signups::get_column_label_index(column_label)
    end
    
    def merchants_column_for(column_label)
      Export::Entercom::Merchants::get_column_label_index(column_label)
    end
    
    def remove_file(filename)
      File.unlink(filename) if filename.present? && File.exists?(filename)
    end
    
    def add_zip_code_for_consumer_without_remote_record_id
      @entercom_sacramento_a1_d1_r1.daily_deal_payment.update_attribute :payer_postal_code, "42444"
    end

  end

end