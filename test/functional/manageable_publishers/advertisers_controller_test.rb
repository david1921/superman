require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ManageablePublishers::AdvertisersControllerTest

module ManageablePublishers
  
  class AdvertisersControllerTest < ActionController::TestCase
    
    tests AdvertisersController
    
    context "a publishing group user, with access to only some publishers in the group" do
      
      setup do
        @publishing_group = Factory :publishing_group, :self_serve => true
        @publisher_1 = Factory :publisher, :publishing_group => @publishing_group
        @publisher_2 = Factory :publisher, :publishing_group => @publishing_group
        @publisher_3 = Factory :publisher
        
        @pub_1_advertiser = Factory :advertiser, :publisher => @publisher_1
        @pub_2_advertiser = Factory :advertiser, :publisher => @publisher_2
        @pub_3_advertiser = Factory :advertiser, :publisher => @publisher_3
        
        @user = Factory :user, :company => @publishing_group
        Factory :manageable_publisher, :user => @user, :publisher => @publisher_1
        @user.reload
        login_as @user
      end
    
      context "GET to :index in the context of a publisher" do
      
        should "respond with success, if the user has permission to view/edit this publisher" do
          get :index, :publisher_id => @publisher_1.to_param
          assert_response :success
        end
      
        should "respond with a 404 with a publisher_id that does not belong to the user's group" do
          assert_raises ActiveRecord::RecordNotFound do
            get :index, :publisher_id => @publisher_3.to_param
          end
        end
        
        should "respond with a 404 with a publisher_id that belongs to this group, but is not manageable by the user" do
          assert_raises ActiveRecord::RecordNotFound do
            get :index, :publisher_id => @publisher_2.to_param
          end
        end
      
      end

      context "GET to :new in the context of a publisher" do
      
        should "respond with success, if the user has permission to view/edit this publisher" do
          get :new, :publisher_id => @publisher_1.to_param
          assert_response :success
        end
      
        should "respond with a 404 with a publisher_id that does not belong to the user's group" do
          assert_raises ActiveRecord::RecordNotFound do
            get :new, :publisher_id => @publisher_3.to_param
          end
        end
        
        should "respond with a 404 with a publisher_id that belongs to this group, but is not manageable by the user" do
          assert_raises ActiveRecord::RecordNotFound do
            get :new, :publisher_id => @publisher_2.to_param
          end
        end
      
      end
      
      context "POST to :create in the context of a publisher" do
      
        should "respond with success, if the user has permission to view/edit this publisher" do
          assert_difference "Advertiser.count", 1 do
            post :create, :publisher_id => @publisher_1.to_param,
                 :advertiser => { :name => "Awesome Advertiser", :do_not_show_map => "0" }
          end
          assert_redirected_to edit_publisher_advertiser_path(@publisher_1, assigns['advertiser'])
        end
      
        should "respond with a 404 with a publisher_id that does not belong to the user's group" do
          assert_no_difference "Advertiser.count" do
            assert_raises(ActiveRecord::RecordNotFound) do
              post :create, :publisher_id => @publisher_3.to_param,
                   :advertiser => { :name => "Awesome Advertiser", :do_not_show_map => "0" }
            end
          end
        end
        
        should "respond with a 404 with a publisher_id that belongs to this group, but is not manageable by the user" do
          assert_no_difference "Advertiser.count" do
            assert_raises(ActiveRecord::RecordNotFound) do
              post :create, :publisher_id => @publisher_2.to_param,
                   :advertiser => { :name => "Awesome Advertiser", :do_not_show_map => "0" }
            end
          end
        end
      
      end
      
      context "GET to :edit in the context of a publisher" do
      
        should "respond with success, if the user has permission to view/edit this publisher" do
          get :edit, :id => @pub_1_advertiser.to_param
          assert_response :success
        end
      
        should "respond with a 404 with a publisher_id that does not belong to the user's group" do
          assert_raises ActiveRecord::RecordNotFound do
            get :edit, :id => @pub_3_advertiser.to_param
          end
        end
        
        should "respond with a 404 with a publisher_id that belongs to this group, but is not manageable by the user" do
          assert_raises ActiveRecord::RecordNotFound do
            get :edit, :id => @pub_2_advertiser.to_param
          end
        end
      
      end

      context "PUT to :update in the context of a publisher" do
      
        should "respond with success, if the user has permission to view/edit this publisher" do
          put :update, :id => @pub_1_advertiser.to_param, :advertiser => {}
          assert_redirected_to edit_publisher_advertiser_path(@publisher_1, @pub_1_advertiser)
          assert_match /updated/i, flash[:notice]
        end
      
        should "respond with a 404 with a publisher_id that does not belong to the user's group" do
          assert_raises ActiveRecord::RecordNotFound do
            put :update, :id => @pub_3_advertiser.to_param, :advertiser => {}
          end
        end
        
        should "respond with a 404 with a publisher_id that belongs to this group, but is not manageable by the user" do
          assert_raises ActiveRecord::RecordNotFound do
            put :update, :id => @pub_2_advertiser.to_param, :advertiser => {}
          end
        end
      
      end
      
    end
    
  end
  
end