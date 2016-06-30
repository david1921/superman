require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::CouponBorderTypesTest
module Publishers
  module PublisherModel
    class CouponBorderTypesTest < ActiveSupport::TestCase
      test "coupon border types" do
        assert(Publisher::COUPON_BORDER_TYPES.include?("solid"), "there should be a 'solid' option")
        assert(Publisher::COUPON_BORDER_TYPES.include?("dotted"), "there should be a 'dotted' option")
      end

      test "set coupon border to dotted for simple layout" do
        publisher = Factory(:publisher, :name => "New Publisher", :theme => "simple")
        publisher.update_attributes(:coupon_border_type => 'dotted')
        assert_equal("dotted", publisher.coupon_border_type, "publisher should have 'dotted' border type")
      end

      test "set coupon border to invalid border type for simple layout" do
        publisher = Factory(:publisher, :name => "New Publisher", :theme => "simple")
        publisher.update_attributes(:coupon_border_type => 'blah')
        assert_not_equal("dotted", publisher.coupon_border_type, "publisher should have 'dotted' border type")
      end

      test "set coupon border to dotted for narrow layout" do
        publisher = Factory(:publisher, :name => "New Publisher", :theme => "narrow")
        publisher.update_attributes(:coupon_border_type => 'dotted')
        assert_equal("dotted", publisher.coupon_border_type, "publisher should have 'dotted' border type")
      end

      test "set coupon border to invalid border type for narrow layout" do
        publisher = Factory(:publisher, :name => "New Publisher", :theme => "narrow")
        publisher.update_attributes(:coupon_border_type => 'blah')
        assert_not_equal("dotted", publisher.coupon_border_type, "publisher should have 'dotted' border type")
      end
    end
  end
end