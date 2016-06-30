require File.dirname(__FILE__) + "/../../test_helper"

class ActsAsLabelledTest < ActiveSupport::TestCase

  test "find_by_label_or_id should search by id only when number is given" do
    assert Publisher.included_modules.include?(ActsAsLabelled)

    publisher = Factory(:publisher, :label => "8coupons")

    assert_equal publisher, Publisher.find_by_label_or_id("8coupons")
  end
end
