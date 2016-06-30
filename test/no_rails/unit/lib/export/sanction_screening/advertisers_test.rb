require File.dirname(__FILE__) + "/../../../../test_helper"

class Export::SanctionScreening::AdvertisersTest < Test::Unit::TestCase

  context "export_encrypt_and_upload!" do

    should "first export and then encrypt_upload_and_remove" do
      filename = "my_file.txt"
      passphrase = "secret"
      recipient = "songbird"
      sanction_date = Time.now
      Export::SanctionScreening::Advertisers.expects(:export_to_pipe_delimited_file!).with(sanction_date).returns(filename)
      Export::SanctionScreening::Upload.expects(:encrypt_upload_and_remove!).with(filename, passphrase, recipient)
      Export::SanctionScreening::Advertisers.export_encrypt_and_upload!(passphrase, recipient, sanction_date)
    end

  end

end
