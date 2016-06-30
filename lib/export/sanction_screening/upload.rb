module Export
  module SanctionScreening
    module Upload

      def self.encrypt_upload_and_remove!(filename, passphrase, recipient)
        encrypt_and_upload_with_private_key(filename, passphrase)
        encrypt_and_upload_with_public_key(filename, recipient)
        FileUtils.rm(filename)
      end

      def self.encrypt_and_upload_with_private_key(filename, passphrase)
        encrypted_filename = Export::SanctionScreening::Encrypt.private_key_encrypt(filename, passphrase)
        Export::SanctionScreening::Upload.upload_file!("barclays_upload", encrypted_filename)
      end

      def self.encrypt_and_upload_with_public_key(filename, recipient)
        encrypted_filename = Export::SanctionScreening::Encrypt.public_key_encrypt(filename, recipient)
        Export::SanctionScreening::Upload.upload_file!("barclays_from_ocean", encrypted_filename)
      end

      def self.upload_file!(directory_name, filename)
        ensure_file_exists!(filename)

        Uploader.new(upload_config).upload(directory_name, filename)
      end
      
      def self.upload_config
        UploadConfig.new(:publishing_groups)
      end

      private

      def self.ensure_file_exists!(filename)
        raise ArgumentError, "file '#{filename}' does not exist" unless filename.present? && File.exists?(filename)
      end

    end
  end
end
