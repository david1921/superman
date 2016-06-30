require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Export::TwcTest

module Export
  
  class TwcTest < ActiveSupport::TestCase
    
    def setup
      Timecop.freeze(Time.parse("2011-09-13T11:33:56Z")) do
        @publishing_group = Factory :publishing_group, :label => "rr"
        @publisher_1 = Factory :publisher, :label => "clickedin-austin", :publishing_group => @publishing_group
        @publisher_2 = Factory :publisher, :label => "clickedin-sanantonio"
        @advertiser = Factory :advertiser, :publisher => @publisher_1
        @daily_deal = Factory :daily_deal, :advertiser => @advertiser, :value_proposition => "amazing food"
        @consumer_1 = Factory :consumer, :first_name => "Neil", :last_name => "Perry", :email => "np@example.com", :publisher => @publisher_1, :created_at => 10.minutes.ago
        @consumer_2 = Factory :consumer, :first_name => "Jamie", :last_name => "Oliver", :email => "jo@example.com", :publisher => @publisher_1, :created_at => 9.minutes.ago, :device => "mobile"
        
        @daily_deal_purchase = Factory :captured_daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer_1, :gift => true, :executed_at => Time.now - 100.seconds, :recipient_names => "Guy Grossi"
        @refund = Factory :refunded_daily_deal_purchase, :daily_deal => @daily_deal, :executed_at => Time.now - 50.seconds, :consumer => @consumer_2
        @pending_purchase = Factory :pending_daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer_2
        
        @daily_deal_purchase.daily_deal_payment.update_attribute :payer_postal_code, "42424"
        @refund.daily_deal_payment.update_attribute :payer_postal_code, "11223"
        
        @sub_1 = Factory :subscriber, :publisher => @publisher_1, :created_at => 8.minutes.ago, :email => "nlawson@example.com"
      end
    end

    fast_context "Export::Twc::PurchasesAndRefunds.export_to_csv!" do

      fast_context "job logging" do
        
        should "log the job with the appropriate job key" do
          
          Job.delete_all
          
          assert_difference "Job.count", 1 do
            Export::Twc::PurchasesAndRefunds.export_to_csv!
          end
          
          assert_equal "twc:generate_purchases_and_refunds_csv", Job.first.key
          
        end
        
      end
      
      fast_context "the data written to the CSV file" do
        
        setup do
          filename = Export::Twc::PurchasesAndRefunds.export_to_csv!
          @csv_rows = FasterCSV.read(filename)
        end
        
        should "include the correct headers" do
          header_row = @csv_rows.first
          column_labels = [
            "first_name", "last_name", "e_mail", "zip_code", "value_proposition", "price", "advertiser_name", "date_and_time_of_purchase",
            "number_of_deals_purchased", "for_friend", "for_self"
          ]
          assert_equal column_labels.length, header_row.length
          column_labels.each do |column_name|
            assert_equal column_name, header_row[purchase_column_number_for(column_name)]
          end
        end
        
        should "include the correct data" do
          assert_equal 3, @csv_rows.length

          data_row = @csv_rows.second
          assert_equal "Neil", data_row[purchase_column_number_for("first_name")]
          assert_equal "Perry", data_row[purchase_column_number_for("last_name")]
          assert_equal "np@example.com", data_row[purchase_column_number_for("e_mail")]
          assert_equal "42424", data_row[purchase_column_number_for("zip_code")]
          assert_equal "amazing food", data_row[purchase_column_number_for("value_proposition")]
          assert_equal "2011-09-13T11:32:16Z", data_row[purchase_column_number_for("date_and_time_of_purchase")]
          assert_equal "1", data_row[purchase_column_number_for("number_of_deals_purchased")]
          assert_equal "1", data_row[purchase_column_number_for("for_friend")]
          assert_equal "0", data_row[purchase_column_number_for("for_self")]
          
          data_row = @csv_rows.third
          assert_equal "Jamie", data_row[purchase_column_number_for("first_name")]
          assert_equal "Oliver", data_row[purchase_column_number_for("last_name")]
          assert_equal "jo@example.com", data_row[purchase_column_number_for("e_mail")]
          assert_equal "11223", data_row[purchase_column_number_for("zip_code")]
          assert_equal "amazing food", data_row[purchase_column_number_for("value_proposition")]
          assert_equal "2011-09-13T11:33:06Z", data_row[purchase_column_number_for("date_and_time_of_purchase")]
          assert_equal "1", data_row[purchase_column_number_for("number_of_deals_purchased")]
          assert_equal "0", data_row[purchase_column_number_for("for_friend")]
          assert_equal "1", data_row[purchase_column_number_for("for_self")]
        end
        
      end
      
    end
    
    fast_context "Export::Twc::Signups.export_to_csv!" do
      
      fast_context "job logging" do
        
        should "log the job with the appropriate key" do
          Job.delete_all
          assert_difference "Job.count", 1 do
            Export::Twc::Signups.export_to_csv!
          end
          assert_equal "twc:generate_signups_csv", Job.first.key
        end
        
      end
      
      fast_context "the data written to the CSV file" do
        
        setup do
          csv_filename = Export::Twc::Signups.export_to_csv!
          @csv_rows = FasterCSV.read(csv_filename)
        end
        
        should "contain the correct number of rows" do
          assert_equal 4, @csv_rows.length
        end
        
        should "contain the correct headers" do
          header_row = @csv_rows.first
          column_labels = %w(first_name last_name e_mail zip_code created_at device)
          assert_equal column_labels.length, header_row.length
          column_labels.each do |col_label|
            assert_equal col_label, header_row[signups_column_number_for(col_label)]
          end
        end
        
        should "contain the correct data" do
          first_row, second_row, third_row = @csv_rows[1..-1]
          assert_equal "Neil", first_row[signups_column_number_for("first_name")]
          assert_equal "Perry", first_row[signups_column_number_for("last_name")]
          assert_equal "np@example.com", first_row[signups_column_number_for("e_mail")]
          assert_equal "42424", first_row[signups_column_number_for("zip_code")]
          assert_equal "2011-09-13T11:23:56Z", first_row[signups_column_number_for("created_at")]
          assert_equal nil, first_row[signups_column_number_for("device")]
          
          assert_equal "Jamie", second_row[signups_column_number_for("first_name")]
          assert_equal "Oliver", second_row[signups_column_number_for("last_name")]
          assert_equal "jo@example.com", second_row[signups_column_number_for("e_mail")]
          assert_equal "11223", second_row[signups_column_number_for("zip_code")]
          assert_equal "2011-09-13T11:24:56Z", second_row[signups_column_number_for("created_at")]
          assert_equal "mobile", second_row[signups_column_number_for("device")]

          assert_equal nil, third_row[signups_column_number_for("first_name")]
          assert_equal nil, third_row[signups_column_number_for("last_name")]
          assert_equal "nlawson@example.com", third_row[signups_column_number_for("e_mail")]
          assert_equal "97214", third_row[signups_column_number_for("zip_code")]
          assert_equal "2011-09-13T11:25:56Z", third_row[signups_column_number_for("created_at")]
          assert_equal nil, third_row[signups_column_number_for("device")]
        end
        
      end
      
      fast_context "when run incrementally" do
        
        setup do
          ENV["INCREMENTAL"] = "1"
          Factory :job, :key => "twc:generate_signups_csv",
                  :started_at => Time.parse("2011-09-13T11:33:56Z"),
                  :finished_at => Time.parse("2011-09-13T11:38:56Z"),
                  :increment_timestamp => Time.parse("2011-09-13T11:33:56Z"),
                  :file_name => "/some/file/name"
        end
        
        teardown do
          ENV["INCREMENTAL"] = nil
        end
        
        should "export only the signups added since the last run" do
          
          Timecop.freeze(Time.parse("2011-09-14T11:33:56Z")) do
            @new_subscriber = Factory :subscriber, :publisher => @publisher_1, :email => "newb@example.com", :created_at => 10.minutes.ago
            @new_consumer = Factory :consumer, :publisher => @publisher_1, :email => "newcons@example.com", :created_at => 5.minutes.ago
            csv_filename = Export::Twc::Signups.export_to_csv!
            @csv_rows = FasterCSV.read(csv_filename)
          end
          
          assert_equal 3, @csv_rows.length
          assert_equal "newb@example.com", @csv_rows.second[signups_column_number_for("e_mail")]
          assert_equal "newcons@example.com", @csv_rows.third[signups_column_number_for("e_mail")]
        end
        
      end
      
    end
    
    fast_context "Export::Twc::PurchasesAndRefunds.upload_csv!" do
      
      should "call export_to_csv! and Uploader methods with relevant config" do
        Export::Twc::PurchasesAndRefunds.expects(:export_to_csv!).once.returns("/some/test/file.csv")
        Export::Twc::PurchasesAndRefunds.stubs(:ensure_file_exists!).returns(nil)
        Export::Twc::PurchasesAndRefunds.stubs(:gzip_file).returns("/some/test/file.csv.gz")
        
        fake_uploader = Object.new
        fake_uploader.expects(:upload).with("clickedin", "/some/test/file.csv.gz")
        Uploader.expects(:new).returns(fake_uploader)
        
        Export::Twc::PurchasesAndRefunds.upload_csv!
      end
      
    end
    
    context "Export::Twc::Signups.upload_csv!" do
      
      should "call export_to_csv! and Uploader methods with relevant config" do
        Export::Twc::Signups.expects(:export_to_csv!).once.returns("/some/test/file.csv")
        Export::Twc::Signups.stubs(:ensure_file_exists!).returns(nil)
        Export::Twc::Signups.stubs(:gzip_file).returns("/some/test/file.csv.gz")
        
        fake_uploader = Object.new
        fake_uploader.expects(:upload).with("clickedin", "/some/test/file.csv.gz")
        Uploader.expects(:new).returns(fake_uploader)
        
        Export::Twc::Signups.upload_csv!
      end
      
    end
    
    def purchase_column_number_for(column_name)
      Export::Twc::PurchasesAndRefunds.get_column_label_index(column_name)
    end
    
    def signups_column_number_for(column_name)
      Export::Twc::Signups.get_column_label_index(column_name)
    end
    
  end
  
end