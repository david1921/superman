require File.dirname(__FILE__) + "/../../../test_helper"
require File.dirname(__FILE__) + "/../../../../lib/tasks/uploader"

# hydra class Export::NewsweekTest

module Export
  class NewsweekTest < ActiveSupport::TestCase

    setup do
      FileUtils.rm_f(Rails.root.join("tmp", "AAN*-NWK-*.TXT").to_s)
    end

    context "PurchaseExport.export_to_1500_record_layout!" do
      setup do
        @publisher = Factory(:publisher, :label => "newsweek")
      end

      should "raise exception when newsweek publisher is not found" do
        ::Publisher.find_by_label("newsweek").destroy
        assert_raise RuntimeError do
          Export::Newsweek::PurchaseExport.export_to_1500_record_layout!
        end
      end

      should "create a job with proper attributes" do
        assert !Job.exists?(:key => "newsweek:export_purchases")
        assert_difference "Job.count", 1 do
          Timecop.freeze(Time.zone.parse("March 26, 2012 22:00 PDT")) do
            Export::Newsweek::PurchaseExport.export_to_1500_record_layout!
          end
        end
        job = Job.find_by_key("newsweek:export_purchases")
        assert_equal @publisher.id, job.publisher_id
        assert job.started_at.present?
        assert job.finished_at.present?
        assert job.increment_timestamp.present?
        assert_equal nil, job.file_name
      end

      context "output file" do
        setup do
          Timecop.freeze(Time.zone.parse("March 25, 2012 22:00 PDT")) do
            consumer = Factory(:billing_address_consumer, :publisher => @publisher)
            daily_deal = Factory(:daily_deal, :publisher => @publisher)
            daily_deal_purchase1 = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer)
            daily_deal_purchase2 = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer)
          end

          Timecop.freeze(Time.zone.parse("March 26, 2012 22:00 PDT")) do
            @file_paths = Export::Newsweek::PurchaseExport.export_to_1500_record_layout!
          end

          @file_name = Rails.root.join("tmp", "AAN032712-NWK-1332824400-0.TXT")
          @file_contents = File.readlines(@file_name)
        end

        should "return output file names" do
          assert_equal [Rails.root.join("tmp", "AAN032712-NWK-1332824400-0.TXT").to_s], @file_paths
        end

        should "exist" do
          assert File.exists?(@file_name)
        end

        should "create export file with header matching the current date" do
          assert @file_contents.first.starts_with?("PCD032712000001AAN")
        end

        should "have a row for each captured purchase in the job date range" do
          assert_equal 2, @file_contents.length
        end

        should "output rows in 1500 record layout" do
          assert @file_contents.second.starts_with?("19501032612        P")
        end

      end

      context "given more than :max_purchases_per_file purchases" do
        setup do
          daily_deal = Factory(:daily_deal, :publisher => @publisher)
          7.times do |i|
            Timecop.freeze(Time.zone.parse("March 25, 2012 22:0#{i} PDT")) do
              consumer = Factory(:billing_address_consumer, :publisher => @publisher, :email => "consumer#{i}@example.com")
              Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer)
            end
          end

          Timecop.freeze(Time.zone.parse("March 26, 2012 22:00 PDT")) do
            Export::Newsweek::PurchaseExport.export_to_1500_record_layout!(:max_purchases_per_file => 5)
          end

          file_name = Rails.root.join("tmp", "AAN032712-NWK-1332824400-0.TXT")
          @file1_contents = File.readlines(file_name)
          file_name = Rails.root.join("tmp", "AAN032712-NWK-1332824400-1.TXT")
          @file2_contents = File.readlines(file_name)
        end

        should "split output into multiple files" do
          assert_equal 6, @file1_contents.length
          assert_equal 3, @file2_contents.length

          assert_equal "consumer0@example.com", @file1_contents[1][603..652].strip
          assert_equal "consumer5@example.com", @file2_contents[1][603..652].strip
        end
      end

      context "given 0 purchases within range" do
        setup do
          DailyDealPurchase.destroy_all
          Timecop.freeze(Time.zone.parse("March 26, 2012 22:00 PDT")) do
            @file_paths = Export::Newsweek::PurchaseExport.export_to_1500_record_layout!(:max_purchases_per_file => 5)
          end

          file_name = Rails.root.join("tmp", "AAN032712-NWK-1332824400-0.TXT")
          @file_contents = File.readlines(file_name)
        end

        should "export one file" do
          assert_equal 1, @file_paths.length
        end

        should "export header with 0 record rows" do
          assert_equal 1, @file_contents.length
          assert @file_contents.first.starts_with?("PCD032712000000AAN")
        end

      end

    end


    context "upload_1500_record_layout_file!" do
      setup do
        @publisher = Factory(:publisher, :label => "newsweek")
      end

      should "call export_to_1500_record_layout! and upload the exported file" do
        Timecop.freeze(Time.zone.parse("March 26, 2012 22:00 PDT")) do
          expected_file_name = Rails.root.join("tmp", "AAN032712-NWK-1332824400-0.TXT").to_s
          Export::Newsweek::PurchaseExport.expects(:export_to_1500_record_layout!).returns([expected_file_name])
          Export::Newsweek::PurchaseExport.expects(:ensure_file_exists!).with(expected_file_name).returns(true)

          fake_uploader = Object.new
          fake_uploader.expects(:upload).with("newsweek", expected_file_name)
          Uploader.
            expects(:new).
            with({ "newsweek" => { :protocol => "sftp", :host => "sftp.palmcoastd.com", :user => "AnalogAnalyticsD", :pass => "8b5dtsUL" } }).
            returns(fake_uploader)

          Export::Newsweek::PurchaseExport.upload_1500_record_layout_file!
        end
      end

    end

  end
end
