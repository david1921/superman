require File.dirname(__FILE__) + "/../../models_helper"

class Locales::EnabledTest < Test::Unit::TestCase
  def setup
    @obj = Object.new.extend(Locales::Enabled)
    Rails.stubs(:root).returns(File.expand_path(File.dirname(__FILE__) + "/data"))
    I18n.load_path = [Dir[File.expand_path(File.dirname(__FILE__)) + "/data/config/locales/*.yml"]]
  end

  context "#enabled_locales_to_display" do
    should "return the union of the default and themed locales" do
      @obj.stubs(:label).returns("nakedmolerat")
      assert_same_elements ["en", "es", "es-MX", "en-GB"], @obj.enabled_locales_to_display
    end

    should "return the default locales" do
      @obj.stubs(:label).returns("hairyotter")
      assert_same_elements ["en", "es"], @obj.enabled_locales_to_display
    end
  end
end
