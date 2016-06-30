require File.dirname(__FILE__) + "/../../test_helper"

class Syndication::AgreementsTest < ActionController::IntegrationTest
  context "authorized request" do
    setup do
      @headers ||= {'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials('contract', 'analog')}
    end

    should "load the 'new' page" do
      get new_syndication_agreement_path, nil, @headers
      assert_response :success
      assert_select "title", /Syndication Agreement/
      assert_select "form[action=#{syndication_agreements_path}][method=post]" do
        [:company_name, :contact_name, :title, :telephone_number, :email].each do |field|
          assert "input[type=text][name=agreement[#{field.to_s}]]"
        end
        [:source_publisher, :distribution_publisher, :affiliate_publisher].each do |field|
          assert "input[type=checkbox][name=agreement[#{field.to_s}]]"
        end
        [:websites, :mobile_applications, :other_delivery_mechanisms].each do |field|
          assert "input[type=text][name=agreement[#{field.to_s}]]"
        end
        [:business_terms, :syndication_terms].each do |field|
          assert "input[type=checkbox][name=agreement[#{field.to_s}]]"
        end
        assert "input[type=submit][value=Accept]"
      end
    end

    should "create a new agreement" do
      post syndication_agreements_path, { :syndication_agreement => {
        :contact_name => "Viper",
        :title => "Instructor",
        :company_name => "Fighter School",
        :telephone_number => "(503) 911-4111",
        :email => "viper@example.com",
        :business_terms => "1",
        :syndication_terms => "1"
      } }, @headers
      assert_redirected_to syndication_agreement_path(Syndication::Agreement.last)
    end

    should "show an existing agreement" do
      agreement = Factory(:agreement)
      get syndication_agreement_path(agreement), nil, @headers
      assert_response :success
      assert_select "title", /Syndication Agreement/
      assert_select "h2", "Agreement Number: #{agreement.serial_number}"
    end
  end
end
