require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::AgreementsControllerTest
module Syndication
  class AgreementsControllerTest < ActionController::TestCase
    def test_new
      set_http_basic_authentication :name => "contract", :pass => "analog"
      get :new
      assert_response :success
    end
    
    def test_create
      set_http_basic_authentication :name => "contract", :pass => "analog"
      assert_difference "Agreement.count" do
        post :create, :syndication_agreement => {
          :contact_name => "Viper",
          :title => "Instructor",
          :company_name => "Fighter School",
          :telephone_number => "(503) 911-4111",
          :email => "viper@example.com",
          :business_terms => "1",
          :syndication_terms => "1"
        }
      end

      agreement = assigns(:agreement)
      assert !agreement.new_record?, "Should save agreement"
      assert_redirected_to syndication_agreement_path(agreement)
    end
    
    def test_show
      set_http_basic_authentication :name => "contract", :pass => "analog"
      get :show, :id => Factory(:agreement).to_param
      assert_response :success
    end

    def test_new_with_no_authentication
      get :new
      assert_response :unauthorized
    end

    def test_create_with_no_authentication
      post :create
      assert_response :unauthorized
    end

    def test_show_with_no_authentication
      get :show, :id => Factory(:agreement).to_param
      assert_response :unauthorized
    end
  end
end