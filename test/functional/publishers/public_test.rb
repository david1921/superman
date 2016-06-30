require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::PublicTest < ActionController::TestCase
  tests PublishersController

  context "help" do
    
    context "with default publisher template" do

      setup do
        @publisher = Factory(:publisher, :label => "pglabel" )
      end

      should "render the appropriate default template" do
        get :help, :id => @publisher.label
        assert_response :success
        assert assigns(:publisher)
        assert_template :help
        assert_layout   :daily_deals
      end

    end

    context "with a publisher with their custom template" do

      setup do
        @publisher = Factory(:publisher, :label => "bespoke")
      end

      should "render the publisher template" do
        get :help, :id => @publisher.label
        assert_response :success
        assert assigns(:publisher)
        assert_template "bespoke/publishers/help"
        assert_layout   :daily_deals
      end

    end

  end

  context "seller" do
    
    context "with default publisher template" do

      setup do
        @publisher = Factory(:publisher, :label => "pglabel" )
      end

      should "render the appropriate default template" do
        get :seller, :id => @publisher.label
        assert_response :success
        assert assigns(:publisher)
        assert_template :seller
        assert_layout   :daily_deals
      end

    end

    context "with a publisher with their custom template" do

      setup do
        @publisher = Factory(:publisher, :label => "bespoke")
      end

      should "render the publisher template" do
        get :seller, :id => @publisher.label
        assert_response :success
        assert assigns(:publisher)
        assert_template "bespoke/publishers/seller"
        assert_layout   :daily_deals
      end

    end

  end


  context "search" do
    
    context "with default publisher template" do

      setup do
        @publisher = Factory(:publisher, :label => "pglabel" )
      end

      should "render the appropriate default template" do
        get :search, :id => @publisher.label
        assert_response :success
        assert assigns(:publisher)
        assert_template :search
        assert_layout   :daily_deals
      end

    end

    context "with a publisher with their custom template" do

      setup do
        @publisher = Factory(:publisher, :label => "bespoke")
      end

      should "render the publisher template" do
        get :search, :id => @publisher.label
        assert_response :success
        assert assigns(:publisher)
        assert_template "bespoke/publishers/search"
        assert_layout   :daily_deals
      end

    end

  end

  context "categories" do
    
    context "with default publisher template" do

      setup do
        @publisher = Factory(:publisher, :label => "pglabel" )
      end

      should "render the appropriate default template" do
        get :categories, :id => @publisher.label
        assert_response :success
        assert assigns(:publisher)
        assert_template :categories
        assert_layout   :daily_deals
      end

    end

    context "with a publisher with their custom template" do

      setup do
        @publisher = Factory(:publisher, :label => "bespoke")
      end

      should "render the publisher template" do
        get :categories, :id => @publisher.label
        assert_response :success
        assert assigns(:publisher)
        assert_template "bespoke/publishers/categories"
        assert_layout   :daily_deals
      end

    end

  end  

  context "location" do
    
    context "with default publisher template" do

      setup do
        @publisher = Factory(:publisher, :label => "pglabel" )
      end

      should "render the appropriate default template" do
        get :location, :id => @publisher.label
        assert_response :success
        assert assigns(:publisher)
        assert_template :location
        assert_layout   :daily_deals
      end

    end

    context "with a publisher with their custom template" do

      setup do
        @publisher = Factory(:publisher, :label => "bespoke")
      end

      should "render the publisher template" do
        get :location, :id => @publisher.label
        assert_response :success
        assert assigns(:publisher)
        assert_template "bespoke/publishers/location"
        assert_layout   :daily_deals
      end

    end

  end

  context "for_you" do
    
    context "with default publisher template" do

      setup do
        @publisher = Factory(:publisher, :label => "pglabel" )
      end

      should "render the appropriate default template" do
        get :for_you, :id => @publisher.label
        assert_response :success
        assert assigns(:publisher)
        assert_template :for_you
        assert_layout   :daily_deals
      end

    end

    context "with a publisher with their custom template" do

      setup do
        @publisher = Factory(:publisher, :label => "bespoke")
      end

      should "render the publisher template" do
        get :for_you, :id => @publisher.label
        assert_response :success
        assert assigns(:publisher)
        assert_template "bespoke/publishers/for_you"
        assert_layout   :daily_deals
      end

    end

  end

end
