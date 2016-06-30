require File.dirname(__FILE__) + "/../../models_helper"

class Advertisers::LabelTest < Test::Unit::TestCase

  def setup
    @obj = Object.new.extend(Advertisers::Label)
  end

  context "#generate_unique_label" do
    setup do
      @obj.stubs(:label).returns('not blank')
      @obj.stubs(:name).returns('not blank')
    end

    should "not change the label if it's present" do
      @obj.expects(:generate_unique_label).never
      @obj.generate_label_from_name
    end

    should "not change the label if the name is blank" do
      @obj.stubs(:label).returns(nil)
      @obj.stubs(:name).returns(nil)
      @obj.expects(:generate_unique_label).never
      @obj.generate_label_from_name
    end
  end
end
