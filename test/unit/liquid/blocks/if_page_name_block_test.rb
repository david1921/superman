require File.dirname(__FILE__) + "/../../../test_helper"

class IfPageNameBlockTest < ActiveSupport::TestCase
  fast_context "if_page_name" do

    setup do
      controller = ApplicationController.new
      controller.stubs(:controller_name).returns('foo')
      controller.stubs(:action_name).returns('bar')
      @registers = {:controller => controller}
    end

    should "render block contents given a true equality" do
      assert_equal "yes", Liquid::Template.parse("{% if_page_name == 'foo#bar' %}yes{% endif_page_name %}").render({}, :registers => @registers)
    end

    should "not render block contents given a false equality" do
      assert_equal "", Liquid::Template.parse("{% if_page_name == 'foo#baz' %}yes{% endif_page_name %}").render({}, :registers => @registers)
    end

    should "default to equals if no comparator given" do
      assert_equal "yes", Liquid::Template.parse("{% if_page_name 'foo#bar' %}yes{% endif_page_name %}").render({}, :registers => @registers)
    end

    should "render block contents given a true negated equality" do
      assert_equal "yes", Liquid::Template.parse("{% if_page_name != 'foo#baz' %}yes{% endif_page_name %}").render({}, :registers => @registers)
    end

    should "not render block contents given a false negated equality" do
      assert_equal "", Liquid::Template.parse("{% if_page_name != 'foo#bar' %}yes{% endif_page_name %}").render({}, :registers => @registers)
    end
  end
end
