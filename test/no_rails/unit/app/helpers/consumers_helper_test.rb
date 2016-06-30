require File.dirname(__FILE__) + "/../helpers_helper"

class ConsumersHelperTest < Test::Unit::TestCase
  def setup
    @helper = Object.new.extend(ConsumersHelper)
  end

  context "#options_for_locale_select" do
      setup do
        @mock_publisher = mock("publisher")
        @mock_publisher.stubs(:enabled_locales_for_consumer).returns(["en", "es-MX", "es"])
        @helper.stubs(:locale_full_name).with("en").returns("English")
        @helper.stubs(:locale_full_name).with("es").returns("Español")
        @helper.stubs(:locale_full_name).with("es-MX").returns("Español (México)")
      end

      should "return a sorted array of locale [shorthand, full_name] for the publisher" do
        assert_equal [["English", "en"], ["Español", "es"], ["Español (México)", "es-MX"]], @helper.options_for_locale_select(@mock_publisher)
      end
    end
end