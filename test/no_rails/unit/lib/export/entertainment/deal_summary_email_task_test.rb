require File.dirname(__FILE__) + "/../../../../test_helper"
require 'export/entertainment/deal_summary_email_task'

# hydra class Export::Entertainment::DealSummaryEmailTaskTest
module Export
  module Entertainment
    class PublisherDailyDealPurchaseTotal; end
    class DealSummaryEmailTaskTest < Test::Unit::TestCase
      context "DateParser" do
        should "throw exception if date is letters" do
          e = assert_raise ArgumentError do
            DateParser.parse_date!("wrong_format")
          end

          assert_equal "invalid date format for `wrong_format`", e.message
        end

        should "throw exception if date is >8 numbers" do
          date = "201212211"
          e = assert_raise ArgumentError do
            DateParser.parse_date!(date)
          end

          assert_equal "invalid date format for `201212211`", e.message
        end

        should "convert dates in format YYYYmmdd to dates" do
          date = "20121221"
          expected_date = Date.new(2012, 12, 21)

          result = DateParser.parse_date!(date)

          assert_equal expected_date, result
        end
      end

      context "#store_deal_purchase_counts" do
        context "success path" do
          setup do
            @input_file = File.join(root_path, "tmp", "deal_summary_input_file.txt")
            @date = "20121221"
            File.stubs(:exist?).returns(true)
          end

          should "summarize input file in FILE environment value" do
            DealEmailFileSummarizer.stubs(:summarize).with(@input_file).returns({}).once
            PublisherDailyDealPurchaseTotal.stubs(:set_totals)

            DealSummaryEmailTask.store_deal_purchase_counts(@input_file, @date)
          end

          should "not save market counts if DRY_RUN is present" do
            DealEmailFileSummarizer.stubs(:summarize).returns({})
            PublisherDailyDealPurchaseTotal.stubs(:set_totals).never

            DealSummaryEmailTask.store_deal_purchase_counts(@input_file, @date, dry_run=true)
          end

          should "save market counts" do
            mock_summary_results = mock
            DealEmailFileSummarizer.stubs(:summarize).returns(mock_summary_results)
            PublisherDailyDealPurchaseTotal.stubs(:set_totals).with(Date.new(2012, 12, 21), mock_summary_results).once

            DealSummaryEmailTask.store_deal_purchase_counts(@input_file, @date)
          end
        end

        context "required parameter FILE" do

          should "throw exception if FILE doesn't exist" do
            file = "doesn't_exist.txt"
            date = "20121221"
            File.stubs(:exist?).returns(false)

            e = assert_raise ArgumentError do
              DealSummaryEmailTask.store_deal_purchase_counts(file, date)
            end

            assert_equal "File #{file} does not exist", e.message
          end
        end

        context "required parameter DATE" do
          setup do
            @file = "does_not_matter.txt"
            File.stubs(:exist?).returns(true)
          end

          should "throw exception if DATE is wrong format" do
            e = assert_raise ArgumentError do
              DealSummaryEmailTask.store_deal_purchase_counts(@file, "wrong_format")
            end

            assert_equal "Must specify DATE to store results for", e.message
          end
        end
      end

      context "#generate_deal_purchase_variance_file" do
        setup do
          @time_zone  = "pst"
          @start_date = "20121220"
          @end_date   = "20121221"
          @output_file = "some_file.txt"
        end

        should "throw execption if output file exists" do

          time_stamp  = Time.zone.now.strftime("%Y%m%d")
          rails_tmp_path = File.expand_path("tmp", Rails.root)
          output_file = File.expand_path("ENTERTAINPUB_DYNDS_DAILYDEAL_#{@time_zone}_SUMMARY_#{time_stamp}.txt", rails_tmp_path)

          File.stubs(:exists?).returns(true)

          e = assert_raise ArgumentError do
            DealSummaryEmailTask.generate_deal_purchase_variance_file(@start_date, @end_date, @time_zone)
          end

          assert_equal "Output file #{output_file} already exists", e.message
        end

        should "throw if START_DATE is wrong format" do
            date = "asd"
            e = assert_raise ArgumentError do
              DealSummaryEmailTask.generate_deal_purchase_variance_file(date, @end_date, @time_zone)
            end

            assert_equal "Must specify a START_DATE", e.message
          end

        should "throw if END_DATE is wrong format" do
            date = "asd"
            e = assert_raise ArgumentError do
              DealSummaryEmailTask.generate_deal_purchase_variance_file(@start_date, date, @time_zone)
            end

            assert_equal "Must specify an END_DATE", e.message
          end

        should "summarizes from START_DATE to END_DATE" do
          time_zone = 'pst'
          start_date = Date.new(2012, 12, 20)
          end_date = Date.new(2012, 12, 21)
          DealSummary.stubs(:summarize).with(start_date, end_date, anything).returns([]).once
          DelimitedFile.stubs(:open)

          DealSummaryEmailTask.generate_deal_purchase_variance_file(@start_date, @end_date, time_zone)
        end

        should "summarizes with 5 percent variance" do
          time_zone = "pst"
          DealSummary.stubs(:summarize).with(anything, anything, 5).returns([]).once
          DelimitedFile.stubs(:open)

          DealSummaryEmailTask.generate_deal_purchase_variance_file(@start_date, @end_date, time_zone)
        end

      end

      context "#upload_deal_purchase_variance_file" do
        should "throw execption if FILE does not exist" do
          input_file = File.join(root_path, "does_not_exist.txt")
          File.stubs(:exists?).with(input_file).returns(false)

          e = assert_raise ArgumentError do
            DealSummaryEmailTask.upload_deal_purchase_variance_file(input_file)
          end

          assert_equal "File #{input_file} does not exist", e.message
        end

        should "load publishing groups upload config" do
          input_file = File.join(root_path, "does_not_exist.txt")
          File.stubs(:exists?).with(input_file).returns(true)
          UploadConfig.stubs(:new).with(:publishing_groups).once
          Uploader.stubs(:new)

          DealSummaryEmailTask.upload_deal_purchase_variance_file(input_file, dry_run = 'true')
        end

        should "upload file using entertainment profile" do
          input_file = File.join(root_path, "does_not_exist.txt")
          File.stubs(:exists?).with(input_file).returns(true)
          UploadConfig.stubs(:new)
          uploader = mock
          Uploader.stubs(:new).returns(uploader)
          uploader.stubs(:upload).with("entertainment", input_file).once

          DealSummaryEmailTask.upload_deal_purchase_variance_file(input_file)
        end

        should "skip uploading of file if is a DRY_RUN" do
          input_file = File.join(root_path, "does_not_exist.txt")
          File.stubs(:exists?).with(input_file).returns(true)
          UploadConfig.stubs(:new).with(:publishing_groups)
          uploader = mock
          Uploader.stubs(:new).returns(uploader)
          uploader.stubs(:upload).never

          DealSummaryEmailTask.upload_deal_purchase_variance_file(input_file, dry_run='true')
        end
      end

      def root_path
        File.expand_path(File.join(File.dirname(__FILE__) + "/../../../../../.."))
      end
    end
  end
end
