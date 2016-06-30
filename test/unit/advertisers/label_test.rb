require File.dirname(__FILE__) + "/../../test_helper"

class Advertisers::LabelTest < ActiveSupport::TestCase
  context "#generate_label_from_name" do
    setup do
      @a0 = Factory(:advertiser, :name => 'Merchant Name')
      assert_equal "merchant-name", @a0.label
      @a2 = Factory(:advertiser, :name => @a0.name, :publisher => @a0.publisher(true))
      assert_equal "merchant-name-2", @a2.label
    end

    should "generate a unique label" do
      @a3 = Factory(:advertiser, :name => @a0.name, :publisher => @a0.publisher(true))
      assert_equal "merchant-name-3", @a3.label
    end

    should "generate a unique label if advertiser was deleted" do
      @a0.delete # there used to be a bug triggered by this scenario
      @a3 = Factory(:advertiser, :name => @a0.name, :publisher => @a0.publisher(true))
      assert_equal "merchant-name-3", @a3.label
    end
  end
end