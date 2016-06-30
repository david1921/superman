require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::DisplayTextTest
module Publishers
  module PublisherModel
    class DisplayTextTest < ActiveSupport::TestCase
      test "publisher.display_text_for with a default value for a label" do
        publisher = Factory :publisher, :label => "pub-without-custom-label"
        assert_equal "Deal of the Day", publisher.display_text_for(:daily_deal_name)
      end

      test "publisher.display_text_for with a custom label value for the publishing group" do
        publishing_group = Factory :publishing_group, :label => "rr"
        publisher = Factory :publisher, :label => "clickedin-austin", :publishing_group => publishing_group
        assert_equal "Fine Print", publisher.display_text_for(:fine_print_label)
      end

      test "publisher.display_text_for with no default or customized label" do
        publisher = Factory :publisher, :label => "mytestpub"
        assert_equal "", publisher.display_text_for(:doesnt_exist)
      end

      test "publisher.display_text allows providing default values" do
        publisher = publishers(:vcreporter)
        assert_equal "3. Present Deal Certificate upon arrival", publisher.display_text_for(:how_to_use_deal_certificate_step3)
        assert_equal "Super Fine Print", publisher.display_text_for(:fine_print_label, "Super Fine Print")
      end
    end
  end
end
