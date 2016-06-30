module Export
  module SanctionScreening
    module Encrypt

      def self.private_key_encrypt(filename, passphrase)
        unless run_command(encryption_command(filename, passphrase))
          raise "Encryption failed for #{filename}"
        end
        "#{filename}.gpg"
      end

      def self.public_key_encrypt(filename, recipient, force = true)
        unless run_command(public_key_encryption_command(filename, recipient, force))
          raise "Public-key encryption of #{filename} failed for recipient #{recipient}, force #{force}"
        end
        "#{filename}.gpg"
      end

      def self.encryption_command(filename, passphrase)
        "echo \'#{passphrase}\' | gpg --no-tty --passphrase-fd 0 -c #{filename}"
      end

      def self.public_key_encryption_command(filename, recipient, force)
        "gpg --encrypt #{'--yes' if force} --recipient '#{recipient}' #{filename}"
      end

      def self.run_command(command)
        system(command)
      end

    end
  end
end
