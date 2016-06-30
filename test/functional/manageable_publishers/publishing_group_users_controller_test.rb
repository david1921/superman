require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ManageablePublishers::PublishingGroupUsersControllerTest

module ManageablePublishers
  
  class PublishingGroupUsersControllerTest < ActionController::TestCase
    
    tests PublishingGroupUsersController
    
    def setup
      @publishing_group = Factory :publishing_group, :name => "Some Pub Group", :label => "pubgroup", :self_serve => true
      @publisher_1 = Factory :publisher, :label => "pub-one", :publishing_group => @publishing_group
      @publisher_2 = Factory :publisher, :label => "pub-two", :publishing_group => @publishing_group
      @publisher_3 = Factory :publisher, :label => "pub-three", :publishing_group => @publishing_group
      @publisher_4 = Factory :publisher, :label => "pub-four"
      
      @admin = Factory :admin
      login_as @admin
    end
    
    context "GET to :new" do
      
      setup do
        get :new, :publishing_group_id => @publishing_group.to_param
      end

      should "response successfully" do
        assert_response :success
      end
      
      should "show radio buttons to allow access to all or only some publishers for the group" do
        assert_select "input[name=access_perms][value=all]"
        assert_select "input[name=access_perms][value=restricted]"
      end
      
      should "should include a checkbox for each publisher in the group" do
        assert_select "input[name='user[manageable_publishers][publisher_id][]']", :count => 3
        [@publisher_1, @publisher_2, @publisher_3].each do |publisher|
          assert_select "input[name='user[manageable_publishers][publisher_id][]'][value=#{publisher.id}]" do
            assert_select "input[checked]", false
          end
        end
      end
      
    end
    
    context "POST to :create" do
      
      should "create the user with no manageable_publishers when access_perms is 'all'" do
        assert !User.exists?(:login => 'testuser1')
        assert_difference "User.count", 1 do
          post :create, :publishing_group_id => @publishing_group.to_param,
               :user => { :login => "testuser1", :password => "foobar", :password_confirmation => "foobar" },
               :access_perms => "all"
        end
        assert_redirected_to publishing_group_users_url(@publishing_group)
        testuser = User.find_by_login('testuser1')
        assert testuser.manageable_publishers.blank?
      end
      
      should "create the user with the associated manageable publishers when access_perms is 'restricted'" do
        assert !User.exists?(:login => 'testuser1')
        assert_difference "User.count", 1 do
          post :create, :publishing_group_id => @publishing_group.to_param, :access_perms => "restricted",
          :user => { :login => "testuser1", :password => "foobar", :password_confirmation => "foobar",
                     :manageable_publishers => { :publisher_id => [@publisher_1.id, @publisher_2.id] } }
        end
        assert_redirected_to publishing_group_users_url(@publishing_group)
        testuser = User.find_by_login('testuser1')
        assert_equal [@publisher_1.id, @publisher_2.id], testuser.manageable_publishers.map(&:publisher_id).sort
      end
      
    end
    
    context "GET to :edit" do
      
      setup do
        @user = create_user_with_company :company => @publishing_group
      end
      
      should "have access_perms 'all' selected when the user.manageable_publishers is blank" do
        assert @user.manageable_publishers.blank?
        get :edit, :publishing_group_id => @publishing_group.to_param, :id => @user.to_param
        assert_response :success
        assert_select "input#allow-for-all[checked=checked]"
        assert_select "input#allow-for-some" do
          assert_select "input[checked=checked]", false
        end
        assert_match /selected-pubs-container.*display:\s*none/, @response.body
      end
      
      should "have access_perms 'restricted' selected, and each of the relevant pubs checked when " +
             "user.manageable_publishers is not blank" do
        Factory :manageable_publisher, :publisher => @publisher_1, :user => @user
        Factory :manageable_publisher, :publisher => @publisher_2, :user => @user
        @user.reload
        get :edit, :publishing_group_id => @publishing_group.to_param, :id => @user.to_param
        assert_response :success
        assert_select "input#allow-for-all" do
          assert_select "input[checked=checked]", false
        end
        assert_select "input#allow-for-some[checked=checked]"
        assert_select "input[name='user[manageable_publishers][publisher_id][]']", :count => 3 do
          assert_select "input[checked=checked][value=#{@publisher_1.id}]"
          assert_select "input[checked=checked][value=#{@publisher_2.id}]"
          assert_select "input[value=#{@publisher_3.id}]" do
            assert_select "input[checked=checked]", false
          end
        end
        assert_no_match /selected-pubs-container.*display:\s*none/, @response.body        
      end
      
    end
    
    context "POST to :update, for a user whose manageable_publishers was blank (i.e. no restrictions)" do
      
      setup do
        @user = create_user_with_company :company => @publishing_group
        assert @user.manageable_publishers.blank?
      end
      
      context "access_perms 'all'" do
        
        should "not create any manageable_publishers" do
          assert_no_difference "User.count" do
            post :update, :publishing_group_id => @publishing_group.to_param, :id => @user.to_param,
                 :user => { :login => @user.login}, :access_perms => "all"
          end
          
          assert @user.manageable_publishers.blank?
          assert_redirected_to publishing_group_users_url(@publishing_group)
          assert_match /updated/i, flash[:notice]
        end
                
      end
      
      context "access_perms 'restricted' with publishers specified" do
        
        should "create a ManageablePublisher for each specified publisher, for this user" do
          assert_no_difference "User.count" do
            assert_difference "ManageablePublisher.count", 2 do
              post :update, :publishing_group_id => @publishing_group.to_param, :id => @user.to_param, :access_perms => "restricted",
                   :user => {
                     :login => @user.login,
                     :manageable_publishers => { :publisher_id => [@publisher_1.id, @publisher_2.id] }}
            end
          end
          
          @user.reload
          assert_equal [@publisher_1.id, @publisher_2.id], @user.manageable_publisher_ids.sort
          assert_redirected_to publishing_group_users_url(@publishing_group)
          assert_match /updated/i, flash[:notice]
        end
        
      end
      
    end
    
    context "POST to :update, for a user who has manageable_publishers (i.e. can only manage some pubs in the group)" do
      
      setup do
        @user = create_user_with_company :company => @publishing_group
        Factory :manageable_publisher, :publisher => @publisher_2, :user => @user
        Factory :manageable_publisher, :publisher => @publisher_3, :user => @user
        @user.reload
        assert @user.manageable_publishers.present?
      end
      
      context "access_perms 'all'" do
        
        should "clear the user's manageable_publishers list" do
          assert_difference "ManageablePublisher.count", -2 do
            post :update, :publishing_group_id => @publishing_group.to_param, :id => @user.to_param, :access_perms => "all",
                 :user => { :login => @user.login }
          end
          
          assert @user.reload.manageable_publishers.blank?
          assert_redirected_to publishing_group_users_url(@publishing_group)
          assert_match /updated/i, flash[:notice]
        end
        
      end
      
      context "access_perms 'all', with publishers selected" do
        
        should "clear the user's manageable_publishers list" do
          assert_difference "ManageablePublisher.count", -2 do
            post :update, :publishing_group_id => @publishing_group.to_param, :id => @user.to_param, :access_perms => "all",
                 :user => { :login => @user.login, :manageable_publishers => { :publisher_id => [@publisher_2.id, @publisher_3.id] } }
          end
          
          assert @user.reload.manageable_publishers.blank?
          assert_redirected_to publishing_group_users_url(@publishing_group)
          assert_match /updated/i, flash[:notice]
        end
        
      end
      
      context "access_perms 'restricted' with publishers specified" do
        
        setup do
          @new_pub = Factory :publisher, :publishing_group => @publishing_group
        end
        
        should "replace the user's existing manageable_publishers with the new list of publishers" do
          assert_difference "ManageablePublisher.count", -1 do
            post :update, :publishing_group_id => @publishing_group.to_param, :id => @user.to_param, :access_perms => "restricted",
                 :user => { :login => @user.login, :manageable_publishers => { :publisher_id => [@new_pub.id] } }
          end
          
          assert_equal [@new_pub.id], @user.reload.manageable_publisher_ids
          assert_redirected_to publishing_group_users_url(@publishing_group)
          assert_match /updated/i, flash[:notice]
          
        end
        
      end
      
    end
    
  end
  
end