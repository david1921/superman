module Sanctions
  class ConsumersFileJob < BaseFileJob

    def self.perform(passphrase)
      Export::SanctionScreening::Consumers.export_encrypt_and_upload!(passphrase, sanctions_gpg_recipient, sanctions_screening_start_date)
    end

  end
end
