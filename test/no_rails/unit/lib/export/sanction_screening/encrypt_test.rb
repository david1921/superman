require File.dirname(__FILE__) + "/../../../../test_helper"

class Export::SanctionScreening::EncryptTest < Test::Unit::TestCase

  context "encryption_command" do

    should "return the right command when given a file and passphrase" do
      filename = "tmp/sanction_screening_publishers_2012041522001334556000.txt"
      assert_equal "echo 'donottell' | gpg --no-tty --passphrase-fd 0 -c #{filename}", Export::SanctionScreening::Encrypt.encryption_command(filename, "donottell")
    end

  end

  context "encrypt" do
    should "run the encryption command happy path" do
      filename = "my_file"
      passphrase = "secret"
      Export::SanctionScreening::Encrypt.expects(:encryption_command).with(filename, passphrase).returns("doit")
      Export::SanctionScreening::Encrypt.expects(:run_command).with("doit").returns(true)
      assert_equal "my_file.gpg", Export::SanctionScreening::Encrypt.private_key_encrypt(filename, passphrase)
    end
    should "run the encryption command something bad happened" do
      filename = "my_file"
      passphrase = "secret"
      Export::SanctionScreening::Encrypt.expects(:encryption_command).with(filename, passphrase).returns("doit")
      Export::SanctionScreening::Encrypt.expects(:run_command).with("doit").returns(false)
      e = assert_raises RuntimeError do
        Export::SanctionScreening::Encrypt.private_key_encrypt(filename, passphrase)
      end
      assert_equal "Encryption failed for #{filename}", e.message
    end
  end

end
