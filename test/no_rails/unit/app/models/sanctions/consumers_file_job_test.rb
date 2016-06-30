require File.dirname(__FILE__) + "/../../models_helper"

# hydra class Sanctions::ConsumersFileJobTest

module Sanctions
  class ConsumersFileJobTest < Test::Unit::TestCase
    context "self.perform" do
      setup do
        ConsumersFileJob.stubs(:sanctions_gpg_recipient).returns("ABC123DEF")
        @screening_start_date = Time.now
        ConsumersFileJob.stubs(:sanctions_screening_start_date).returns(@screening_start_date)
      end

      should "call Export::SanctionScreening::Consumers.export_encrypt_and_upload! with the passphrase and GPG recipient" do
        Export::SanctionScreening::Consumers.expects(:export_encrypt_and_upload!).with("passphrase", "ABC123DEF", @screening_start_date)
        ConsumersFileJob.perform("passphrase")
      end

    end
  end
end