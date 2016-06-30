require File.dirname(__FILE__) + "/../../../../test_helper"
require File.dirname(__FILE__) + "/../../../../../lib/tasks/uploader"

# hydra class Export::SanctionScreening::PublishersTest
module Export
  module SanctionScreening
    class PublishersTest < ActiveSupport::TestCase

      context "export_to_pipe_delimited_file!" do
        setup do
          Dir[Rails.root.join("tmp", "sanction_screening_publishers_*")].each do |file|
            FileUtils.rm(file)
          end
          ::Publisher.delete_all

          Timecop.freeze(Time.zone.parse("2012/4/16 05:00:00 UTC")) do
            @publisher1 = Factory(:publisher, :name => "Publisher 1")
            @publisher2 = Factory(:publisher_with_uk_address, :name => "Publisher 2")
            @publisher3 = Factory(:publisher, :terminated_at => 1.day.from_now, :name => "Publisher 3")
            @publisher4 = Factory(:publisher, :launched_at => nil, :name => "Publisher 4")
          end
        end

        should "output to a file in the tmp directory" do
          Timecop.freeze(Time.zone.parse("2012/4/16 05:00:00 PDT")) do

            filename = Export::SanctionScreening::Publishers.export_to_pipe_delimited_file!
            assert_equal "sanction_screening_publishers_20120416050000.txt", File.basename(filename)
            assert File.exists?(filename)
          end
        end

        should "should include all publishers" do
          lines = nil
          Timecop.freeze(Time.zone.parse("2012/4/16 05:00:00 UTC")) do
            filename = Export::SanctionScreening::Publishers.export_to_pipe_delimited_file!
            lines = FasterCSV.read(filename, :col_sep => "|", :headers => true)
          end

          assert_equal @publisher1.id.to_s, lines[0]["analog_id"]
          assert_equal "Publisher 1", lines[0]["name"]
          assert_equal "1600 Pennsylvania Avenue NW", lines[0]["address_line_1"]
          assert_equal nil, lines[0]["address_line_2"]
          assert_equal "Washington", lines[0]["city"]
          assert_equal "DC", lines[0]["state"]
          assert_equal "20500", lines[0]["zip_code"]
          assert_equal "2012-04-15", lines[0]["start_date"]
          assert_equal "2012-04-15", lines[0]["launch_date"]
          assert_equal nil, lines[0]["termination_date"]
          assert_equal "12-12121212", lines[0]["tax_id"]

          assert_equal @publisher2.id.to_s, lines[1]["analog_id"]
          assert_equal "Publisher 2", lines[1]["name"]
          assert_equal "Thomson House", lines[1]["address_line_1"]
          assert_equal "296 Farnborough Road", lines[1]["address_line_2"]
          assert_equal "Farnborough", lines[1]["city"]
          assert_equal "Hants", lines[1]["state"]
          assert_equal "GU14 7NU", lines[1]["zip_code"]
          assert_equal "2012-04-15", lines[1]["start_date"]
          assert_equal "2012-04-15", lines[1]["launch_date"]
          assert_equal nil, lines[1]["termination_date"]
          assert_equal "12-12121212", lines[1]["tax_id"]

          assert_equal @publisher3.id.to_s, lines[2]["analog_id"]
          assert_equal "Publisher 3", lines[2]["name"]
          assert_equal "1600 Pennsylvania Avenue NW", lines[2]["address_line_1"]
          assert_equal nil, lines[2]["address_line_2"]
          assert_equal "Washington", lines[2]["city"]
          assert_equal "DC", lines[2]["state"]
          assert_equal "20500", lines[2]["zip_code"]
          assert_equal "2012-04-15", lines[2]["start_date"]
          assert_equal "2012-04-15", lines[2]["launch_date"]
          assert_equal "2012-04-16", lines[2]["termination_date"]
          assert_equal "12-12121212", lines[2]["tax_id"]

          assert_equal @publisher4.id.to_s, lines[3]["analog_id"]
          assert_equal "Publisher 4", lines[3]["name"]
          assert_equal "1600 Pennsylvania Avenue NW", lines[3]["address_line_1"]
          assert_equal nil, lines[3]["address_line_2"]
          assert_equal "Washington", lines[3]["city"]
          assert_equal "DC", lines[3]["state"]
          assert_equal "20500", lines[3]["zip_code"]
          assert_equal "2012-04-15", lines[3]["start_date"]
          assert_equal nil, lines[3]["launch_date"]
          assert_equal nil, lines[3]["termination_date"]
          assert_equal "12-12121212", lines[3]["tax_id"]
        end
      end

      context "create_row_from_publisher" do

        should "clean up smart-ish apostrophes" do
          publisher = Factory.build(:publisher)
          publisher.name = "Jake’s Deals"
          row = ::Export::SanctionScreening::Publishers.create_row_from_publisher(publisher)
          assert_equal "Jake's Deals", row[1]
        end

      end

      context "find_publishers" do

        should "exclude publishers used exclusively for testing" do
          pub1 = Factory(:publisher)
          pub2 = Factory(:publisher, :used_exclusively_for_testing => true)
          pub3 = Factory(:publisher)
          pub4 = Factory(:publisher, :used_exclusively_for_testing => true)
          results = ::Export::SanctionScreening::Publishers.find_publishers
          assert ([pub2, pub4] & results).empty?, "pubs excluded for testing should not be in our results"
        end

      end

      context "export_encrypt_and_upload!" do
        
        should "create a Job record with a sensible key, and started_at and finished_at populated" do
          assert !Job.exists?(:key => "sanction_screening:export_and_uploaded_encrypted_publisher_file")
          Export::SanctionScreening::Publishers.expects(:export_to_pipe_delimited_file!)
          Export::SanctionScreening::Upload.expects(:encrypt_upload_and_remove!)
          assert_difference "Job.count" do
            Export::SanctionScreening::Publishers.export_encrypt_and_upload!(
              not_used_in_this_test, not_used_in_this_test)
          end     
          job = Job.last
          assert_equal "sanction_screening:export_and_uploaded_encrypted_publisher_file", job.key
          assert job.started_at.present?
          assert job.finished_at.present?
        end

      end

    end
  end
end
