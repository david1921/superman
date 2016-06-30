require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::ToPreviewPDFTest < ActiveSupport::TestCase

  context "to_preview_pdf" do

    setup do
      @daily_deal = Factory(:daily_deal, :value_proposition => "This is daily deal value proposition")
      @daily_deal.advertiser.update_attribute(:name, "Advertiser 1")
      @expected_purchase_count = @daily_deal.daily_deal_purchases.size
      @expected_certificate_count = @daily_deal.daily_deal_purchases.collect(&:daily_deal_certificates).flatten.compact.size
    end

    context "with a default voucher theme" do

      should "call  render_all_vouchers_in_one_pdf_with_standard_lay_out on daily deal purchase" do
        DailyDealPurchase.any_instance.expects(:render_all_vouchers_in_one_pdf_with_standard_lay_out)
        @daily_deal.to_preview_pdf
      end

      should "render a fake daily deal certificate, without generating new daily deal purchases or certs" do
        pdf_text = extract_text_from_pdf(@daily_deal.to_preview_pdf)
        assert_match @daily_deal.line_item_name, pdf_text
        assert_match @daily_deal.advertiser.name, pdf_text
        assert_match @daily_deal.advertiser.store.address_line_1, pdf_text
        assert_match /Jill Smith/, pdf_text
        @daily_deal.reload
        assert_equal @expected_purchase_count, @daily_deal.daily_deal_purchases.size
        assert_equal @expected_certificate_count, @daily_deal.daily_deal_purchases.collect(&:daily_deal_certificates).flatten.compact.size
      end

    end

    context "with time warner publisher which has a custom voucher template" do

      setup do
        publishing_group = Factory(:publishing_group, :label => "rr")
        @daily_deal.publisher.update_attributes(:publishing_group => publishing_group, :label => 'clickedin-austin')
        @daily_deal.update_attributes(:voucher_headline => "this is the headline")
      end

      should "call render_all_vouchers_in_one_pdf_with_custom_lay_out on daily deal purchase" do
        DailyDealPurchase.any_instance.expects(:render_all_vouchers_in_one_pdf_with_custom_lay_out)
        @daily_deal.to_preview_pdf
      end

      should "render a fake daily deal certificate, without generation new daily deal purchases or certs" do
        pdf_text = extract_text_from_pdf(@daily_deal.to_preview_pdf, false)
        assert_match @daily_deal.voucher_headline, pdf_text
        assert_match @daily_deal.advertiser.name, pdf_text
        assert_match @daily_deal.advertiser.store.address_line_1, pdf_text
        assert_match /Jill Smith/, pdf_text
        @daily_deal.reload
        assert_equal @expected_purchase_count, @daily_deal.daily_deal_purchases.size
        assert_equal @expected_certificate_count, @daily_deal.daily_deal_purchases.collect(&:daily_deal_certificates).flatten.compact.size
      end
    end

  end
end
