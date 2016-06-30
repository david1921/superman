require File.dirname(__FILE__) + "/../../test_helper"

class TimeWarnerCable::LogoTest < ActionController::TestCase
  class StubController < ActionController::Base
    include TimeWarnerCable::Logo
    
    def index
      render :text => "show twc logo: #{show_twc_logo? ? 'YES' : 'NO'}"
    end
  end

  tests TimeWarnerCable::LogoTest::StubController

  context "with the show_twc_logo cookie set to true in the request" do
    setup do
      @request.cookies["show_twc_logo"] = "true"
    end
    
    context "and referred by an external time-warner-cable domain" do
      setup do
        @request.env['HTTP_REFERER'] = "http://www.timewarnercable.com"
      end
      
      should "show the logo but not set the show_twc_logo cookie in the response" do
        get :index

        assert_match /show twc logo: YES/, @response.body
        assert(!@response.cookies.has_key?("show_twc_logo"))
      end
    end

    context "and referred by an internal time-warner-cable domain" do
      setup do
        @request.env['HTTP_REFERER'] = "http://deals.clickedin.com"
      end
      
      should "show the logo but not set the show_twc_logo cookie in the response" do
        get :index

        assert_match /show twc logo: YES/, @response.body
        assert(!@response.cookies.has_key?("show_twc_logo"))
      end
    end

    context "and referred by a non-time-warner-cable domain" do
      setup do
        @request.env['HTTP_REFERER'] = "http://www.google.com"
      end
      
      should "not show the logo and delete the show_twc_logo cookie in the response" do
        get :index

        assert_match /show twc logo: NO/, @response.body
        assert(@response.cookies.has_key?("show_twc_logo"))
        assert_nil @response.cookies["show_twc_logo"]
      end
    end
  end

  context "with the show_twc_logo cookie not set in the request" do
    context "and referred by an external time-warner-cable domain" do
      setup do
        @request.env['HTTP_REFERER'] = "http://www.timewarnercable.com"
      end
      
      should "show the logo and set the show_twc_logo cookie to true in the response" do
        get :index

        assert_match /show twc logo: YES/, @response.body
        assert_equal "true", @response.cookies["show_twc_logo"]
      end
    end

    context "and referred by an internal time-warner-cable domain" do
      setup do
        @request.env['HTTP_REFERER'] = "http://deals.clickedin.com"
      end
      
      should "not show the logo and not set the show_twc_logo cookie in the response" do
        get :index

        assert_match /show twc logo: NO/, @response.body
        assert(!@response.cookies.has_key?("show_twc_logo"))
      end
    end

    context "and referred by a non-time-warner-cable domain" do
      setup do
        @request.env['HTTP_REFERER'] = "http://www.google.com"
      end
      
      should "not show the logo and not set the show_twc_logo cookie in the response" do
        get :index

        assert_match /show twc logo: NO/, @response.body
        assert(!@response.cookies.has_key?("show_twc_logo"))
      end
    end
  end
end
