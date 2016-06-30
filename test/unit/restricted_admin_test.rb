require File.dirname(__FILE__) + "/../test_helper"

class RestrictedAdminTest < ActiveSupport::TestCase

  fast_context "restricted and unrestricted admin permissions" do
    
    setup do
      PublishingGroup.delete_all
      Publisher.delete_all
      Advertiser.delete_all
      @publishing_group_1 = Factory :publishing_group, :label => "pg1"
      @publishing_group_2 = Factory :publishing_group, :label => "pg2"
      @publishing_group_3 = Factory :publishing_group, :label => "pg3"

      @publisher_1 = Factory :publisher, :label => "p1", :publishing_group => nil
      @publisher_2 = Factory :publisher, :label => "p2", :publishing_group => nil
      @publisher_3 = Factory :publisher, :label => "p3", :publishing_group => @publishing_group_2
      @publisher_4 = Factory :publisher, :label => "p4", :publishing_group => @publishing_group_3
      
      @advertiser_1 = Factory :advertiser, :publisher => @publisher_1, :name => "a1" 
      @advertiser_2 = Factory :advertiser, :publisher => @publisher_2, :name => "a2" 
      @advertiser_3 = Factory :advertiser, :publisher => @publisher_3, :name => "a3" 

      @admin = Factory :admin
      
      @restricted_admin = Factory :restricted_admin
      @restricted_admin.user_companies << UserCompany.new(:company => @publishing_group_2)
      @restricted_admin.user_companies << UserCompany.new(:company => @publisher_1)      
    end

    fast_context "Publisher#manageable_by for restricted admins" do

      should "return only the publishers which the restricted admin user can access" do
        assert_equal ["p1", "p3"], Publisher.manageable_by(@restricted_admin).map(&:label).sort
      end

    end
    
    fast_context "Publisher#observable_by for restricted admins" do
      
      should "return only the publishers which the restricted admin user can access" do
        assert_equal ["p1", "p3"], Publisher.observable_by(@restricted_admin).map(&:label).sort
      end
      
    end

    fast_context "PublishingGroup#manageable_by" do

      should "return all publishing groups for an unrestricted admin" do
        assert_equal ["pg1", "pg2", "pg3"], PublishingGroup.manageable_by(@admin).map(&:label).sort
      end

      should "return only the publishing groups that a restricted admin can access" do
        admin = Factory :restricted_admin
        admin.user_companies << UserCompany.new(:company => @publishing_group_2)
        admin.user_companies << UserCompany.new(:company => @publisher_4)
        assert_equal ["pg2", "pg3"], PublishingGroup.manageable_by(admin).map(&:label).sort
      end
      
      should "return no publishing groups for a non-admin user associated to a publisher in a group" do
        user = Factory :user, :company => @publisher_4
        assert_equal [], PublishingGroup.manageable_by(user)
      end
      
      should "return no publishing groups for a non-admin user associated with a publishing group " do
        user = Factory :user, :company => @publishing_group_3
        assert_equal [], PublishingGroup.manageable_by(user)
      end
      
    end
    
    fast_context "Advertiser#manageable_by" do
      
      should "return all advertisers for an unrestricted admin" do
        assert_equal ["a1", "a2", "a3"], Advertiser.manageable_by(@admin).map(&:name).sort
      end
      
      should "return only the advertisers that a restricted admin can access" do
        assert_equal ["a1", "a3"], Advertiser.manageable_by(@restricted_admin).map(&:name).sort
      end
      
    end
    
    fast_context "User#set_companies" do
      
      should "only be callable on a restricted admin user" do
        user = Factory :user
        
        assert_raises(RuntimeError) { user.set_companies }
        assert_raises(RuntimeError) { @admin.set_companies }
        assert_nothing_raised { @restricted_admin.set_companies }
      end
      
      should "set create UserCompany rows for the publisher ids and pub group ids passed as arguments" do
        user = Factory :restricted_admin
        assert user.user_companies.blank?
        assert_difference "UserCompany.count", 3 do
          user.set_companies(:publisher_ids => [@publisher_1.id],
                             :publishing_group_ids => [@publishing_group_2.id, @publishing_group_3.id])
        end
        assert_equal ["p1", "pg2", "pg3"], user.reload.companies.map(&:label).sort
      end
      
      should "replace any existing UserCompany rows with new UserCompany rows" do
        user = Factory :restricted_admin
        user.set_companies(:publisher_ids => [@publisher_1.id])
        assert_equal ["p1"], user.reload.companies.map(&:label)
        
        user.set_companies(:publisher_ids => [@publisher_2.id])
        assert_equal ["p2"], user.reload.companies.map(&:label)        
      end
      
    end
        
  end
  
end