require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ManageablePublishers::PublishersControllerTest

module ManageablePublishers
  
  class PublishersControllerTest < ActionController::TestCase

    tests PublishersController

    context "a publishing group user viewing the PG's publisher listing" do
      
      setup do
        @publishing_group = Factory :publishing_group, :name => "Some Pub Group", :label => "pubgroup", :self_serve => true
        @publisher_1 = Factory :publisher, :label => "pub-one", :publishing_group => @publishing_group
        @publisher_2 = Factory :publisher, :label => "pub-two", :publishing_group => @publishing_group
        @publisher_3 = Factory :publisher, :label => "pub-three", :publishing_group => @publishing_group
        @publisher_4 = Factory :publisher, :label => "pub-four"
        
        @user = Factory :user, :company => @publishing_group
      end
      
      context "GET to :index" do
      
        should "list all publishers in the group when user.manageable_publishers is blank" do
          assert @user.manageable_publishers.blank?
          
          login_as(@user)
          get :index, :publishing_group_id => @publishing_group.id
          assert_response :success
          assert_select "table.publishers tr.publisher", :count => 3
          assert_match /pub-one/, @response.body
          assert_match /pub-two/, @response.body
          assert_match /pub-three/, @response.body
        end
      
        should "list only publishers in user.manageable_publishers, when present" do
          Factory :manageable_publisher, :publisher => @publisher_3, :user => @user
          @user.reload
          
          login_as(@user)
          get :index, :publishing_group_id => @publishing_group.id
          assert_response :success
          assert_select "table.publishers tr.publisher", :count => 1
          assert_no_match /pub-one/, @response.body
          assert_no_match /pub-two/, @response.body
          assert_match /pub-three/, @response.body
        end
        
      end
      
    end    
  end
    
end