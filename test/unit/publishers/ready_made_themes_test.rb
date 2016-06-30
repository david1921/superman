require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Publishers::ReadyMadeThemesTest

module Publishers
  
  class ReadyMadeThemesTest < ActiveSupport::TestCase
    
    TEST_PUBLISHER = "test-uses-ready-made-theme"
    TEST_THEME = "cleverbetta"
    
    context "#uses_a_ready_made_theme?" do
      
      should "return true if the publisher has a parent_theme set" do
        publisher = Factory :publisher, :label => TEST_PUBLISHER, :parent_theme => TEST_THEME
        assert publisher.uses_a_ready_made_theme?
      end
      
      should "return false if the publisher does not have a parent_theme set" do
        publisher = Factory :publisher, :label => "someotherpub"
        assert !publisher.uses_a_ready_made_theme?
      end
      
    end
    
    context "#parent_theme" do
      
      should "return the name of the parent theme used by a publisher that uses a ready made theme" do
        publisher = Factory :publisher, :label => TEST_PUBLISHER, :parent_theme => TEST_THEME
        assert_equal TEST_THEME, publisher.parent_theme
      end
      
      should "must be one of howlingwolf, roaringlion, dramaticchipmunk, or cleverbetta, or nil" do
        publisher = Factory :publisher, :label => "someotherpub"
        assert publisher.parent_theme.nil?
        assert publisher.valid?
        
        publisher.parent_theme = "howlingwolf"
        assert publisher.valid?
        
        publisher.parent_theme = "roaringlion"
        assert publisher.valid?
        
        publisher.parent_theme = "dramaticchipmunk"
        assert publisher.valid?

        publisher.parent_theme = "cleverbetta"
        assert publisher.valid?
        
        publisher.parent_theme = "someinvalidtheme"
        assert publisher.invalid?
        
        assert_equal "is not a valid theme", publisher.errors.on(:parent_theme)
      end
      
    end
    
  end
  
end