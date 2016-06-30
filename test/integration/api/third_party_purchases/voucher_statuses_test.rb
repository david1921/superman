require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Api::ThirdPartyPurchases::VoucherStatusTest

module Api::ThirdPartyPurchases
  class VoucherStatusTest < ActionController::IntegrationTest
    include Api::ThirdPartyPurchases::VoucherStatuses::Core

    PATH = '/api/third_party_purchases/voucher_statuses'

    should "require basic authentication" do
      get PATH
      assert_response :unauthorized
    end

    context "authorized" do
      setup do
        user = Factory(:user)
        @headers ||= {'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(user.login, 'test'), "Content-type" => "text/xml"}

        @certificates = create_certificates_matching_xml(voucher_status_xml)
      end

      context "HTTP request" do
        setup do
          VoucherStatusesController.stubs(:ssl_rails_environment?).returns(true)
        end

        context "GET" do
          should "return voucher statuses xml" do
            serial_numbers = serial_numbers_from_xml(voucher_status_xml)
            query_string = serial_numbers.inject([]){|a,e| a << "serial_numbers[]=#{e}"}.join('&')
            get PATH + "?#{query_string}", nil, @headers
            assert_response :forbidden
          end
        end

        context "POST" do
          should "update and return voucher statuses xml" do
            update_xml = update_voucher_status_xml
            post PATH, update_xml, @headers
            assert_response :forbidden
          end
        end
      end

      context "HTTPS request" do
        setup do
          https!
        end

        context "GET" do
          should "return voucher statuses xml" do
            serial_numbers = serial_numbers_from_xml(voucher_status_xml)
            query_string = serial_numbers.inject([]){|a,e| a << "serial_numbers[]=#{e}"}.join('&')
            get PATH + "?#{query_string}", nil, @headers
            assert_response :ok
            assert_template 'voucher_statuses/index.xml'
            assert_certificate_statuses
          end
        end

        context "POST" do
          should "update and return voucher statuses xml" do
            update_xml = update_voucher_status_xml
            post PATH, update_xml, @headers
            assert_response :ok
            assert_template 'voucher_statuses/index.xml'
            assert_certificate_statuses_updated(update_xml)
          end
        end
      end
    end


    private

    def voucher_status_xml
      File.read(Rails.root + "test/data/api/third_party_purchases/voucher_statuses.xml")
    end

    def update_voucher_status_xml
      voucher_status_xml.tap do |xml|
        xml.sub!('active', 'redeemed')
        xml.sub!('active', 'refunded')
        xml.sub!('active', 'voided')
      end
    end

    def create_certificates_matching_xml(xml)
      [].tap do |certs|
        doc = Nokogiri::XML(xml)
        doc.search('voucher_status').each do |vs|
          serial_number = vs.attr('serial_number')
          status = vs.content
          refunded_at = status == 'refunded' ? Time.zone.now : nil
          cert = Factory(:daily_deal_certificate, :serial_number => serial_number, :status => status, :refunded_at => refunded_at)
          assert_equal serial_number, cert.serial_number
          assert_equal status, cert.status
          certs << cert
        end
      end
    end

    def serial_numbers_from_xml(xml)
      voucher_statuses_from_xml(xml).keys
    end

    def assert_certificate_statuses
      doc = Nokogiri::XML(response.body)
      @certificates.each do |cert|
        assert_equal cert.status, doc.search('voucher_status').select{|vs| vs.attr('serial_number') == cert.serial_number}.first.content
      end
    end

    def assert_certificate_statuses_updated(xml)
      doc_in = Nokogiri::XML(xml)
      doc_out = Nokogiri::XML(response.body)
      doc_in.search('voucher_status').each do |vs|
        assert_equal vs.content, doc_out.search('voucher_status').select{|x| x.attr('serial_number') == vs.attr('serial_number')}.first.content
      end
    end
  end
end
