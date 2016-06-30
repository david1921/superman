require File.dirname(__FILE__) + "/../test_helper"

class AffiliatePlacementTest < ActiveSupport::TestCase
  
  context ".not_deleted" do
    
    should "return only affiliate placements whose deleted_at is null" do
      ap1 = Factory :affiliate_placement
      ap2 = Factory :affiliate_placement
      assert_equal 2, AffiliatePlacement.not_deleted.count
      ap1.soft_delete!
      assert_equal 1, AffiliatePlacement.not_deleted.count
    end
    
  end
  
  context "#soft_delete!" do
    
    should "set the deleted_at attribute of the AffiliatePlacement object" do
      affiliate_placement = Factory :affiliate_placement
      assert_nil affiliate_placement.deleted_at
      affiliate_placement.soft_delete!
      assert affiliate_placement.deleted_at.is_a?(ActiveSupport::TimeWithZone)
    end
    
  end
  
  context "#undelete!" do
    
    should "unset the deleted_at attribute of the AffiliatePlacement object" do
      affiliate_placement = Factory :affiliate_placement, :deleted_at => Time.now
      
      assert affiliate_placement.deleted_at.present?
      assert affiliate_placement.deleted?
      affiliate_placement.undelete!
      assert !affiliate_placement.deleted?
      assert_nil affiliate_placement.deleted_at
    end
    
  end
  
end
