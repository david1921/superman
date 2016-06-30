require File.dirname(__FILE__) + "/../test_helper"

class BarCodeTest < ActiveSupport::TestCase
  context "ordering" do
    setup do
      BarCode.delete_all
      @daily_deal = Factory(:daily_deal)
      @barcode1 = Factory(:bar_code, :bar_codeable => @daily_deal)
      @barcode2 = Factory(:bar_code, :bar_codeable => @daily_deal)
      @barcode3 = Factory(:bar_code, :bar_codeable => @daily_deal)
      @barcode4 = Factory(:bar_code)
    end

    should "give incremental positions scoped by bar_codeable_id" do
      assert_equal 1, @barcode1.position
      assert_equal 2, @barcode2.position
      assert_equal 3, @barcode3.position
      assert_equal 1, @barcode4.position
    end
  end
end
