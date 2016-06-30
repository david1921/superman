module Sanctions
  class BaseFileJob

    @queue = :sanctions_file_uploads

    def self.perform(passphrase)
      raise "This method must be implemented in a subclass"
    end

    private

    def self.sanctions_gpg_recipient
      SanctionsConfig.gpg_recipient
    end

    def self.sanctions_screening_start_date
      SanctionsConfig.sanction_screening_start_date
    end

  end
end
