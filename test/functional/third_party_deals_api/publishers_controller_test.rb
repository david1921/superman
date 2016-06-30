require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ThirdPartyDealsApi::PublishersControllerTest

module ThirdPartyDealsApi
  
  class PublishersControllerTest < ActionController::TestCase
    
    tests ::PublishersController
    
    context "editing third party deals configs on the publisher edit screen" do
      
      setup do
        @admin = Factory :admin
        @controller.stubs(:current_user).returns(@admin)
        @publisher = Factory :publisher, :name => "Some Publisher", :label => "some-publisher"
      end
      
      should "NOT create a third party deals api config record when api config values are empty" do
        assert @publisher.third_party_deals_api_config.blank?
        assert_no_difference "ThirdPartyDealsApi::Config.count" do
          post :update, :id => @publisher.to_param, :publisher => { :label => "some-publisher-changed" }
        end
        assert_response :redirect
        assert_redirected_to edit_publisher_url(@publisher)
        assert_equal "Updated Some Publisher", flash[:notice]
        
        @publisher.reload
        assert_equal "some-publisher-changed", @publisher.reload.label
        assert @publisher.third_party_deals_api_config.blank?
      end
      
      should "display error messages when the third party api config is specified, but invalid" do
        assert @publisher.third_party_deals_api_config.blank?
        assert_no_difference "ThirdPartyDealsApi::Config.count" do
          post :update, :id => @publisher.to_param,
                        :publisher => { 
                          :third_party_deals_api_config_attributes => {
                            :api_username => "foobar",
                            :api_password => "test", 
                            :voucher_serial_numbers_url => "http://example.com"
                        } }
        end
        assert_response :success
        assert_template "publishers/edit"
        
        @publisher.reload
        assert @publisher.third_party_deals_api_config.blank?
        assert_match /voucher serial numbers url must be https/i, @response.body
      end
      
      should "create a third party deals api config record when api config values are specified" do
        assert @publisher.third_party_deals_api_config.blank?
        assert_difference "ThirdPartyDealsApi::Config.count", 1 do
          post :update, :id => @publisher.to_param,
                        :publisher => { 
                          :third_party_deals_api_config_attributes => {
                            :api_username => "foobar",
                            :api_password => "test", 
                            :voucher_serial_numbers_url => "https://example.com"
                        } }
        end
        assert_response :redirect
        assert_redirected_to edit_publisher_url(@publisher)
        assert_equal "Updated Some Publisher", flash[:notice]
        assert @publisher.reload.third_party_deals_api_config.present?
      end
      
    end
    
  end
  
end