require File.dirname(__FILE__) + "/../../../test_helper"

class AnalyticsTagDataTagTest < ActiveSupport::TestCase
  test "render with sale analytics tag" do
    controller = ApplicationController.new
    controller.send("analytics_tag=", AnalyticsTag.new.sale!(:value => 1.23, :quantity => 2, :item_id => "1234", :sale_id => "9876"))
    registers = { :controller => controller }
    
    assert_equal "1.23", Liquid::Template.parse("{% analytics_tag_data value %}").render({}, :registers => registers)
    assert_equal "2", Liquid::Template.parse("{% analytics_tag_data quantity %}").render({}, :registers => registers)
    assert_equal "1234", Liquid::Template.parse("{% analytics_tag_data item_id %}").render({}, :registers => registers)
    assert_equal "9876", Liquid::Template.parse("{% analytics_tag_data sale_id %}").render({}, :registers => registers)
    assert_equal "", Liquid::Template.parse("{% analytics_tag_data foo %}").render({}, :registers => registers)
  end

  test "render with signup analytics tag" do
    controller = ApplicationController.new
    controller.send("analytics_tag=", AnalyticsTag.new.signup!)
    registers = { :controller => controller }
    
    assert_equal "", Liquid::Template.parse("{% analytics_tag_data value %}").render({}, :registers => registers)
    assert_equal "", Liquid::Template.parse("{% analytics_tag_data foo %}").render({}, :registers => registers)
  end

  test "render with default analytics tag" do
    controller = ApplicationController.new
    controller.send("analytics_tag=", AnalyticsTag.new)
    registers = { :controller => controller }
    
    assert_equal "", Liquid::Template.parse("{% analytics_tag_data value %}").render({}, :registers => registers)
    assert_equal "", Liquid::Template.parse("{% analytics_tag_data foo %}").render({}, :registers => registers)
  end
end
