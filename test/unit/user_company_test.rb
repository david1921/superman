require File.dirname(__FILE__) + "/../test_helper"

class UserCompanyTest < ActiveSupport::TestCase
  
  fast_context "UserCompany" do
    
    setup do
      @publisher_1 = Factory :publisher
      @publisher_2 = Factory :publisher
    end
    
    should "allow an admin user to be associated to multiple companies" do
      admin = Factory :restricted_admin
      assert_nothing_raised do
        UserCompany.create! :user => admin, :company => @publisher_1
        UserCompany.create! :user => admin, :company => @publisher_2
      end
      assert_equal 2, admin.companies.size
    end
    
    should "NOT allow a non-admin user to be associated to multiple companies" do
      non_admin = Factory :user_without_company
      assert_nothing_raised do
        UserCompany.create! :user => non_admin, :company => @publisher_1
      end
      second_uc = UserCompany.new(:user => non_admin, :company => @publisher_2)
      assert second_uc.invalid?
      assert_equal ["Non-admin users can be associated to at most one company"], second_uc.errors.full_messages
    end
    
  end
  
end