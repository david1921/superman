require File.dirname(__FILE__) + "/../test_helper"

class LandingPagesTest < ActionController::IntegrationTest
  assert_no_angle_brackets :except => :test_Should_show_publishing_group_landing_page

  context "https only host" do
    context "redirect by membership code" do
      setup do
        @host = "example.com"
        Factory(:https_only_host, :host => @host)
        @publishing_group = Factory(:publishing_group, :label => "bcbsa")
        @publisher = Factory(:publisher, :publishing_group => @publishing_group, :label => "bcbsma")
        Factory(:publisher_membership_code, :code => "ABC", :publisher => @publisher)
      end

      should "store secure cookies" do
        https!
        get publishing_group_landing_page_path(@publishing_group.label, :membership_code => "ABC", :zip_code => "98685"), nil, :host => @host, :protocol => "https"

        cookie_array = headers['Set-Cookie']
        assert_secure_cookie cookie_array, "publisher_membership_code"
        assert_secure_cookie cookie_array, "publisher_label"
        assert_secure_cookie cookie_array, "zip_code"

      end
    end
  end

  context "non https only host" do
    context "redirect by membership code" do
      setup do
        @publishing_group = Factory(:publishing_group, :label => "bcbsa")
        @publisher = Factory(:publisher, :publishing_group => @publishing_group, :label => "bcbsma")
        Factory(:publisher_membership_code, :code => "ABC", :publisher => @publisher)
      end

      should "not store secure cookies" do
        https!
        get publishing_group_landing_page_path(@publishing_group.label, :membership_code => "ABC", :zip_code => "98685"), nil, :protocol => "https"
        assert headers["Set-Cookie"].nil?, "Should not set any cookies"
      end
    end
  end

  def assert_secure_cookie(cookie_array, cookie_name)
    cookie = cookie_array.detect { |c| c =~ /^#{cookie_name}/ }
    fail "no cookie matching #{cookie_name}" unless cookie.present?
    assert_match /^#{cookie_name}.*; secure/, cookie
  end

end
