require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::BitLyTest
module Publishers
  module PublisherModel
    class BitLyTest < ActiveSupport::TestCase
      test "bit_ly_path_format returns falsey if group config file is present but config key is not present" do
        publisher = Factory(:publisher, :label => "sacbee", :publishing_group => Factory(:publishing_group, :label => "mcclatchy"))
        assert !publisher.bit_ly_path_format(:xxxxxxxxx)
      end

      test "bit_ly_path_format returns falsey if group config file is not present" do
        publisher = Factory(:publisher, :label => "sacbee", :publishing_group => Factory(:publishing_group, :label => "xxxxxxxxx"))
        assert !publisher.bit_ly_path_format(:offers)
      end

      test "bit_ly_path_format returns configured value if group config file is present and config key is present" do
        publisher = Factory(:publisher, :label => "sacbee", :publishing_group => Factory(:publishing_group, :label => "mcclatchy"))
        assert_equal "Coupons?couponid=:offer_id", publisher.bit_ly_path_format(:offers)
      end
    end
  end
end