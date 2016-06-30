require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::ApiTest < ActionController::TestCase
  tests PublishersController

  context "coupons" do
    setup do
      login_as Factory(:admin)
      get :coupons, :format => "xml"
    end
  
    should "render the rr publishers/coupons XML" do
      assert_response :success
      xml = Nokogiri.parse(@response.body, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS)
      assert_equal 3, xml.css("publishers publisher").size, "publishers"
      assert xml.css("publishers publisher label").any? { |node| node.content == "myspace" }, "should export publishers with coupons"
      assert xml.css("publishers publisher label").none? { |node| node.content == "entercom" }, "should only export publishers with coupons"
    end
  end

  context "daily_deals" do
    setup do
      daily_deal = Factory(:daily_deal, :publisher => Factory(:publisher, :label => "blind-squirrel"))
      login_as Factory(:admin)
      get :daily_deals, :format => "xml"
    end

    should "render the rr publishers/daily_deals XML" do
      assert_response :success
      xml = Nokogiri.parse(@response.body, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS)
      assert_equal 1, xml.css("publishers publisher").size, "publishers"
      assert xml.css("publishers publisher label").none? { |node| node.content == "sdh_austin" }, "should only export publishers with deals"
      assert xml.css("publishers publisher label").any? { |node| node.content == "blind-squirrel" }, "should export publishers with deals"
    end
  end
end
