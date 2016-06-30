require File.dirname(__FILE__) + "/../../../../test_helper"
require File.dirname(__FILE__) + "/../../../../../lib/tasks/uploader"

class Export::SanctionScreening::AdvertisersTest < ActiveSupport::TestCase
  context "export_to_pipe_delimited_file!" do
    setup do
      @screening_start_date = Time.zone.parse("Tue Apr 17 02:57:03 UTC 2012")
      remove_existing_files_in_tmp_folder
      delete_all_stores
      @paychex_stores_before_sanctions = setup_paychex_stores(@screening_start_date - 1.second)
      @non_paychex_stores_after_sanctions = setup_non_paychex_stores(@screening_start_date + 1.second)
      @paychex_stores_after_sanctions = setup_paychex_stores(@screening_start_date + 1.second)
      Timecop.freeze(Time.zone.parse("2012/4/18 05:00:00 PDT")) do
        @filename = Export::SanctionScreening::Advertisers.export_to_pipe_delimited_file!(@screening_start_date)
      end
    end

    should "output to a file" do
      assert_equal "sanction_screening_advertisers_20120418050000.txt", File.basename(@filename)
      assert File.exists?(@filename)
    end

    should "have the correct headers on the first line" do
      first_line = File.readlines(@filename).first.chomp
      expected_headers = ["merchant_name", "analog_id", "address_line_1", "address_line_2", "city", "state", "zip_code", "start_date", "launch_date", "termination_date", "tax_id"]
      assert_equal expected_headers.join('|'), first_line
    end

    should "should include only stores for Paychex advertisers" do
      lines = File.read(@filename).split("\n")

      @paychex_stores_after_sanctions.each do |store|
        assert_contains lines, store_to_line(store), "Paychex store #{store.id} after sanctions was missing from output"
      end

      @paychex_stores_before_sanctions.each do |store|
        assert_contains lines, store_to_line(store), "Paychex store #{store.id} before sanctions was missing from output"
      end

      @non_paychex_stores_after_sanctions.each do |store|
        assert_does_not_contain lines, store_to_line(store), "Non-Paychex store #{store.id} was not expected in output"
      end

    end
  end

  private

  def remove_existing_files_in_tmp_folder
    Dir[Rails.root.join("tmp", "sanction_screening_advertisers_*")].each do |file|
      FileUtils.rm(file)
    end
  end

  def delete_all_stores
    Store.delete_all
  end

  def setup_paychex_stores(creation_time)
    setup_stores(creation_time)
  end

  def setup_non_paychex_stores(creation_time)
    setup_stores(creation_time, false)
  end

  def setup_stores(creation_time, paychex=true)
    stores = []
    Timecop.freeze(creation_time) do
      pub_attrs = {:started_at => 1.week.from_now, :launched_at => 2.weeks.from_now, :terminated_at => 1.year.from_now}
      publisher = Factory(paychex ? :publisher_using_paychex : :publisher, pub_attrs)
      2.times do |i|
        advertiser = Factory(:advertiser, :publisher => publisher, :federal_tax_id => "12345-#{i}")
        2.times do
          stores << Factory(:store, :advertiser => advertiser)
        end
      end
    end
    stores
  end

  context "create_row_from_store" do

    should "clean store names on the way through" do
      store = Factory.build(:store)
      store.advertiser.name = "San Antonio Children’s Museum"
      row = Export::SanctionScreening::Advertisers.create_row_from_store(store)
      assert_equal "San Antonio Children's Museum", row[0]
    end

  end

  context "find_stores" do

      should "exclude advertisers used exclusively for testing" do
        # We only write checks to stores that use paychex
        publishing_group = Factory(:publishing_group_using_paychex)
        included_publisher = Factory(:publisher, :publishing_group => publishing_group)
        excluded_publisher = Factory(:publisher, :publishing_group => publishing_group, :used_exclusively_for_testing => true)

        excluded_advertiser_because_of_publisher = Factory(:advertiser, :publisher => excluded_publisher)
        excluded_advertiser = Factory(:advertiser, :publisher => included_publisher, :used_exclusively_for_testing => true)
        normal_included_advertiser = Factory(:advertiser, :publisher => included_publisher)

        store_excluded1 = Factory(:store, :advertiser => excluded_advertiser_because_of_publisher)
        store_excluded2 = Factory(:store, :advertiser => excluded_advertiser)
        store_included = Factory(:store, :advertiser => normal_included_advertiser)

        results = ::Export::SanctionScreening::Advertisers.find_stores
        assert ([store_excluded1, store_excluded2] & results).empty?, "stores should have been excluded"
        assert results.include?(store_included)
      end

  end

  context "export_encrypt_and_upload!" do
    
    should "create a Job record with a sensible key, and started_at and finished_at populated" do
      assert !Job.exists?(:key => "sanction_screening:export_and_uploaded_encrypted_advertiser_file")
      Export::SanctionScreening::Advertisers.expects(:export_to_pipe_delimited_file!)
      Export::SanctionScreening::Upload.expects(:encrypt_upload_and_remove!)
      assert_difference "Job.count" do
        Export::SanctionScreening::Advertisers.export_encrypt_and_upload!(
          not_used_in_this_test, not_used_in_this_test, not_used_in_this_test)
      end     
      job = Job.last
      assert_equal "sanction_screening:export_and_uploaded_encrypted_advertiser_file", job.key
      assert job.started_at.present?
      assert job.finished_at.present?
    end

  end

  private

  def store_to_line(store)
    [
        store.advertiser.name,
        store.id,
        store.address_line_1,
        store.address_line_2,
        store.city,
        store.state || store.region,
        store.zip,
        store.started_at.try(:to_formatted_s, :db_date),
        store.launched_at.try(:to_formatted_s, :db_date),
        store.terminated_at.try(:to_formatted_s, :db_date),
        store.federal_tax_id
    ].join('|')
  end
end
