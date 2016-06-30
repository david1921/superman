require File.dirname(__FILE__) + "/../test_helper"

class NumericExtensionsTest < ActiveSupport::TestCase
  context "is_fractional?" do
    context "given Integer" do
      should "return false" do
        assert !1.is_fractional?
      end
    end

    context "given Float" do
      should "return true when fractional" do
        assert 5.2.is_fractional?
      end

      should "return false when not fractional" do
        assert !2.000.is_fractional?
      end
    end

    context "using Liquid" do
      should "be callable" do
        assert_equal "yes", Liquid::Template.parse("{% if num.is_fractional? %}yes{% endif %}").render("num" => 3.01)
      end
    end
  end
end
