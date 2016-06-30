require File.dirname(__FILE__) + "/../../../test_helper"
require 'nokogiri'

# hydra class Api::ThirdPartyPurchases::SerialNumberResponseTest

module Api::ThirdPartyPurchases
  class SerialNumberResponseTest < ActiveSupport::TestCase

    context "#to_xml" do
      context "success response" do
        setup do
          @voucher = stub('daily deal certificate', :serial_number => '12345', :bar_code => '6789012345', :bar_code_symbology => '128B',
                          :sequence => '1')
          @request = stub('serial number request', :success? => true, :vouchers => [@voucher], :deal_qty_remaining => 10,
                          :deal_sold_out? => false)
        end

        should "have a 'voucher_responses' root" do
          xml_doc
          assert_equal 'voucher_responses', @doc.root.name
        end

        should "have a voucher_response element" do
          xml_doc
          assert_equal 1, @doc.root.search('voucher_response').size
        end


        should "have the voucher serial number" do
          xml_doc
          assert_equal @voucher.serial_number, @doc.root.search('voucher_response serial_number').first.text
        end

        should "have the voucher barcode number" do
          xml_doc
          assert_equal @voucher.bar_code, @doc.search('voucher_response bar_code value').first.text
        end

        should "have voucher_response elements with a barcode format" do
          xml_doc
          assert_equal @voucher.bar_code_symbology, @doc.search('voucher_response bar_code format').first.text
        end

        should "have the voucher_response sequence" do
          xml_doc
          assert_equal @voucher.sequence, @doc.search('voucher_response').first.attr('sequence')
        end

        should "have the deal quantity remaining" do
          xml_doc
          assert_equal @request.deal_qty_remaining.to_s, @doc.search('voucher_responses qty_remaining').first.text
        end
      end

      context "error response" do
        setup do
          @request = mock('serial number request')
          @request.stubs(:valid?).returns(false)
          @request.stubs(:success?).returns(false)
          @request.stubs(:deal_sold_out?).returns(false)
          @request.stubs(:errors).returns({})
        end

        should "have an 'errors' root" do
          xml_doc
          assert_equal 'errors', @doc.root.name
        end

        context "invalid request" do
          should "have error 3 with text 'invalid request'" do
            xml_doc
            assert_contains @doc.root.search('error').collect { |node| [node.search('code').text, node.search('text').text] }, ['3', 'invalid request']
          end
        end

        context "sold out deal" do
          setup do
            @request.stubs(:deal_sold_out? => true)
            xml_doc
          end

          should "have error 2 with text 'sold out'" do
            assert_contains @doc.root.search('error').collect { |node| node.search('code').text }, '2'
          end
        end
      end
    end


    private

    def xml_doc
      xml = SerialNumberResponse.new(:request => @request).to_xml
      @doc = Nokogiri::XML(xml)
    end
  end
end
