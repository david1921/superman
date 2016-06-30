require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Publishers::ExportTest

module Publishers
  class ExportTest < ActiveSupport::TestCase

    context "Publisher daily deal exports for NYDN" do

      setup do
        @nydn = Factory :publisher, :label => "nydailynews"
        @other_publisher = Factory :publisher, :label => "examplepub"    

        @advertiser_1 = Factory :advertiser, :name => "Advertiser One", :publisher_id => @nydn.id
        @advertiser_2 = Factory :advertiser, :name => "Advertiser Two", :publisher_id => @nydn.id 
        @non_nydn_advertiser_1 = Factory :advertiser, :publisher_id => @other_publisher.id
        @non_nydn_advertiser_2 = Factory :advertiser, :publisher_id => @other_publisher.id

        @b = DailyDealCategory.create!(:name => "Beauty", :abbreviation => "B")
        @th = DailyDealCategory.create!(:name => "Theater", :abbreviation => "TH")
        @a = DailyDealCategory.create!(:name => "Activities", :abbreviation => "A")
        @daily_deal_1 = Factory :daily_deal, :advertiser_id => @advertiser_1.id, :value_proposition => "Great Deal #1", :analytics_category => @b
        @daily_deal_2 = Factory :side_daily_deal, :advertiser_id => @advertiser_2.id, :value_proposition => "Great Deal #2", :analytics_category => @th
        @daily_deal_3 = Factory :side_daily_deal, :advertiser_id => @advertiser_2.id, :value_proposition => "Great Deal #3", :analytics_category => @a

        @non_nydn_daily_deal_1 = Factory :daily_deal, :advertiser_id => @non_nydn_advertiser_1.id, :value_proposition => "Great Deal #1 from another publisher"
        
        column_names = Publisher.nydn_export_column_names
        @tx_type_idx = column_names.index("TX_TYPE")
        @tx_total_idx = column_names.index("DD_TOTAL_COST")
        @qty_idx = column_names.index("DD_QTY")
        @email_idx = column_names.index("email")
        @value_prop_idx = column_names.index("DD_DEAL")
        @dd_date_idx = column_names.index("DD_DATE")
      end

      context "#daily_deal_purchases_and_consumers_and_subscribers" do

        context "with no purchases, consumers, or subscribers" do

          should "return nil" do
            assert_equal [], @nydn.daily_deal_purchases_and_consumers_and_subscribers
          end

        end

        context "with captured, voided, refunded, and authorized purchases, but no additional consumers or subscribers" do

          setup do
            create_consumers
            create_captured_voided_and_authorized_purchases
            create_refunded_purchases
          end

          should "return the fields required by customers for the DDP/consumers/subscribers export" do
            results = @nydn.daily_deal_purchases_and_consumers_and_subscribers
            first_result = results.first
            %w(email first_name last_name zip_code recipient_names address_line_1 address_line_2 city state
               value_proposition category price card_type quantity created_at).each do |field_name|
              assert first_result.has_key?(field_name), "daily deal purchase export result has key '#{field_name}1"
            end
          end

          should "return only the captured and refunded purchases" do
            results = @nydn.daily_deal_purchases_and_consumers_and_subscribers

            assert_equal 8, results.size
            assert_equal "Test", results[0]['first_name']
            assert_equal "Cons3", results[0]['last_name']
            assert_equal "", results[0]['value_proposition']

            assert_equal "Test", results[1]['first_name']
            assert_equal "Cons4", results[1]['last_name']
            assert_equal "", results[1]['value_proposition']

            assert_equal "Great Deal #1", results[2]['value_proposition']
            assert_equal "B", results[2]['category']
            assert_equal "Vancouver", results[2]['city']
            assert_equal "BC", results[2]['state']
            assert_equal "100 Example Road", results[2]['address_line_1']
            assert_equal "P", results[2]['rec_type']

            assert_equal "Great Deal #2", results[3]['value_proposition']
            assert_equal "TH", results[3]['category']
            assert_equal "Las Vegas", results[3]['city']
            assert_equal "NV", results[3]['state']
            assert_equal "1234 Las Vegas Boulevard", results[3]['address_line_1']
            assert_equal "P", results[3]['rec_type']

            assert_equal "Great Deal #1", results[4]['value_proposition']
            assert_equal "B", results[4]['category']
            assert_equal "Vancouver", results[4]['city']
            assert_equal "BC", results[4]['state']
            assert_equal "100 Example Road", results[4]['address_line_1']
            assert_equal "P", results[4]['rec_type']

            assert_equal "Great Deal #2", results[5]['value_proposition']
            assert_equal "TH", results[5]['category']
            assert_equal "Las Vegas", results[5]['city']
            assert_equal "NV", results[5]['state']
            assert_equal "1234 Las Vegas Boulevard", results[5]['address_line_1']
            assert_equal "P", results[5]['rec_type']
            
            assert_equal "Great Deal #1", results[6]['value_proposition']
            assert_equal "B", results[6]['category']
            assert_equal "Vancouver", results[6]['city']
            assert_equal "BC", results[6]['state']
            assert_equal "100 Example Road", results[6]['address_line_1']
            assert_equal "R", results[6]['rec_type']

            assert_equal "Great Deal #2", results[7]['value_proposition']
            assert_equal "TH", results[7]['category']
            assert_equal "Las Vegas", results[7]['city']
            assert_equal "NV", results[7]['state']
            assert_equal "1234 Las Vegas Boulevard", results[7]['address_line_1']
            assert_equal "R", results[7]['rec_type']
          end
          
          should "return a negative actual_purchase_price for refunds" do
            results = @nydn.daily_deal_purchases_and_consumers_and_subscribers

            assert_equal "Great Deal #1", results[6]['value_proposition']
            assert_equal "R", results[6]['rec_type']
            assert_equal "-15.00", results[6]['actual_purchase_price']

            assert_equal "Great Deal #2", results[7]['value_proposition']
            assert_equal "R", results[7]['rec_type']
            assert_equal "-45.00", results[7]['actual_purchase_price']
          end
          
          should "return a negative quantity for refunds" do
            results = @nydn.daily_deal_purchases_and_consumers_and_subscribers
            
            assert_equal "Great Deal #1", results[6]['value_proposition']
            assert_equal "R", results[6]['rec_type']
            assert_equal "-1", results[6]['quantity']

            assert_equal "Great Deal #2", results[7]['value_proposition']
            assert_equal "R", results[7]['rec_type']
            assert_equal "-3", results[7]['quantity']            
          end

          context "with more than one purchase made by the same consumer" do

            setup do
              funky_deal = Factory :side_daily_deal, :publisher_id => @nydn.id, :value_proposition => "A Funky Deal", :analytics_category => @a
              @consumer_1.email = "multiple-purchases@example.com"
              @consumer_1.save!
              Factory :captured_daily_deal_purchase, :daily_deal_id => funky_deal.id, :consumer_id => @consumer_1.id          
            end

            should "return all the transactions" do
              results = @nydn.daily_deal_purchases_and_consumers_and_subscribers
              assert_equal 9, results.size

              assert_equal "Test", results[0]['first_name']
              assert_equal "Cons3", results[0]['last_name']
              assert_equal "", results[0]['value_proposition']

              assert_equal "Test", results[1]['first_name']
              assert_equal "Cons4", results[1]['last_name']
              assert_equal "", results[1]['value_proposition']

              assert_equal "Great Deal #1", results[2]['value_proposition']
              assert_equal "multiple-purchases@example.com", results[2]['email']
              assert_equal "Vancouver", results[2]['city']
              assert_equal "BC", results[2]['state']
              assert_equal "100 Example Road", results[2]['address_line_1']
              assert_equal "P", results[2]['rec_type']

              assert_equal "Great Deal #2", results[3]['value_proposition']
              assert_equal "Las Vegas", results[3]['city']
              assert_equal "NV", results[3]['state']
              assert_equal "1234 Las Vegas Boulevard", results[3]['address_line_1']
              assert_equal "P", results[3]['rec_type']
              
              assert_equal "Great Deal #1", results[4]['value_proposition']
              assert_equal "multiple-purchases@example.com", results[4]['email']
              assert_equal "Vancouver", results[4]['city']
              assert_equal "BC", results[4]['state']
              assert_equal "100 Example Road", results[4]['address_line_1']
              assert_equal "P", results[4]['rec_type']

              assert_equal "Great Deal #2", results[5]['value_proposition']
              assert_equal "Las Vegas", results[5]['city']
              assert_equal "NV", results[5]['state']
              assert_equal "1234 Las Vegas Boulevard", results[5]['address_line_1']
              assert_equal "P", results[5]['rec_type']
              
              assert_equal "A Funky Deal", results[6]['value_proposition']
              assert_equal "multiple-purchases@example.com", results[6]['email']
              assert_equal "Vancouver", results[6]['city']
              assert_equal "BC", results[6]['state']
              assert_equal "100 Example Road", results[6]['address_line_1']
              assert_equal "P", results[6]["rec_type"]
              
              assert_equal "Great Deal #1", results[7]['value_proposition']
              assert_equal "B", results[7]['category']
              assert_equal "Vancouver", results[7]['city']
              assert_equal "BC", results[7]['state']
              assert_equal "100 Example Road", results[7]['address_line_1']
              assert_equal "R", results[7]['rec_type']

              assert_equal "Great Deal #2", results[8]['value_proposition']
              assert_equal "TH", results[8]['category']
              assert_equal "Las Vegas", results[8]['city']
              assert_equal "NV", results[8]['state']
              assert_equal "1234 Las Vegas Boulevard", results[8]['address_line_1']
              assert_equal "R", results[8]['rec_type']
            end

          end

        end

        context "with purchases and other consumers that haven't bought anything yet, but no subscribers" do

          setup do
            create_captured_voided_and_authorized_purchases
            create_consumers_without_purchases        
          end

          should "return the *active* consumers that haven't bought anything, followed by purchases with their consumer details" do
            results = @nydn.daily_deal_purchases_and_consumers_and_subscribers
            assert_equal 6, results.size

            assert_equal "Test", results[0]['first_name']
            assert_equal "Cons3", results[0]['last_name']
            assert_equal "", results[0]['value_proposition']

            assert_equal "Test", results[1]['first_name']
            assert_equal "Cons4", results[1]['last_name']
            assert_equal "", results[1]['value_proposition']

            assert_equal "Active1", results[2]['first_name']
            assert_equal "Consumer1", results[2]['last_name']
            assert_equal "", results[2]['value_proposition']

            assert_equal "Active2", results[3]['first_name']
            assert_equal "Consumer2", results[3]['last_name']
            assert_equal "", results[3]['value_proposition']

            assert_equal "Great Deal #1", results[4]['value_proposition']
            assert_equal "Great Deal #2", results[5]['value_proposition']
          end

        end

        context "with purchases, consumers, and subscribers" do

          setup do
            create_captured_voided_and_authorized_purchases
            create_consumers_without_purchases
            create_subscribers
          end

          should "return the subscribers, active consumers, and purchases with consumer details" do
            results = @nydn.daily_deal_purchases_and_consumers_and_subscribers
            assert_equal 8, results.size

            assert_match /subscriber\d+@example\.com/, results[0]['email']
            assert_equal "", results[0]['value_proposition']

            assert_match /subscriber\d+@example\.com/, results[1]['email']
            assert_equal "", results[1]['value_proposition']

            assert_equal "Test", results[2]['first_name']
            assert_equal "Cons3", results[2]['last_name']
            assert_equal "", results[2]['value_proposition']

            assert_equal "Test", results[3]['first_name']
            assert_equal "Cons4", results[3]['last_name']
            assert_equal "", results[3]['value_proposition']        

            assert_equal "Active1", results[4]['first_name']
            assert_equal "Consumer1", results[4]['last_name']
            assert_equal "", results[4]['value_proposition']

            assert_equal "Active2", results[5]['first_name']
            assert_equal "Consumer2", results[5]['last_name']
            assert_equal "", results[5]['value_proposition']

            assert_equal "Great Deal #1", results[6]['value_proposition']
            assert_equal "Great Deal #2", results[7]['value_proposition']
          end

        end

        context "with subscribers, but no purchases or consumers" do

          setup do
            create_subscribers
          end

          should "return only subscribers" do
            results = @nydn.daily_deal_purchases_and_consumers_and_subscribers
            assert_equal 2, results.size

            assert_equal "subscriber1@example.com", results[0]['email']
            assert_equal "", results[0]['value_proposition']

            assert_equal "subscriber2@example.com", results[1]['email']
            assert_equal "", results[1]['value_proposition']
          end

        end

        context "with subscribers and consumers, but no purchases yet" do

          setup do
            create_subscribers
            create_consumers_without_purchases
          end

          should "return the subscribers, followed by the consumers" do
            results = @nydn.daily_deal_purchases_and_consumers_and_subscribers
            assert_equal 4, results.size

            assert_match /subscriber\d+@example\.com/, results[0]['email']
            assert_equal "", results[0]['value_proposition']

            assert_match /subscriber\d+@example\.com/, results[1]['email']
            assert_equal "", results[1]['value_proposition']

            assert_equal "Active1", results[2]['first_name']
            assert_equal "Consumer1", results[2]['last_name']
            assert_equal "", results[2]['value_proposition']

            assert_equal "Active2", results[3]['first_name']
            assert_equal "Consumer2", results[3]['last_name']
            assert_equal "", results[3]['value_proposition']
          end

        end

        context "when there are duplicate email addresses between subscribers and consumers" do

          setup do
            @sub_who_becomes_consumer = Factory :subscriber, :email => "sub1@example.com", :publisher_id => @nydn.id
            @normal_sub = Factory :subscriber, :email => "sub2@example.com", :publisher_id => @nydn.id
            @consumer_who_was_subscriber = Factory :consumer, :email => "sub1@example.com", :first_name => "Brad",
                                                   :last_name => "Bollenbach", :publisher_id => @nydn.id
          end

          should "return return consumer info in preference to subscriber info, when a consumer is also a subscriber" do
            results = @nydn.daily_deal_purchases_and_consumers_and_subscribers
            assert_equal 2, results.size

            assert_equal "sub2@example.com", results[0]['email']
            assert_equal "", results[0]['value_proposition']

            assert_equal "sub1@example.com", results[1]['email']
            assert_equal "Brad", results[1]['first_name']
            assert_equal "Bollenbach", results[1]['last_name']
          end

        end

        context "date filtering" do

          setup do
            @to_timestamp = Time.now

            @s1 = Factory :subscriber, :publisher_id => @nydn.id, :email => "s1@example.com", :created_at => @to_timestamp - 10.minutes
            @s2 = Factory :subscriber, :publisher_id => @nydn.id, :email => "s2@example.com", :created_at => @to_timestamp - 1.second
            @s3 = Factory :subscriber, :publisher_id => @nydn.id, :email => "s3@example.com", :created_at => @to_timestamp
            @s4 = Factory :subscriber, :publisher_id => @nydn.id, :email => "s4@example.com", :created_at => @to_timestamp + 1.second

            @c1 = Factory :consumer, :publisher_id => @nydn.id, :email => "c1@example.com",
                          :created_at => @to_timestamp - 1.day, :activated_at => @to_timestamp - 1.day
            @c2 = Factory :consumer, :publisher_id => @nydn.id, :email => "c2@example.com",
                          :created_at => @to_timestamp, :activated_at => @to_timestamp
            @c3 = Factory :consumer, :publisher_id => @nydn.id, :email => "c3@example.com",
                          :created_at => @to_timestamp + 1.second, :activated_at => @to_timestamp + 1.second

            @ddp1 = Factory :captured_daily_deal_purchase, :daily_deal_id => @daily_deal_1.id, :consumer_id => @c1.id, :created_at => @to_timestamp - 1.day
            @ddp2 = Factory :captured_daily_deal_purchase, :daily_deal_id => @daily_deal_1.id, :consumer_id => @c2.id, :created_at => @to_timestamp
            @ddp3 = Factory :captured_daily_deal_purchase, :daily_deal_id => @daily_deal_2.id, :consumer_id => @c1.id, :created_at => @to_timestamp + 3.minutes
          end

          context "with only a :to parameter" do

            should "return only records whose created_at is <= the :to value" do
              results = @nydn.daily_deal_purchases_and_consumers_and_subscribers(:to => @to_timestamp)
              expected = [
                ["s1@example.com", ""], ["s2@example.com", ""], ["s3@example.com", ""],
                ["c1@example.com", "Great Deal #1"], ["c2@example.com", "Great Deal #1"]
              ]
              assert_equal expected, results.map { |r| [r["email"], r["value_proposition"]] }
            end

          end

          context "with :from and :to parameters" do

            should "return only records whose created_at is > :from and <= :to" do
              results = @nydn.daily_deal_purchases_and_consumers_and_subscribers(:from => @to_timestamp - 10.minutes, :to => @to_timestamp)
              expected = [["s2@example.com", ""], ["s3@example.com", ""], ["c2@example.com", "Great Deal #1"]]
              assert_equal expected, results.map { |r| [r["email"], r["value_proposition"]] }
            end

          end

          context "with only a :from parameter" do

            should "return only records created *after* the :from timestamp" do
              results = @nydn.daily_deal_purchases_and_consumers_and_subscribers(:from => @to_timestamp)
              expected = [["s4@example.com", ""], ["c3@example.com", ""], ["c1@example.com", "Great Deal #2"]]
              assert_equal expected, results.map { |r| [r["email"], r["value_proposition"]] }
            end

          end

        end

        context "with a block" do

          should "not call the block if there are no results" do
            results = []
            @nydn.daily_deal_purchases_and_consumers_and_subscribers do |row|
              results << row
            end
            assert_equal [], results
          end

          should "yield each row of the result to the block" do
            create_subscribers
            create_consumers_without_purchases
            create_captured_voided_and_authorized_purchases

            results = []
            @nydn.daily_deal_purchases_and_consumers_and_subscribers do |row|
              results << row
            end
            assert_equal 8, results.size
            first_result = results.first

            assert first_result.is_a?(Hash)
            assert_match /subscriber\d+@example\.com/, first_result['email']
          end

        end

      end

      context ".export_nydn_purchases_and_consumers!" do

        setup do
          @csv_filename = File.join(Rails.root, "tmp", "nydn_export_test.csv")
        end

        should "dedupe subscribers by email" do
          bob = Factory :subscriber, :publisher_id => @nydn.id, :email => "bob@example.com", :first_name => "Bob", :created_at => 10.seconds.ago
          alice = Factory :subscriber, :publisher_id => @nydn.id, :email => "alice@example.com", :first_name => "Alice"
          bob_dupe = Factory :subscriber, :publisher_id => @nydn.id, :email => "bob@example.com", :first_name => "Bob"

          Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename
          csv_file_lines = File.readlines(@csv_filename)
          assert_equal 3, csv_file_lines.length
          csv_file_lines.sort!
          assert_equal ["alice@example.com", "", "", "97214", "", "", "", "", "", "",
                        "", "", "", "", "", ""], csv_file_lines[0].parse_csv[0..13] + csv_file_lines[0].parse_csv[-2..-1]
          assert_equal ["bob@example.com", "", "", "97214", "", "", "", "", "", "",
                        "", "", "", "", "", ""], csv_file_lines[1].parse_csv[0..13] + csv_file_lines[1].parse_csv[-2..-1]
        end

        should "create a CSV file with the headers requested by NYDN" do
          assert !File.exists?(@csv_filename)
          Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename
          assert File.exists?(@csv_filename)
          csv_file_lines = File.readlines(@csv_filename)
          assert_equal 1, csv_file_lines.length

          assert_equal %w(email first_name last_name zip RecipientName Address1
                          Address2 City State DD_DEAL DD_CATEGORY DD_PRICE
                          DD_CARD_TYPE DD_QTY DD_DATE TX_TYPE DD_ADVERTISER DD_TOTAL_COST
                          CONSUMER_DATE),
                       csv_file_lines[0].parse_csv
        end

        should "output the daily deal purchase, consumer, and subscriber data to that CSV file" do
          create_captured_voided_and_authorized_purchases
          create_consumers_without_purchases
          create_subscribers

          Publisher.stubs(:nydn_purchases_and_consumers_export_filename).returns(@csv_filename)

          Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename
          csv_file_lines = File.readlines(@csv_filename)

          assert_equal 9, csv_file_lines.length

          assert_equal %w(email first_name last_name zip RecipientName Address1
                          Address2 City State DD_DEAL DD_CATEGORY DD_PRICE
                          DD_CARD_TYPE DD_QTY DD_DATE TX_TYPE DD_ADVERTISER DD_TOTAL_COST
                          CONSUMER_DATE),
                       csv_file_lines[0].parse_csv

          assert_equal ["subscriber1@example.com", "", "", "81711", "", "", "", "", "", "",
                        "", "", "", "", "", "", ""], csv_file_lines[1].parse_csv[0..13] + csv_file_lines[1].parse_csv[-3..-1]

          assert_equal ["active_cons1@example.com", "Active1", "Consumer1", "", "", "", "", "",
                        "", "", "", "", "", "", "", "", ""], csv_file_lines[5].parse_csv[0..13] + csv_file_lines[5].parse_csv[-3..-1]

          assert_equal ["cons1@example.com", "Test", "Cons1", "12345", "Tom Sawyer", "100 Example Road", "",
                        "Vancouver", "BC", "Great Deal #1", "B", "15.00", "", "1", "P", "Advertiser One", "15.00",
                        @consumer_1.created_at_before_type_cast], csv_file_lines[7].parse_csv[0..13] + csv_file_lines[7].parse_csv[-4..-1]
        end

        should "output either a numeric value for zip code, or blank, if the stored zip is non-numeric" do
          create_captured_voided_and_authorized_purchases
          create_consumers_without_purchases
          create_subscribers

          @subscriber_1.update_attribute :zip_code, "not a real zip"
          @consumer_1.update_attribute :zip_code, "9181-29"
          
          Publisher.stubs(:nydn_purchases_and_consumers_export_filename).returns(@csv_filename)

          Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename
          csv_file_lines = File.readlines(@csv_filename)

          assert_equal 9, csv_file_lines.length
          assert_equal ["subscriber1@example.com", "", "", "", "", "", "", "", "", "",
                        "", "", "", "", "", "", "", ""], csv_file_lines[1].parse_csv[0..13] + csv_file_lines[1].parse_csv[-4..-1]
          assert_equal ["cons1@example.com", "Test", "Cons1", "", "Tom Sawyer", "100 Example Road", "",
                        "Vancouver", "BC", "Great Deal #1", "B", "15.00", "", "1", "P", "Advertiser One", "15.00",
                        @consumer_1.created_at_before_type_cast], csv_file_lines[7].parse_csv[0..13] + csv_file_lines[7].parse_csv[-4..-1]
          assert_equal ["cons2@example.com", "Test", "Cons2", "67890", "Hank Reardon; Dagny Taggart", "1234 Las Vegas Boulevard", "",
                        "Las Vegas", "NV", "Great Deal #2", "TH", "15.00", "", "2", "P", "Advertiser Two", "30.00",
                        @consumer_2.created_at_before_type_cast], csv_file_lines[8].parse_csv[0..13] + csv_file_lines[8].parse_csv[-4..-1]
        end
        
        should "output negative values for quantity and total cost for refund rows" do
          create_refunded_purchases
          Publisher.stubs(:nydn_purchases_and_consumers_export_filename).returns(@csv_filename)
          Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename
          csv_file_lines = File.readlines(@csv_filename)
          assert_equal 7, csv_file_lines.length
          assert_equal ["cons1@example.com", "Test", "Cons1", "12345", "Tom Sawyer", "100 Example Road", "",
                        "Vancouver", "BC", "Great Deal #1", "B", "15.00", "", "-1", "R", "Advertiser One", "-15.00",
                        @consumer_1.created_at_before_type_cast], csv_file_lines[5].parse_csv[0..13] + csv_file_lines[5].parse_csv[-4..-1]
          assert_equal ["cons2@example.com", "Test", "Cons2", "67890", "Hank Reardon; Dagny Taggart; John Galt", "1234 Las Vegas Boulevard", "",
                        "Las Vegas", "NV", "Great Deal #2", "TH", "15.00", "", "-3", "R", "Advertiser Two", "-45.00",
                        @consumer_2.created_at_before_type_cast], csv_file_lines[6].parse_csv[0..13] + csv_file_lines[6].parse_csv[-4..-1]
        end

        context "when :incremental is set to false (i.e. the default)" do

          should "create a record in the jobs table, which records the job label, start_at, " +
                 "finish_at, leaving increment_timestamp null" do
            assert_equal 0, Job.count
            Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename
            assert_equal 1, Job.count

            job = Job.first

            assert_equal "daily_deals:export_nydn_purchases_and_consumers:nydailynews", job.key
            assert job.started_at.is_a?(ActiveSupport::TimeWithZone)
            assert job.finished_at.is_a?(ActiveSupport::TimeWithZone)
            assert_nil job.increment_timestamp
          end

          should "call daily_deal_purchases_and_consumers_and_subscribers with no args" do
            @nydn.expects(:daily_deal_purchases_and_consumers_and_subscribers).with({})
            Publisher.stubs(:find_by_label).returns(@nydn)
            Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename
          end

        end

        context "when :incremental is set to true" do

          context "when there are no jobs records for this job" do

            setup do
              assert 0, Job.count
              @inc_timestamp = Time.zone.now
              Job.stubs(:increment_timestamp).returns(@inc_timestamp)
            end

            should "create a Job record, populating its increment_timestamp with Job.increment_timestamp" do
              Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename, :incremental => true
              assert_equal 1, Job.count

              job = Job.first
              assert_equal "daily_deals:export_nydn_purchases_and_consumers:nydailynews", job.key
              assert job.started_at.is_a?(ActiveSupport::TimeWithZone)
              assert job.finished_at.is_a?(ActiveSupport::TimeWithZone)
              assert job.increment_timestamp.is_a?(ActiveSupport::TimeWithZone)

              assert_equal @inc_timestamp.to_s, job.increment_timestamp.to_s
            end

            should "pass :to => increment_timestamp to daily_deal_purchases_and_consumers_and_subscribers" do
              @nydn.expects(:daily_deal_purchases_and_consumers_and_subscribers).with do |options|
                (options.keys == [:to]) && (options[:to].to_s == @inc_timestamp.to_s)
              end
              Publisher.stubs(:find_by_label).returns(@nydn)
              Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename, :incremental => true
            end

          end

          context "when there is a job record for this job, but no increment_timestamp" do

            setup do
              now = Time.zone.now
              Job.create! :key => "daily_deals:export_nydn_purchases_and_consumers:nydailynews",
                          :started_at => now - 1.minute, :finished_at => now
              assert_equal 1, Job.count

              @inc_timestamp = Time.zone.now
              Job.stubs(:increment_timestamp).returns(@inc_timestamp)
            end

            should "create a Job record, populating its increment_timestamp with Job.increment_timestamp" do
              Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename, :incremental => true
              assert_equal 2, Job.count

              job = Job.last
              assert_equal "daily_deals:export_nydn_purchases_and_consumers:nydailynews", job.key
              assert job.started_at.is_a?(ActiveSupport::TimeWithZone)
              assert job.finished_at.is_a?(ActiveSupport::TimeWithZone)
              assert job.increment_timestamp.is_a?(ActiveSupport::TimeWithZone)

              assert_equal @inc_timestamp.to_s, job.increment_timestamp.to_s
            end

            should "pass :to => increment_timestamp to daily_deal_purchases_and_consumers_and_subscribers" do
              @nydn.expects(:daily_deal_purchases_and_consumers_and_subscribers).with do |options|
                (options.keys == [:to]) && (options[:to].to_s == @inc_timestamp.to_s)
              end
              Publisher.stubs(:find_by_label).returns(@nydn)
              Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename, :incremental => true
            end

          end

          context "when there are job records for this job, with increment_timestamp not null" do

            setup do
              @now = Time.zone.now
              @inc_timestamp = @now + 2.seconds
              Job.stubs(:increment_timestamp).returns(@inc_timestamp)
              two_days_ago = @now - 2.days
              one_day_ago = @now - 1.day
              Job.create! :key => "daily_deals:export_nydn_purchases_and_consumers:nydailynews",
                          :started_at => two_days_ago, :finished_at => two_days_ago + 10.minutes,
                          :increment_timestamp => two_days_ago + 1.second

              Job.create! :key => "daily_deals:export_nydn_purchases_and_consumers:nydailynews",
                          :started_at => one_day_ago, :finished_at => one_day_ago + 8.minutes,
                          :increment_timestamp => one_day_ago
            end

            should "create a Job record, populating its increment_timestamp with Job.increment_timestamp" do
              Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename, :incremental => true
              assert_equal 3, Job.count

              job = Job.with_key("daily_deals:export_nydn_purchases_and_consumers:nydailynews").latest_incremental_run.first
              assert_equal "daily_deals:export_nydn_purchases_and_consumers:nydailynews", job.key
              assert job.started_at.is_a?(ActiveSupport::TimeWithZone)
              assert job.finished_at.is_a?(ActiveSupport::TimeWithZone)
              assert job.increment_timestamp.is_a?(ActiveSupport::TimeWithZone)

              assert_equal @inc_timestamp.to_s, job.increment_timestamp.to_s
            end

            should "pass the latest increment_timestamp as the :from value, and Job.increment_timestamp as the :to value" do
              @nydn.expects(:daily_deal_purchases_and_consumers_and_subscribers).with do |options|
                (options.keys.map(&:to_s).sort == ["from", "to"]) &&
                (options[:to].to_s == @inc_timestamp.to_s)
                (options[:from].to_s == (@now - 1.day).to_s)
              end
              Publisher.stubs(:find_by_label).returns(@nydn)
              Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename, :incremental => true
            end

          end

        end

        teardown do
          File.unlink(@csv_filename) if File.exists?(@csv_filename)
        end

      end
      
      context "purchases and refunds" do
        
        setup do
          @start_time = Time.now
          @subscriber_1 = Factory :subscriber, :publisher => @nydn, :name => "Bob Jones",
                                  :email => "sub1@example.com", :created_at => @start_time - 30.days
          @consumer_1 = Factory :consumer, :publisher => @nydn, :name => "Sarah McDonald",
                                :email => "cons1@example.com", :created_at => @start_time - 29.days
          @consumer_2 = Factory :consumer, :publisher => @nydn, :name => "Tom Payton",
                                :email => "cons2@example.com", :created_at => @start_time - 27.days
          @purchase_1 = Factory :captured_daily_deal_purchase, :daily_deal => @daily_deal_1,
                                :consumer => @consumer_1, :quantity => 2,
                                :created_at => @start_time - 27.days + 1.second
          @refund_1 = Factory :refunded_daily_deal_purchase, :daily_deal => @daily_deal_2,
                              :consumer => @consumer_2, :quantity => 5, :created_at => @start_time - 27.days + 2.seconds,
                              :refunded_at => @start_time - 23.days
          
          # This line is needed to make the *_before_type_cast calls down below
          # return a datetime string with no timezone info in it.
          @refund_1.reload
          
          @csv_filename = File.join(Rails.root, "tmp", "nydn_export_test-#{SecureRandom.hex(4)}.csv")
        end
      
        context "a full export" do
        
          should "be exported as: one row for the purchase, one row for the refund" do
            Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename
            
            csv_lines = File.readlines(@csv_filename)
            assert_equal 5, csv_lines.length
            
            column_labels, first_line, second_line, third_line,
            fourth_line = csv_lines.map { |line| line.parse_csv }

            assert_equal "sub1@example.com", first_line[@email_idx]
            assert_equal "", first_line[@tx_type_idx]

            assert_equal "cons1@example.com", second_line[@email_idx]
            assert_equal "P", second_line[@tx_type_idx]
            assert_equal "2", second_line[@qty_idx]
            assert_equal "Great Deal #1", second_line[@value_prop_idx]
            
            assert_equal "cons2@example.com", third_line[@email_idx]
            assert_equal "P", third_line[@tx_type_idx]
            assert_equal "5", third_line[@qty_idx]
            assert_equal "Great Deal #2", third_line[@value_prop_idx]
            assert_equal @refund_1.created_at_before_type_cast, third_line[@dd_date_idx]
            
            assert_equal "cons2@example.com", fourth_line[@email_idx]
            assert_equal "R", fourth_line[@tx_type_idx]
            assert_equal "-5", fourth_line[@qty_idx]
            assert_equal "Great Deal #2", fourth_line[@value_prop_idx]
            assert_equal @refund_1.refunded_at_before_type_cast, fourth_line[@dd_date_idx]            
          end
        
        end
      
        context "an incremental export" do
          
          should "include the purchase in the earlier export that matches its created_at date" do
            Publisher.stubs(:get_export_options).returns({:from => @start_time - 28.days, :to => @start_time - 26.days})

            Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename, :incremental => true
            csv_lines = File.readlines(@csv_filename)
            assert_equal 3, csv_lines.length
            
            column_labels, first_line, second_line = csv_lines.map { |line| line.parse_csv }

            assert_equal "cons1@example.com", first_line[@email_idx]
            assert_equal "P", first_line[@tx_type_idx]
            assert_equal "2", first_line[@qty_idx]
            assert_equal "Great Deal #1", first_line[@value_prop_idx]
            
            assert_equal "cons2@example.com", second_line[@email_idx]
            assert_equal "P", second_line[@tx_type_idx]
            assert_equal "5", second_line[@qty_idx]
            assert_equal "Great Deal #2", second_line[@value_prop_idx]
          end
        
          should "include the refund in the later export that matches the refund date" do
            Publisher.stubs(:get_export_options).returns({:from => @start_time - 24.days, :to => @start_time - 22.days})

            Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename, :incremental => true
            csv_lines = File.readlines(@csv_filename)
            assert_equal 2, csv_lines.length
            
            column_labels, first_line = csv_lines.map { |line| line.parse_csv }

            assert_equal "cons2@example.com", first_line[@email_idx]
            assert_equal "R", first_line[@tx_type_idx]
            assert_equal "-5", first_line[@qty_idx]
            assert_equal "Great Deal #2", first_line[@value_prop_idx]            
          end
        
          should "set DD_DATE to the refunded_at value of the refund" do
            Publisher.stubs(:get_export_options).returns({:from => @start_time - 24.days, :to => @start_time - 22.days})

            Publisher.export_nydn_purchases_and_consumers! :file_name => @csv_filename, :incremental => true
            csv_lines = File.readlines(@csv_filename)
            assert_equal 2, csv_lines.length
            
            column_labels, first_line = csv_lines.map { |line| line.parse_csv }

            assert_equal "R", first_line[@tx_type_idx]
            assert_equal "-5", first_line[@qty_idx]
            assert_equal @refund_1.refunded_at_before_type_cast, first_line[@dd_date_idx]
          end
        
        end
        
      end

    end

    private

    def create_consumers
      start_time = Time.now
      
      @consumer_1 ||= Factory :consumer, :publisher_id => @nydn.id, :billing_city => "Vancouver", :state => "BC",
                              :first_name => "Test", :last_name => "Cons1", :address_line_1 => "100 Example Road",
                              :email => "cons1@example.com", :zip_code => "12345", :created_at => start_time - 10.minutes
      @consumer_2 ||= Factory :consumer, :publisher_id => @nydn.id, :billing_city => "Las Vegas", :state => "NV",
                              :first_name => "Test", :last_name => "Cons2", :address_line_1 => "1234 Las Vegas Boulevard",
                              :email => "cons2@example.com", :zip_code => "67890", :created_at => start_time - 9.minutes
      @consumer_3 ||= Factory :consumer, :publisher_id => @nydn.id, :email => "cons3@example.com",
                              :first_name => "Test", :last_name => "Cons3", :zip_code => "45567", :created_at => start_time - 8.minutes
      @consumer_4 ||= Factory :consumer, :publisher_id => @nydn.id, :email => "cons4@example.com",
                              :first_name => "Test", :last_name => "Cons4", :zip_code => "27171", :created_at => start_time - 7.minutes

      # A dirty hack to make consumer.*_before_type_cast on datetime columns return
      # a value similar to what an ActiveRecord object initialized in the "normal"
      # (i.e. non-factory_girl) way would.
      [@consumer_1, @consumer_2, @consumer_3, @consumer_4].each do |c|
        c.reload
      end
    end

    def create_captured_voided_and_authorized_purchases
      create_consumers
      
      start_time = Time.now

      @captured_purchase_1 ||= Factory :captured_daily_deal_purchase,
                                       :daily_deal_id => @daily_deal_1.id,
                                       :consumer_id => @consumer_1.id,
                                       :recipient_names => "Tom Sawyer",
                                       :created_at => start_time - 10.minutes
      @captured_purchase_2 ||= Factory :captured_daily_deal_purchase,
                                       :daily_deal_id => @daily_deal_2.id,
                                       :consumer_id => @consumer_2.id,
                                       :quantity => "2",
                                       :recipient_names => ["Hank Reardon", "Dagny Taggart"],
                                       :created_at => start_time - 9.minutes
      @non_nydn_captured_purchase ||= Factory :captured_daily_deal_purchase, :created_at => start_time - 8.minutes

      @voided_purchase_1 ||= Factory :voided_daily_deal_purchase,
                                     :daily_deal_id => @daily_deal_1.id,
                                     :consumer_id => @consumer_3.id,
                                     :created_at => start_time - 7.minutes

      @authorized_purchase_1 ||= Factory :authorized_daily_deal_purchase,
                                         :daily_deal_id => @daily_deal_3.id,
                                         :consumer_id => @consumer_4.id,
                                         :created_at => start_time - 6.minutes
    end

    def create_captured_purchases_from_yesterday
      create_consumers

      @captured_purchase_yesterday_1 ||= Factory :captured_daily_deal_purchase,
                                                 :daily_deal_id => @daily_deal_1.id,
                                                 :consumer_id => @consumer_1.id,
                                                 :created_at => (1.day + 15.minutes).ago
      @captured_purchase_yesterday_2 ||= Factory :captured_daily_deal_purchase,
                                                 :daily_deal_id => @daily_deal_2.id,
                                                 :consumer_id => @consumer_2.id,
                                                 :created_at => (1.day + 45.minutes).ago 
      @non_nydn_captured_purchase_yesterday ||= Factory :captured_daily_deal_purchase,
                                                        :created_at => (1.day + 22.minutes).ago
    end
    
    def create_refunded_purchases
      create_consumers
      
      start_time = Time.now

      @refunded_purchase_1 ||= Factory :refunded_daily_deal_purchase,
                                       :daily_deal_id => @daily_deal_1.id,
                                       :consumer_id => @consumer_1.id,
                                       :recipient_names => "Tom Sawyer",
                                       :created_at => start_time - 30.seconds
      @refunded_purchase_2 ||= Factory :refunded_daily_deal_purchase,
                                       :daily_deal_id => @daily_deal_2.id,
                                       :consumer_id => @consumer_2.id,
                                       :quantity => 3,
                                       :recipient_names => ["Hank Reardon", "Dagny Taggart", "John Galt"],
                                       :created_at => start_time - 25.seconds
      @non_nydn_refunded_purchase ||= Factory :refunded_daily_deal_purchase, :created_at => start_time - 20.seconds
    end
    

    def create_consumers_without_purchases
      start_time = Time.now
      
      @inactive_consumer_1 ||= Factory :consumer, :activated_at => nil, :publisher_id => @nydn.id,
                                       :created_at => start_time - 30.seconds
      @non_nydn_inactive_consumer_1 ||= Factory :consumer, :activated_at => nil, :publisher_id => @other_publisher.id,
                                        :created_at => start_time - 25.seconds

      @activated_consumer_1 ||= Factory :consumer, :first_name => "Active1", :last_name => "Consumer1", :email => "active_cons1@example.com", :publisher_id => @nydn.id,
                                        :created_at => start_time - 20.seconds
      @activated_consumer_2 ||= Factory :consumer, :first_name => "Active2", :last_name => "Consumer2", :email => "active_cons2@example.com", :publisher_id => @nydn.id,
                                        :created_at => start_time - 15.seconds
      @non_nydn_activated_consumer_1 ||= Factory :consumer, :publisher_id => @other_publisher.id,
                                                 :created_at => start_time - 10.seconds
    end

    def create_consumers_without_purchases_from_yesterday
      start_time = Time.now

      @inactive_consumer_yesterday_1 ||= Factory :consumer, :activated_at => nil, :publisher_id => @nydn.id, :created_at => (1.day + 20.minutes).ago,
                                                 :created_at => start_time - 10.minutes
      @non_nydn_inactive_consumer_yesterday_1 ||= Factory :consumer, :activated_at => nil, :publisher_id => @other_publisher.id, :created_at => (1.day + 20.minutes).ago,
                                                          :created_at => start_time - 9.minutes

      @activated_consumer_yesterday_1 ||= Factory :consumer, :first_name => "Active1", :last_name => "Consumer1", :publisher_id => @nydn.id, :created_at => (1.day + 20.minutes).ago,
                                                  :created_at => start_time - 8.minutes
      @non_nydn_activated_consumer_yesterday_1 ||= Factory :consumer, :publisher_id => @other_publisher.id, :created_at => (1.day + 20.minutes).ago,
                                                           :created_at => start_time - 7.minutes
    end

    def create_subscribers
      start_time = Time.now
      
      @subscriber_1 ||= Factory :subscriber, :publisher_id => @nydn.id, :first_name => "Sub", :last_name => "One",
                                :email => "subscriber1@example.com", :zip_code => "81711", :created_at => start_time - 10.minutes
      @subscriber_2 ||= Factory :subscriber, :publisher_id => @nydn.id, :first_name => "Sub", :last_name => "Two",
                                :email => "subscriber2@example.com", :zip_code => "81170", :created_at => start_time - 9.minutes
      @non_nydn_subscriber ||= Factory :subscriber, :publisher_id => @other_publisher.id, :created_at => start_time - 8.minutes
    end

    def create_subscribers_from_yesterday
      @subscriber_yesterday_1 ||= Factory :subscriber, :publisher_id => @nydn.id, :first_name => "Sub", :last_name => "One", :created_at => (1.day + 20.minutes).ago
      @subscriber_yesterday_2 ||= Factory :subscriber, :publisher_id => @nydn.id, :first_name => "Sub", :last_name => "Two", :created_at => (1.day + 20.minutes).ago
      @non_nydn_subscriber_yesterday ||= Factory :subscriber, :publisher_id => @other_publisher.id, :created_at => (1.day + 20.minutes).ago
    end

  end
end
