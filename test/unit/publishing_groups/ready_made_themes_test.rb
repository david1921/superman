require File.dirname(__FILE__) + "/../../test_helper"

# hydra class PublishingGroups::ReadyMadeThemesTest

module PublishingGroups
  
  class ReadyMadeThemesTest < ActiveSupport::TestCase
    
    TEST_PUB_GROUP = "test-pg-uses-ready-made-theme"
    TEST_THEME = "roaringlion"
    
    context "#uses_a_ready_made_theme?" do
      
      should "return true if the publishing group has a parent_theme set" do
        publishing_group = Factory :publishing_group, :label => TEST_PUB_GROUP, :parent_theme => TEST_THEME
        assert publishing_group.uses_a_ready_made_theme?
      end
      
      should "return false if the publishing group does not have a parent_theme set" do
        publishing_group = Factory :publishing_group, :label => "someotherpub"
        assert !publishing_group.uses_a_ready_made_theme?
      end
      
    end
    
    context "#parent_theme" do
      
      should "return the name of the parent theme used by a publishing group that uses a ready made theme" do
        publishing_group = Factory :publishing_group, :label => TEST_PUB_GROUP, :parent_theme => TEST_THEME
        assert_equal TEST_THEME, publishing_group.parent_theme
      end
      
      should "be one of howlingwolf, roaringlion, dramaticchipmunk, or cleverbetta, or nil" do
        publishing_group = Factory :publishing_group, :label => "someotherpub"
        assert publishing_group.parent_theme.nil?
        assert publishing_group.valid?
        
        publishing_group.parent_theme = "howlingwolf"
        assert publishing_group.valid?
        
        publishing_group.parent_theme = "roaringlion"
        assert publishing_group.valid?
        
        publishing_group.parent_theme = "dramaticchipmunk"
        assert publishing_group.valid?

        publishing_group.parent_theme = "cleverbetta"
        assert publishing_group.valid?
        
        publishing_group.parent_theme = "someinvalidtheme"
        assert publishing_group.invalid?
        assert_equal "is not a valid theme", publishing_group.errors.on(:parent_theme)
      end
      
    end
    
  end
  
end