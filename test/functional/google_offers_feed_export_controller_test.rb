require File.dirname(__FILE__) + "/../test_helper"

class GoogleOffersFeedExportControllerTest < ActionController::TestCase
  
  tests PublishersController
  
  context "GET to :google_offers_feed, format xml" do
    
    setup do
      @ocregister = Factory :publisher, :label => "ocregister"
      @otherpub = Factory :publisher, :label => "not-ocregister"
      @advertiser = Factory :advertiser, :publisher => @ocregister, :description => "test description"
      @deal = Factory :daily_deal, :advertiser => @advertiser, :start_at => 1.minute.ago, :hide_at => 1.day.from_now
    end
    
    context "with a publisher whose #enable_google_offers_feed? returns true" do
    
      setup do
        assert @ocregister.enable_google_offers_feed?
      end
    
      should "return a 401 Unauthorized when no basic auth specified" do
        get :google_offers_feed, :id => @ocregister.to_param, :format => "xml"
        assert_response :unauthorized
      end
      
      should "return the google offers xml feed when valid auth credentials are provided" do
        login_with_basic_auth :login => "googleoffers", :password => "nwyxTYwC"
        get :google_offers_feed, :id => @ocregister.to_param, :format => "xml"
        assert_response :success
        
        xml_doc = Nokogiri::XML(@response.body)
        assert_equal "feed", xml_doc.root.name
        assert_equal 1, xml_doc.css("entry").size
      end
      
    end
    
    context "with a publisher whose #enable_google_offers_feed? returns false" do
      
      setup do
        assert !@otherpub.enable_google_offers_feed?
      end
      
      should "return a 401 Unauthorized with invalid auth credentials" do
        login_with_basic_auth(:login => "wrong", :password => "wronger")
        get :google_offers_feed, :id => @otherpub.to_param, :format => "xml"
        assert_response :unauthorized
      end
      
      should "return a 404 Not Found with valid auth credentials" do
        login_with_basic_auth(:login => "googleoffers", :password => "nwyxTYwC")
        get :google_offers_feed, :id => @otherpub.to_param, :format => "xml"
        assert_response :not_found
      end
      
    end
    
  end
  
  
end