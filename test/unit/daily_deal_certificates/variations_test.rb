require File.dirname(__FILE__) + "/../../test_helper"


class DailyDealCertificates::VariationsTest < ActiveSupport::TestCase
  
	context "daily deal certificates for variations" do

		setup do
			@daily_deal = Factory(:daily_deal, 
				:value_proposition => "Deal Value Prop", 
				:voucher_headline => "Deal Voucher Headline",
				:value => 100.00,
				:price => 50.00,
				:terms => "Deal Terms",
				:bar_code_encoding_format => 7
			)
			@daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)

			@variation = Factory(:daily_deal_variation, 
				:daily_deal => @daily_deal,
				:value_proposition => "Variation Value Prop",
				:voucher_headline => "Variation Voucher Headline",
				:value => 75.00,
				:price => 30.00,
				:terms => "Voucher Terms",
				:bar_code_encoding_format => 6)

			@purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :daily_deal_variation => @variation)			
		end

		should "have a variation on the purchase" do
			assert_equal @variation, @purchase.daily_deal_variation
		end

		should "have one certificate on the purchase" do
			assert 1, @purchase.daily_deal_certificates.size
		end

		should "have the certificate use the daily deal variations fields for proposition, headline, value, price and terms" do
			certificate = @purchase.daily_deal_certificates.first
			assert_equal @variation.value_proposition, certificate.value_proposition, "should use variation value prop"
			assert_equal @variation.voucher_headline, certificate.voucher_headline, "should use variation voucher headline"
			assert_equal @variation.value, certificate.value, "should use variation value"
			assert_equal @variation.price, certificate.price, "should use variation price"
			assert_equal @variation.terms, certificate.terms, "should use variation terms"
			assert_equal @variation.humanize_price, certificate.humanize_price, "should use variation humanize price"
			assert_equal @variation.humanize_value, certificate.humanize_value, "should use variation humanize value"
			assert_equal @variation.terms_plain, certificate.terms_plain, "should use variation terms_plain value"
			assert_equal @variation.bar_code_encoding_format, certificate.bar_code_encoding_format, "should use variation bar_code_encoding_format value"
		end

	end

	context "wcax custom voucher for variations" do

		setup do
			@publishing_group = Factory(:publishing_group, :label => "wcax")
			@publisher        = Factory(:publisher, :label => "wcax-vermont", :publishing_group => @publishing_group, :enable_daily_deal_variations => true)
			@deal             = Factory(:daily_deal, :publisher => @publisher, :voucher_headline => "DEAL HEADLINE", :value_proposition => "DEAL PROPOSITION", :terms => "DEAL TERMS")
			@variation        = Factory(:daily_deal_variation, :daily_deal => @deal, :voucher_headline => "VARIATION HEADLINE", :value_proposition => "VARIATION PROPOSITION", :terms => "VARIATION TERMS")
			@purchase         = Factory(:captured_daily_deal_purchase, :daily_deal => @deal, :daily_deal_variation => @variation)
			@certificate      = @purchase.daily_deal_certificates.first
		end

    should "use the app/views/themes/wcax/daily_deal_purchases/certificate_layout.html.erb for custom_voucher_template_layout_path" do
      assert_equal Rails.root.join("app/views/themes/wcax/daily_deal_purchases/certificate_layout.html.erb"), @certificate.daily_deal_purchase.custom_voucher_template_layout_path
    end

    should "use the app/views/themes/wcax/daily_deal_purchases/_certificate_body.html.erb for custom_voucher_template_path" do
      assert_equal Rails.root.join("app/views/themes/wcax/daily_deal_purchases/_certificate_body.html.erb"), @certificate.daily_deal_purchase.custom_voucher_template_path
    end		

    should "render the variation voucher headline if voucher headline is present" do
      assert_match(%r{<span id="lblTitle">#{@variation.voucher_headline}</span>}, @certificate.custom_lay_out_as_html_snippet)
    end    

    should "render the variation value proposition if voucher headline isn't present" do
    	@certificate.stubs(:voucher_headline).returns( nil )
      assert_match(%r{<span id="lblTitle">#{@variation.value_proposition}</span>}, @certificate.custom_lay_out_as_html_snippet)
    end    

    should "render the variation terms" do
      assert_match(%r{<span id="lblSmallPrint">#{textilize @variation.terms(:plain)}</span>}, @certificate.custom_lay_out_as_html_snippet)
    end 

	end

	context "wcax custom voucher for syndicated variations" do

		setup do
			@source_deal  = Factory(:daily_deal_for_syndication, :value_proposition => "SOURCE DEAL")
			@source_deal.publisher.update_attributes(:enable_daily_deal_variations => true, :label => "source-publisher", :publishing_group => nil)
			@variation    = Factory(:daily_deal_variation, :daily_deal => @source_deal)

			@distributed_publishing_group = Factory(:publishing_group, :label => "wcax")
			@distributed_publisher        = Factory(:publisher, :label => "wcax-vermont", :publishing_group => @publishing_group, :enable_daily_deal_variations => true)
			@distributed_deal							= syndicate( @source_deal, @distributed_publisher )

			@distributed_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @distributed_deal, :daily_deal_variation => @variation)			
			@certificate  = @distributed_purchase.daily_deal_certificates.first
		end

		#
		# NOTE: the source publisher template should be used for syndicated deals.
		#

    should "use the app/views/themes/source-publisher/daily_deal_purchases/certificate_layout.html.erb for custom_voucher_template_layout_path" do
      assert_equal Rails.root.join("app/views/themes/source-publisher/daily_deal_purchases/certificate_layout.html.erb"), @certificate.daily_deal_purchase.custom_voucher_template_layout_path
    end

    should "use the app/views/themes/source-publisher/daily_deal_purchases/_certificate_body.html.erb for custom_voucher_template_path" do
      assert_equal Rails.root.join("app/views/themes/source-publisher/daily_deal_purchases/_certificate_body.html.erb"), @certificate.daily_deal_purchase.custom_voucher_template_path
    end		

	end

end
