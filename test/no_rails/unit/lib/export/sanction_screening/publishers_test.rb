require File.dirname(__FILE__) + "/../../../../test_helper"

class Export::SanctionScreening::PublishersTest < Test::Unit::TestCase

  context "export_encrypt_and_upload!" do

    should "first export and then encrypt_upload_and_remove" do
      filename = "my_file.txt"
      passphrase = "secret"
      recipient = "recipient"
      Export::SanctionScreening::Publishers.expects(:export_to_pipe_delimited_file!).returns(filename)
      Export::SanctionScreening::Upload.expects(:encrypt_upload_and_remove!).with(filename, passphrase, recipient)
      Export::SanctionScreening::Publishers.export_encrypt_and_upload!(passphrase, recipient)
    end

  end

end
