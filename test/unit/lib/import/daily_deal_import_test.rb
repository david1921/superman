require File.dirname(__FILE__) + "/../../../test_helper"
require File.expand_path("lib/tasks/import/daily_deal_import", RAILS_ROOT)

# hydra class Import::DailyDealImportHelperTest

module Import
  class DailyDealImportHelperTest < ActiveSupport::TestCase
    include DailyDealImport

    context "#select_unprocessed_files" do

      context "no processed files" do
        setup do
          @publisher = Factory(:publisher)
        end

        should "select unprocessed jobs" do
          unprocessed = ["unprocessed_file.xml"]
          assert_equal unprocessed, FTP::select_unprocessed_files(@publisher, unprocessed)
        end

        should "select unprocessed jobs when passing in an alternate file extension" do
          unprocessed = ["unprocessed_file.csv"]
          assert_equal unprocessed, FTP::select_unprocessed_files(@publisher, unprocessed)
        end
      end

      context "processed files" do
        setup do
          @publisher = Factory(:publisher)
          @job1 = Factory(:finished_job, :publisher => @publisher, :file_name => "file1.xml")
          @job2 = Factory(:finished_job, :publisher => @publisher, :file_name => "file2.xml")
        end

        should "select only unprocessed jobs" do
          unprocessed = ["unprocessed_file.xml"]
          assert_equal unprocessed, FTP::select_unprocessed_files(@publisher, unprocessed)
        end

        should "not select processed jobs" do
          assert_equal [], FTP::select_unprocessed_files(@publisher, ["file1.xml"])
        end

        context "#select_files_ready_to_process" do
          should "filter out remote files with no sig files" do
            remote_files = %w( file1.xml file1.sig
                               file2.xml file2.sig
                               file3.xml file3.sig
                               file4.xml file4.sig
                               file5.xml )
            expected = %w( file3.xml file4.xml )
            assert_equal expected, FTP::select_files_ready_to_process(@publisher, remote_files)
          end

          should "filter out remote files with no sig files when using an alternate file extension" do
            remote_files = %w( file1.csv file1.sig
                               file2.csv file2.sig
                               file3.csv file3.sig
                               file4.csv file4.sig
                               xmlfile.xml xmlfile.sig
                               file5.csv )
            expected = %w( file1.csv file2.csv file3.csv file4.csv )
            assert_equal expected, FTP::select_files_ready_to_process(@publisher, remote_files, "csv")
          end
        end
      end
    end
  end
end
