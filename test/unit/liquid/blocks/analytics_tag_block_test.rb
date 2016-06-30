require File.dirname(__FILE__) + "/../../../test_helper"

class AnalyticsTagBlockTest < ActiveSupport::TestCase
  test "render with signup analytics tag" do
    controller = ApplicationController.new
    controller.send("analytics_tag=", AnalyticsTag.new.signup!)
    registers = { :controller => controller }
    
    assert_equal "<br/>", Liquid::Template.parse("{% analytics_tag signup %}<br/>{% endanalytics_tag %}").render({}, :registers => registers)
    assert_equal "", Liquid::Template.parse("{% analytics_tag landing %}<br/>{% endanalytics_tag %}").render({}, :registers => registers)
    assert_equal "", Liquid::Template.parse("{% analytics_tag foo %}<br/>{% endanalytics_tag %}").render({}, :registers => registers)
  end

  test "render with default analytics tag" do
    controller = ApplicationController.new
    controller.send("analytics_tag=", AnalyticsTag.new)
    registers = { :controller => controller }
    
    assert_equal "", Liquid::Template.parse("{% analytics_tag signup %}<br/>{% endanalytics_tag %}").render({}, :registers => registers)
    assert_equal "", Liquid::Template.parse("{% analytics_tag foo %}<br/>{% endanalytics_tag %}").render({}, :registers => registers)
  end

end
