require File.dirname(__FILE__) + "/../../test_helper"

class Advertisers::AdvertiserOwnersControllerTest < ActionController::TestCase

  context 'controller actions' do
    setup do
      @advertiser = Factory.create(:advertiser)
      @admin = Factory.create(:admin)
    end

    context "#new" do
      should 'render new.html.erb' do
        login_as @admin
        get :new, :advertiser_id => @advertiser.to_param
        assert_template :new
      end
    end

    context "#create" do
      setup do
        @valid_attrs = Factory.attributes_for(:advertiser_owner)
        login_as @admin
      end

      should 'not allow regular users access' do
        login_as Factory(:consumer)
        post :create, :advertiser_id => @advertiser.to_param, :advertiser_owner => @valid_attrs
        assert_response 302
        assert_redirected_to 'http://test.host/session/new'
      end
     
      should "redirect to advertiser edit after creating an owner" do
        post :create, :advertiser_id => @advertiser.to_param, :advertiser_owner => @valid_attrs
        assert_redirected_to edit_advertiser_path(@advertiser)
      end

      should "flash a message after creating an owner" do
        post :create, :advertiser_id => @advertiser.to_param, :advertiser_owner => @valid_attrs
        assert_equal "Created a new owner for #{@advertiser.name}", flash[:notice]
      end

      should "create an advertiser" do
        assert_equal 0, AdvertiserOwner.count
        post :create, :advertiser_id => @advertiser.to_param, :advertiser_owner => @valid_attrs
        assert_equal 1, AdvertiserOwner.count
      end

      should "render the new template if the owner was not saved" do
        post :create, :advertiser_id => @advertiser.to_param, :advertiser_owner => {}
        assert_template :new
      end
    end

    context "#edit" do
      setup do
        @owner = Factory(:advertiser_owner, :advertiser => @advertiser)
      end

      should "load the owner and render the edit template" do
        login_as @admin
        get :edit, :advertiser_id => @advertiser.to_param, :id => @owner.to_param
        assert_equal assigns(:owner), @owner
        assert_template :edit
      end
    end

    context "#update" do
      setup do
        @owner = Factory(:advertiser_owner, :advertiser => @advertiser)
        login_as @admin
      end

      should "require admin access" do
        login_as Factory(:consumer)
        put :update, :advertiser_id => @advertiser.to_param, :id => @owner.to_param, :advertiser_owner => {:first_name => 'some new name'}
        assert_response 302
        assert_redirected_to 'http://test.host/session/new'
      end

      should "redirect to advertiser edit after an update" do
        put :update, :advertiser_id => @advertiser.to_param, :id => @owner.to_param, :advertiser_owner => {:first_name => 'some new name'}
        assert_redirected_to edit_advertiser_path(@advertiser)
      end

      should "flash a message after an update" do
        put :update, :advertiser_id => @advertiser.to_param, :id => @owner.to_param, :advertiser_owner => {:first_name => 'some new name'}
        assert_equal "Updated advertiser #{@advertiser.name}", flash[:notice]
      end
   
      should "update the owner" do
        put :update, :advertiser_id => @advertiser.to_param, :id => @owner.to_param, :advertiser_owner => {:first_name => 'some new name'}
        assert_equal 'some new name', @owner.reload.first_name 
      end 

      should "render the edit template when the owner cannot be updated" do
        put :update, :advertiser_id => @advertiser.to_param, :id => @owner.to_param, :advertiser_owner => {:first_name => nil } 
        assert_template :edit
      end
    end

    context "#destroy" do
      setup do
        @owner = Factory(:advertiser_owner, :advertiser => @advertiser)
        login_as @admin
      end

      should "delete the owner" do
        assert_equal 1, @advertiser.advertiser_owners.count
        delete :destroy, :advertiser_id => @advertiser.to_param, :id => @owner.to_param
        assert_equal 0, @advertiser.reload.advertiser_owners.reload.count
      end

      should "flash a message" do
        delete :destroy, :advertiser_id => @advertiser.to_param, :id => @owner.to_param
        assert_equal "Deleted the advertiser's owner", flash[:notice]
      end

      should "require admin access" do
        login_as Factory(:consumer) 
        delete :destroy, :advertiser_id => @advertiser.to_param, :id => @owner.to_param
        assert_response 302
        assert_redirected_to 'http://test.host/session/new'
      end
    end
  end
end
