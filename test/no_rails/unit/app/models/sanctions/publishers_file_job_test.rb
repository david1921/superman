require File.dirname(__FILE__) + "/../../models_helper"

# hydra class Sanctions::PublishersFileJobTest

module Sanctions
  class PublishersFileJobTest < Test::Unit::TestCase
    context "self.perform" do
      setup do
        PublishersFileJob.stubs(:sanctions_gpg_recipient).returns("ABC123DEF")
      end

      should "call Export::SanctionScreening::Publishers.export_encrypt_and_upload! with the passphrase and GPG recipient" do
        Export::SanctionScreening::Publishers.expects(:export_encrypt_and_upload!).with("passphrase", "ABC123DEF")
        PublishersFileJob.perform("passphrase")
      end

    end
  end
end