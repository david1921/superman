require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Advertisers::TranslationsTest
module Advertisers
  class TranslationsTest < ActionController::IntegrationTest
    test "edit advertiser with spanish locale" do
      post session_path, :user => { :login => "quentin", :password => "monkey" }

      I18n.locale = :en
      advertiser = Factory(:advertiser)

      I18n.locale = :es
      advertiser.update_attributes!(:name => "spanish name",
                                    :tagline => "spanish tagline",
                                    :website_url => "http://es.foo.com")

      get "/advertisers/#{advertiser.id}/translations/es/edit"

      assert_response :success
      assert assigns(:advertiser)

      assert_select "form.edit_advertiser" do
        assert_select "input[name='advertiser[name]'][value='spanish name']"
        assert_select "input[name='advertiser[tagline]'][value='spanish tagline']"
        assert_select "input[name='advertiser[website_url]'][value='http://es.foo.com']"
      end
    end

    test "update advertiser with spanish locale" do
      post session_path, :user => { :login => "quentin", :password => "monkey" }

      I18n.locale = :en
      advertiser = Factory(:advertiser)

      put "/advertisers/#{advertiser.id}/translations/es", :advertiser => {
        :name => "new spanish name",
        :tagline => "new spanish tagline",
        :website_url => "http://es.new.com",
      }

      assert_redirected_to "/advertisers/#{advertiser.id}/translations/es/edit"
      
      I18n.locale = :es
      advertiser = advertiser.reload
      assert_equal "new spanish name", advertiser.name
      assert_equal "new spanish tagline", advertiser.tagline
      assert_equal "http://es.new.com", advertiser.website_url
    end

    test "update advertiser with spanish locale and invalid data" do
      post session_path, :user => { :login => "quentin", :password => "monkey" }

      I18n.locale = :en
      advertiser = Factory(:advertiser)

      put "/advertisers/#{advertiser.id}/translations/es", :advertiser => {
        :name => "new spanish name",
        :tagline => "new spanish tagline",
        :website_url => "http://",
      }

      assert_response :success
      
      assert_select ".errorExplanation ul li",
                    "Website url 'http://' is not a valid HTTP or HTTPS URL",
                    "errors should be in English"
    end
  end
end
