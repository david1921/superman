require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Api::ThirdPartyPurchases::SerialNumberRequestIntegrationTest

module Api::ThirdPartyPurchases
  class SerialNumberRequestIntegrationTest < ActionController::IntegrationTest

    should "require basic authentication" do
      post api_third_party_purchases_serial_numbers_url
      assert_response :unauthorized
    end

    context "authorized" do
      setup do
        @publisher = Factory(:publisher)
        @user = Factory(:user, :company => @publisher.publishing_group)
        @headers ||= {'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, 'test')}
      end

      context "valid request" do
        setup do
          @valid_xml = File.read(Rails.root + "test/data/api/third_party_purchases/serial_number_request.xml")
          @daily_deal = Factory(:daily_deal, :publisher => @publisher, :listing => Hash.from_xml(@valid_xml)['daily_deal_purchase']['daily_deal_listing'], :quantity => 2)
          create_bar_codes!(@daily_deal)
          Factory(:store, :listing => Hash.from_xml(@valid_xml)['daily_deal_purchase']['location_listing'], :advertiser => @daily_deal.advertiser)
        end

        context "HTTP request" do
          setup do
            SerialNumbersController.stubs(:ssl_rails_environment?).returns(true)
          end

          should "respond with forbidden response" do
            post api_third_party_purchases_serial_numbers_url, @valid_xml, @headers
            assert_response :forbidden
          end
        end

        context "HTTPS request" do
          setup do
            https!
          end

          should "respond with successful response" do
            post api_third_party_purchases_serial_numbers_url, @valid_xml, @headers
            assert_response :ok
            doc = Nokogiri::XML(@response.body)
            assert_voucher_responses_root(doc)
            assert_qty_remaining(doc)
            assert_bar_code_values(doc)
            assert_bar_code_formats(doc)
          end

          should "create a new OffPlatformDailyDealPurchase when valid" do
            assert_difference 'OffPlatformDailyDealPurchase.count' do
              post api_third_party_purchases_serial_numbers_url, @valid_xml, @headers
            end
          end

          should "not enforce forgery protection" do
            with_forgery_protection do
              post api_third_party_purchases_serial_numbers_url, @valid_xml, @headers
            end
            assert_response :ok
          end

          context "insufficient deal qty" do
            setup do
              BarCode.last.destroy
              @daily_deal.quantity = 1
              @daily_deal.save!
            end

            should "return sold-out error response" do
              post api_third_party_purchases_serial_numbers_url, @valid_xml, @headers
              doc = Nokogiri::XML(@response.body)
              assert_error_response(doc)
              assert_sold_out_error(doc)
            end
          end
        end
      end

      context "invalid request" do
        setup do
          https!
          valid_xml = File.read(Rails.root + "test/data/api/third_party_purchases/serial_number_request.xml")
          doc = Nokogiri::XML(valid_xml)
          doc.search('daily_deal_listing').remove
          @invalid_xml = doc.to_xml
        end

        should "not create a new OffPlatformDailyDealPurchase" do
          assert_no_difference 'OffPlatformDailyDealPurchase.count' do
            post api_third_party_purchases_serial_numbers_url, @invalid_xml, @headers
          end
        end

        should "respond with an error response" do
          post api_third_party_purchases_serial_numbers_url, @invalid_xml, @headers
          assert_response :ok
          assert_error_response(Nokogiri::XML(@response.body))
        end
      end
    end


    private

    def create_bar_codes!(deal)
      Nokogiri::XML(@valid_xml).search('voucher_request').size.times do |i|
        Factory(:bar_code, :bar_codeable => deal)
      end
    end

    def assert_voucher_responses_root(doc)
      assert_equal 'voucher_responses', doc.root.name, @response.body
    end

    def assert_qty_remaining(doc)
      assert_equal "0", doc.root.search('qty_remaining').text, @response.body
    end

    def assert_bar_code_values(doc)
      assert_equal 2, doc.root.search('voucher_response bar_code value').select { |node| node.text.present? }.size, @response.body
    end

    def assert_bar_code_formats(doc)
      assert_equal 2, doc.root.search('voucher_response bar_code format').select { |node| node.text == '128B' }.size, @response.body
    end

    def assert_error_response(doc)
      assert_equal 'errors', doc.root.name, @response.body
    end

    def assert_sold_out_error(doc)
      assert_equal "2", doc.root.search('error code').first.text, @response.body
    end

    def with_forgery_protection
      begin
        SerialNumbersController.allow_forgery_protection = true
        yield
      ensure
        SerialNumbersController.allow_forgery_protection = false
      end
    end
  end
end
