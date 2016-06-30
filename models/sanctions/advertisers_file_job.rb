module Sanctions
  class AdvertisersFileJob < BaseFileJob

    def self.perform(passphrase)
      Export::SanctionScreening::Advertisers.export_encrypt_and_upload!(passphrase, sanctions_gpg_recipient, sanctions_screening_start_date)
    end

  end
end
