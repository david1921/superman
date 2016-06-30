module Sanctions
  class PublishersFileJob < BaseFileJob

    def self.perform(passphrase)
      Export::SanctionScreening::Publishers.export_encrypt_and_upload!(passphrase, sanctions_gpg_recipient)
    end
  end
end
