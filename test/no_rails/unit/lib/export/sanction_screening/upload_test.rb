require File.dirname(__FILE__) + "/../../../../test_helper"
require File.dirname(__FILE__) + "/../../../../../../lib/tasks/uploader"

# hydra class Export::SanctionScreening::UploadTest
class Export::SanctionScreening::UploadTest < Test::Unit::TestCase

  context "upload_pipe_delimited_file!" do

    should "make proper calls to upload the exported file" do
      fake_config = stub("config")
      Export::SanctionScreening::Upload.stubs(:ensure_file_exists!)
      Export::SanctionScreening::Upload.stubs(:upload_config).returns(fake_config)
      fake_uploader = stub("uploader")
      fake_uploader.expects(:upload).with("barclays_upload", "/some/test/file.txt")
      Uploader.
          expects(:new).
          with(fake_config).
          returns(fake_uploader)

      Export::SanctionScreening::Upload.upload_file!("barclays_upload", "/some/test/file.txt")
    end

  end

  context "encrypt_upload_and_remove!" do

    should "make sure file is encrypted and uploaded twice" do
      filename = "my_file.txt"
      passphrase = "secret"
      recipient = "sonbird"

      Export::SanctionScreening::Encrypt.expects(:private_key_encrypt).with(filename, passphrase).returns("#{filename}.gpg")
      Export::SanctionScreening::Upload.expects(:upload_file!).with("barclays_upload", "#{filename}.gpg")
      Export::SanctionScreening::Encrypt.expects(:public_key_encrypt).with(filename, recipient).returns("#{filename}.gpg")
      Export::SanctionScreening::Upload.expects(:upload_file!).with("barclays_from_ocean", "#{filename}.gpg")
      FileUtils.expects(:rm).with(filename).once

      Export::SanctionScreening::Upload.encrypt_upload_and_remove!(filename, passphrase, recipient)
    end

  end

end
