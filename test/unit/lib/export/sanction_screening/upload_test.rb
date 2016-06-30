require File.dirname(__FILE__) + "/../../../../test_helper"
require File.dirname(__FILE__) + "/../../../../../lib/tasks/uploader"

class Export::SanctionScreening::UploadTest < ActiveSupport::TestCase

  context "upload_config" do

    should "use barclays upload" do
      config = Export::SanctionScreening::Upload.upload_config
      assert_equal "upload", config["barclays_upload"][:path]
      assert_equal "upload/from_ocean", config["barclays_from_ocean"][:path]
    end

  end

end
