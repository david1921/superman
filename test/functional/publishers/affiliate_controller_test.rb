require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::AffiliateControllerTest < ActionController::TestCase
  
  context "FAQs" do
    context "with a publisher that uses the default page" do
      setup do
        @publisher = Factory(:publisher)
        get :faqs, :publisher_id => @publisher.label
      end
      
      should render_template("publishers/affiliate/faqs")
      should render_with_layout("affiliate")
      should assign_to(:publisher).with(@publisher)
    end
    
    context "with a publisher that uses the themed page" do
      setup do
        @publisher = Factory(:publisher, :label => "kowabunga")
        get :faqs, :publisher_id => @publisher.label
      end
      
      should "render the kowabunga publishers/affiliate/faqs template" do
        assert_template "themes/kowabunga/publishers/affiliate/faqs"
      end
      
      should "render the kowabunga layouts/publishers/affiliate" do
        assert_theme_layout "kowabunga/layouts/publishers/affiliate"
      end
    end
  end
  
  context "show" do
    context "with a publisher that uses the default page" do
      setup do
        @publisher = Factory(:publisher)
        get :show, :publisher_id => @publisher.label
      end

      should render_template("publishers/affiliate/show")
      should render_with_layout("affiliate")
      should assign_to(:publisher).with(@publisher)
    end

    context "with a publisher that uses the themed page" do
      setup do
        @publisher = Factory(:publisher, :label => "kowabunga")
        get :show, :publisher_id => @publisher.label
      end

      should "render the kowabunga publishers/affiliate/faqs template" do
        assert_template "themes/kowabunga/publishers/affiliate/show"
      end

      should "render the kowabunga layouts/publishers/affiliate" do
        assert_theme_layout "kowabunga/layouts/publishers/affiliate"
      end
    end
  end


end
