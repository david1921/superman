require File.dirname(__FILE__) + "/../test_helper"

class CachingController < ApplicationController
  def index
    expires_in 10.minutes, :public => true
    session[:foo] = "bar"
    render :text => "<html></html>"
  end
end

class CachingControllerTest < ActionController::TestCase
  test "raise security exception if session accessed and page set to cache" do
    assert_raise SecurityError do
      get :index
    end
  end
end
