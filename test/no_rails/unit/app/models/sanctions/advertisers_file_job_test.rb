require File.dirname(__FILE__) + "/../../models_helper"

# hydra class Sanctions::AdvertisersFileJobTest

module Sanctions
  class AdvertisersFileJobTest < Test::Unit::TestCase
    context "self.perform" do
      setup do
        AdvertisersFileJob.stubs(:sanctions_gpg_recipient).returns("ABC123DEF")
        @screening_start_date = Time.now
        AdvertisersFileJob.stubs(:sanctions_screening_start_date).returns(@screening_start_date)
      end

      should "call Export::SanctionScreening::Advertisers.export_encrypt_and_upload! with the passphrase and GPG recipient" do
        Export::SanctionScreening::Advertisers.expects(:export_encrypt_and_upload!).with("passphrase", "ABC123DEF", @screening_start_date)
        AdvertisersFileJob.perform("passphrase")
      end

    end
  end
end