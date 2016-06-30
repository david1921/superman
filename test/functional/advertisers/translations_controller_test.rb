require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Advertisers::TranslationsControllerTest
class Advertisers::TranslationsControllerTest < ActionController::TestCase
  fast_context "edit" do
    setup do
      @advertiser = Factory(:advertiser)
      login_as Factory(:admin)
      get :edit, :advertiser_id => @advertiser.to_param
    end

    should render_template(:edit)
    should assign_to(:advertiser)
  end
end
