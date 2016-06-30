require File.dirname(__FILE__) + "/../../helpers_helper"

class Analog::ThemeHelperTest < Test::Unit::TestCase

  class MockHelper
    include Analog::ThemeHelper
  end

  def setup
    @helper = Object.new.extend(Analog::ThemeHelper)
  end

  context "#find_template" do
    should "return generic template when publisher_or_group arg is nil" do
      mock_view_paths = mock("view_paths")
      mock_found_template = mock('found generic template')
      mock_view_paths.stubs(:find_template).with("edit", :html).returns(mock_found_template)
      @helper.stubs(:view_paths).returns(mock_view_paths)

      assert_equal mock_found_template, @helper.find_template(nil, "edit")
    end

    should "return themed template when non-nil publisher_or_group" do
      mock_publisher = mock("publisher", :uses_a_ready_made_theme? => true, :label => "pub_label")
      mock_themed_template = mock("themed template")
      mock_view_paths = mock("view_paths")
      @helper.stubs(:view_paths).returns(mock_view_paths)
      mock_view_paths.stubs(:find_template).with("themes/pub_label/edit", :html, false).returns(mock_themed_template)
      assert_equal mock_themed_template, @helper.find_template(mock_publisher, "edit")
    end
  end


end