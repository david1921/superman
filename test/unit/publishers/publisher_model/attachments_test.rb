require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::AttachmentsTest
module Publishers
  module PublisherModel
    class AttachmentsTest < ActiveSupport::TestCase
      test "attachment_style_geometry returns configured value if config file is present and config key is present" do
        publisher = Factory(:publisher, :label => "nydailynews")
        assert_equal "300x276#", publisher.attachment_style_geometry(:daily_deal, :photo, :email)
      end

      test "attachment_style_geometry returns configured value for entercomnew" do
        publisher = Factory(:publisher, :label => "entercomnew")
        assert_equal "440x265>", publisher.attachment_style_geometry(:daily_deal, :photo, :standard)
      end

      test "attachment_style_geometry returns falsey if config file is present but config key is not present" do
        publisher = Factory(:publisher, :label => "nydailynews")
        assert !publisher.attachment_style_geometry(:daily_deal, :photo, :xxxxx)
      end

      test "attachment_style_geometry returns falsey if config file is not present" do
        publisher = Factory(:publisher, :label => "xxxxxxxxxxx")
        assert !publisher.attachment_style_geometry(:daily_deal, :photo, :email)
      end
    end
  end
end