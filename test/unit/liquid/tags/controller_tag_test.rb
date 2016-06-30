require File.dirname(__FILE__) + "/../../../test_helper"

class ControllerTagTest < ActiveSupport::TestCase

  test "render controller_name" do
    controller = ApplicationController.new
    controller.action_name = "test"

    registers = { :controller => controller }

    assert_equal "application", Liquid::Template.parse("{% controller controller_name %}").render({}, :registers => registers)
    assert_equal "test", Liquid::Template.parse("{% controller action_name %}").render({}, :registers => registers)
  end

end
