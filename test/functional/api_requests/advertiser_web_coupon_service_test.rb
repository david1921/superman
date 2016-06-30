#  This test needs to be rewritten to NOT use sdcitybeat...

require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ApiRequests::AdvertiserWebCouponServiceTest

module ApiRequests
  class AdvertiserWebCouponServiceTest < ActionController::TestCase
    include ApiRequestsTestHelper

    tests ApiRequestsController

    def test_advertiser_web_coupons_service_with_invalid_client_id_and_location_id_pair
      @api_version = @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      publisher       = Factory(:publisher)
      vvm_client_id   = "12312312"
      vvm_location_id = "34344343"
      advertiser      = publisher.advertisers.create!(:listing => "#{vvm_client_id}-#{vvm_location_id}")
      offer_1         = advertiser.offers.create!(:message => "TACOS! TACOS!")
      offer_2         = advertiser.offers.create!(:message => "DONUTS! DONUTS!")

      assert_raise ActiveRecord::RecordNotFound do
        get :advertiser_web_coupons_service, {
          :format => :xml,
          :client_id => vvm_client_id,
          :location_id => "blala"
        }
      end
    end

    def test_advertiser_web_coupons_service_with_valid_client_id_and_location_id_pair
      @api_version = @request.env['API-Version'] = "1.2.0"
      set_http_basic_authentication(:name => users(:robert).login, :pass => "monkey")

      publisher       = Factory(:publisher, :theme => "standard")
      publisher.update_attributes(:production_host => "coupons.houstonpress.com", :show_facebook_button => true, :show_twitter_button => true)
      vvm_client_id   = "12312312"
      vvm_location_id = "34344343"
      advertiser      = publisher.advertisers.create!(:name => "Houston Sushi", :listing => "#{vvm_client_id}-#{vvm_location_id}")
      advertiser.stores.create!(:phone_number => "111-111-1111", :address_line_1 => "123 Main St", :city => "Houston", :state => "TX", :zip => "66009")

      offer_1         = advertiser.offers.create!(:message => "TACOS! TACOS!", :txt_message => "TACOS!")
      offer_2         = advertiser.offers.create!(:message => "DONUTS! DONUTS!", :txt_message => "DONUTS!")

      advertiser.coupon_clipping_modes << :email
      advertiser.coupon_clipping_modes << :txt
      advertiser.logo_file_name     = "my-logo.jpg"
      advertiser.logo_content_type  = "image/jpeg"
      advertiser.logo_width         = "146"
      advertiser.logo_height        = "77"
      advertiser.save

      assert advertiser.logo.present?, "should have logo"

      get :advertiser_web_coupons_service, {
        :format => :xml,
        :client_id => vvm_client_id,
        :location_id => vvm_location_id
      }

      assert_response :success
      assert_not_nil  assigns(:advertiser)
      assert_not_nil  assigns(:publisher), "should assign publisher need for the view"
      assert_not_nil  assigns(:categories), "should assign categories"
      assert_equal 2, assigns(:offers).size, "should return both offers"

      root = REXML::Document.new(@response.body).root
      assert_not_nil root, "should have a root element"
      assert_equal "service_response", root.name, "XML response root element name"
      assert_equal "advertiser_web_coupons", root.attributes["type"], "XML response service_response[type]"

      advertiser_element = root.elements['advertiser']
      assert_not_nil advertiser_element, "root should have advertiser element"
      assert_equal advertiser.id, advertiser_element.attributes["id"].to_i

      web_coupons = advertiser_element.elements['web_coupons']
      assert_not_nil web_coupons, "advertiser element should have web_coupons element"

      html_head = web_coupons.elements['html_head']
      assert_not_nil html_head, "web_coupons element should have html_head element"
      assert_equal 1, html_head.cdatas.size, "should be 1 CDATA element"

      head = REXML::Document.new("<head>#{html_head.cdatas.first.to_s}</head>").root
      ["javascripts/prototype.js", "javascripts/effects.js", "javascripts/dragdrop.js", "javascripts/controls.js", "javascripts/business.js", "javascripts/xd_business.js" ].each_with_index do |resource, index|
        assert_equal "http://coupons.houstonpress.com/#{resource}", head.elements[index+1].attributes['src']
      end
      assert_equal "http://coupons.houstonpress.com/stylesheets/#{publisher.label}/businesses.css", head.elements[ head.elements.size - 1 ].attributes['href']

      html_body = web_coupons.elements['html_body']
      assert_not_nil html_body, "web_coupons element should have html_body element"
      assert_equal 1, html_body.cdatas.size, "should be 1 CDATA element"

      # want to use HTML::Document, since the CDATA should be valid html, and we can use rails built in assert_select
      body = HTML::Document.new( html_body.cdatas.first.to_s ).root
      assert_select body, "div.analog_analytics_content" do
        assert_select "div.content" do
          assert_select "div.address", :text => "#{advertiser.formatted_phone_number} | #{advertiser.address.join(", ")} | Map"
          assert_select "ul.offers" do
            advertiser.offers.each do |offer|
              assert_select "li" do
                assert_select "div.top" do
                  assert_select "div.info" do
                    assert_select "span.expiration"
                    assert_select "span.share" do
                      # assert_select "a[href='http://test.host/offers/#{offer.id}/facebook?publisher_id=#{publisher.id}']" do
                      #   assert_select "img[src^='http://test.host/images/coupons/facebook.png']"
                      # end
                      # assert_select "a[href='http://test.host/offers/#{offer.id}/twitter?publisher_id=#{publisher.id}']" do
                      #   assert_select "img[src^='http://test.host/images/coupons/twitter.png']"
                      # end
                      # assert_select "a[id='print_#{offer.id}']" do
                      #   assert_select "img[src^='http://test.host/images/coupons/print.png']"
                      # end
                      # assert_select "a[class='email']" do
                      #   assert_select "img[src^='http://test.host/images/coupons/email.png']"
                      # end
                      # assert_select "a[class='txt']" do
                      #   assert_select "img[src^='http://test.host/images/coupons/phone.png']"
                      # end
                    end
                  end
                end
              end
            end
          end
        end
        assert_select "div.logo"
      end

    end

    private

    def set_http_basic_authentication(options)
      @request.env['HTTP_AUTHORIZATION'] = 'Basic ' + Base64::encode64("#{options[:name]}:#{options[:pass]}")
    end

  end
end