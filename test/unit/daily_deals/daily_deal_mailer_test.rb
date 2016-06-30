require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealMailerTest < ActionMailer::TestCase
  include ActionController::Assertions::SelectorAssertions

  def test_purchase_confirmation_with_certificates

    @daily_deal = daily_deals(:changos)
    @consumer = users(:john_public)
    @daily_deal_purchase = @daily_deal.daily_deal_purchases.new
    @daily_deal_purchase.consumer = @consumer
    @daily_deal_purchase.quantity = 1
    @daily_deal_purchase.gift = false
    @daily_deal_purchase.save!
    @daily_deal_purchase.daily_deal_payment = BraintreePayment.new
    @daily_deal_purchase.daily_deal_payment.payment_gateway_id = "1234"
    @daily_deal_purchase.daily_deal_payment.payment_at = Time.now
    @daily_deal_purchase.daily_deal_payment.credit_card_last_4 = "0000"
    @daily_deal_purchase.daily_deal_payment.amount = @daily_deal.price
    @daily_deal_purchase.daily_deal_payment.save!

    ActionMailer::Base.deliveries.clear

    DailyDealMailer.deliver_purchase_confirmation_with_certificates @daily_deal_purchase
    assert_equal 1, ActionMailer::Base.deliveries.size, "Emails delivered"
    email = ActionMailer::Base.deliveries.first

    assert_equal ["bbdsupport@analoganalytics.com"], email.from, "From: header"
    assert_equal "MySDH.com Deal of the Day", email.friendly_from, "From: header (friendly)"
    assert_equal [@consumer.email], email.to, "To: header"
    assert_match /purchase confirmed/i, email.subject, "Subject: header"

    assert_equal "multipart/mixed", email.content_type, "Content-Type: header"
    assert_equal 2, email.parts.size, "Email message should have 4 parts"
    
    part_multi_alt = email.parts.detect { |p| p.content_type == "multipart/alternative" }
    assert_not_nil part_multi_alt, "multipart/alternative"
    assert_equal 2, part_multi_alt.parts.size, "Alternative part should have 2 parts"

    [:plain, :html].each do |ctype|
      part = part_multi_alt.parts.detect { |p| p.content_type == "text/#{ctype}" }
      assert_not_nil part, "Should have text/#{ctype} part"

      assert_match %r{#{"%.2f" % @daily_deal_purchase.amount}}, part.body, "Should contain transaction amount"

      body_part = part_multi_alt.parts.detect { |p| p.content_type == "text/#{ctype}" }

      if ctype == :plain
        assert_match /Total Paid:.*$\n\nKindly note/, body_part.body, "Purchase confirmation email closing paragraph"
        assert_match /program at MySDH.com\.\n\nSUPPORT/, body_part.body, "Purchase confirmation email closing paragraph"
      end
      assert_match /will show a payment to Analog Analytics/, body_part.body, "Purchase confirmation email closing paragraph"
      assert_match /Please contact us if you have any questions: http:/, body_part.body, "Purchase confirmation email closing paragraph"
      assert_match /Please contact us if you have any questions: http:/, body_part.body, "Purchase confirmation email closing paragraph"
    end

    assert_equal 1, email.attachments.size, "Should have one attachment"
    attachment = email.attachments.first
    assert_equal "application/pdf", attachment.content_type
    assert_match /.+\.pdf\z/, attachment.original_filename
  end

  def test_purchase_confirmation_with_custom_closing_paragraph
    publisher = Factory(:publisher, :label => "entertainment", :daily_deal_email_signature => "The Entertainment® DealTM Team")
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :advertiser => advertiser)
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal)

    assert File.exists?(
               "#{Rails.root}/app/views/themes/#{daily_deal_purchase.publisher.group_label_or_label}" +
                   "/daily_deal_mailer/_purchase_confirmation_closing_paragraph.text.plain.erb")
    purch_conf_mail = DailyDealMailer.create_purchase_confirmation_with_certificates daily_deal_purchase
    body_part = purch_conf_mail.parts[0].parts.detect { |p| p.content_type == "text/plain" }
    assert_match /Total Paid:.*$\n\nKindly note/, body_part.body, "Custom purchase confirmation email closing paragraph"
    assert_match /will show a payment to Entertainment.com Deals./, body_part.body,
                 "Custom purchase confirmation email closing paragraph"
    assert_match /show a payment to Entertainment.com Deals\.\n\nSUPPORT/, body_part.body,
                 "Custom purchase confirmation email CC info"
    assert_match /Please contact us if you have any questions: deals@entertainment.com\./, body_part.body,
                 "Custom purchase confirmation email contact"
    assert_match /Thank you for your purchase today!\n\nThe Entertainment® DealTM Team/, body_part.body,
                 "Custom purchase confirmation email signature"
  end

  def test_purchase_confirmation_with_certificates_and_custom_email_voucher_redemption_message

    @daily_deal = daily_deals(:changos)
    @daily_deal.email_voucher_redemption_message = "some text entered by the client"
    @daily_deal.save!
    @consumer = users(:john_public)
    @daily_deal_purchase = @daily_deal.daily_deal_purchases.new
    @daily_deal_purchase.consumer = @consumer
    @daily_deal_purchase.quantity = 1
    @daily_deal_purchase.gift = false
    @daily_deal_purchase.save!
    @daily_deal_purchase.daily_deal_payment = BraintreePayment.new
    @daily_deal_purchase.daily_deal_payment.payment_gateway_id = "1234"
    @daily_deal_purchase.daily_deal_payment.payment_at = Time.now
    @daily_deal_purchase.daily_deal_payment.credit_card_last_4 = "0000"
    @daily_deal_purchase.daily_deal_payment.amount = @daily_deal.price
    @daily_deal_purchase.daily_deal_payment.save!

    ActionMailer::Base.deliveries.clear

    DailyDealMailer.deliver_purchase_confirmation_with_certificates @daily_deal_purchase
    assert_equal 1, ActionMailer::Base.deliveries.size, "Emails delivered"
    email = ActionMailer::Base.deliveries.first

    assert_equal ["bbdsupport@analoganalytics.com"], email.from, "From: header"
    assert_equal "MySDH.com Deal of the Day", email.friendly_from, "From: header (friendly)"
    assert_equal [@consumer.email], email.to, "To: header"
    assert_match /purchase confirmed/i, email.subject, "Subject: header"

    assert_equal "multipart/mixed", email.content_type, "Content-Type: header"
    assert_equal 2, email.parts.size, "Email message should have 2 parts"
    
    part_multi_alt = email.parts.detect { |p| p.content_type == "multipart/alternative" }
    assert_not_nil part_multi_alt, "multipart/alternative"
    assert_equal 2, part_multi_alt.parts.size, "Alternative part should have 2 parts"

    [:plain, :html].each do |ctype|
      part = part_multi_alt.parts.detect { |p| p.content_type == "text/#{ctype}" }
      assert_not_nil part, "Should have text/#{ctype} part"

      assert_match %r{#{"%.2f" % @daily_deal_purchase.amount}}, part.body, "Should contain transaction amount"

      body_part = part_multi_alt.parts.detect { |p| p.content_type == "text/#{ctype}" }

      if ctype == :plain
        assert_match /Total Paid:.*$\n\nKindly note/, body_part.body, "Purchase confirmation email closing paragraph"
        assert_match /program at MySDH.com\.\n\nSUPPORT/, body_part.body, "Purchase confirmation email closing paragraph"
      end
      assert_match /will show a payment to Analog Analytics/, body_part.body, "Purchase confirmation email closing paragraph"
      assert_match /Please contact us if you have any questions: http:/, body_part.body, "Purchase confirmation email closing paragraph"
      assert_match /some text entered by the client/, body_part.body, "Should include daily deal email message entered by client"
    end

    assert_equal 1, email.attachments.size, "Should have one attachment"
    attachment = email.attachments.first
    assert_equal "application/pdf", attachment.content_type
    assert_match /.+\.pdf\z/, attachment.original_filename
  end

  def test_purchase_confirmation_with_custom_closing_paragraph_custom_email_voucher_redemption_message
    publisher = Factory(:publisher, :label => "entertainment", :daily_deal_email_signature => "The Entertainment® DealTM Team")
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :advertiser => advertiser, :email_voucher_redemption_message => "some text entered by the client")
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal)

    assert File.exists?(
               "#{Rails.root}/app/views/themes/#{daily_deal_purchase.publisher.group_label_or_label}" +
                   "/daily_deal_mailer/_purchase_confirmation_closing_paragraph.text.plain.erb")
    purch_conf_mail = DailyDealMailer.create_purchase_confirmation_with_certificates daily_deal_purchase
    body_part = purch_conf_mail.parts[0].parts.detect { |p| p.content_type == "text/plain" }
    assert_match /Total Paid:.*$\n\nKindly note/, body_part.body, "Custom purchase confirmation email closing paragraph"
    assert_match /will show a payment to Entertainment.com Deals./, body_part.body,
                 "Custom purchase confirmation email closing paragraph"
    assert_match /show a payment to Entertainment.com Deals\.\n\nSUPPORT/, body_part.body,
                 "Custom purchase confirmation email CC info"
    assert_match /Please contact us if you have any questions: deals@entertainment.com\./, body_part.body,
                 "Custom purchase confirmation email contact"
    assert_match /Thank you for your purchase today!\n\nThe Entertainment® DealTM Team/, body_part.body,
                 "Custom purchase confirmation email signature"
    assert_match /some text entered by the client/, body_part.body, "Should include daily deal email message entered by client"
  end

  context "#purchase_confirmation_with_certificates" do
    context "(gift) purchase for multiple recipients" do
      setup do
        @num_recipients = 5
        @daily_deal_purchase = Factory(:captured_daily_deal_purchase,
                                       :quantity => @num_recipients,
                                       :recipient_names => @num_recipients.times.collect { |i| "Recipient #{i}" },
                                       :gift => true
        )
        DailyDealMailer.deliver_purchase_confirmation_with_certificates @daily_deal_purchase
        @email = ActionMailer::Base.deliveries.last
      end

      should "have a certificate attachment for each recipient" do
        assert_equal @num_recipients, @daily_deal_purchase.daily_deal_certificates.size
        assert_equal @num_recipients, @email.attachments.size, "Attachment and recipient counts don't match."
      end

      should "have certificate filenames that start with the recipient's name" do
        attachment_filenames = @email.attachments.collect(&:original_filename)
        @daily_deal_purchase.recipient_names.each do |recipient_name|
          assert attachment_filenames.select { |f| f =~ /^#{recipient_name.downcase.gsub(' ', '_')}/ }.any?, "Expected attachment filename to start with recipient's name"
        end
      end
    end

    context "multiple certificate purchase for self" do
      setup do
        @daily_deal_purchase = Factory(:captured_daily_deal_purchase,
                                       :quantity => 5,
                                       :gift => false
        )
        DailyDealMailer.deliver_purchase_confirmation_with_certificates @daily_deal_purchase
        @email = ActionMailer::Base.deliveries.last
      end

      should "have a single attachment" do
        assert_equal 1, @email.attachments.size
      end
    end

    should "have the publisher's daily deal logo in an html part" do
      daily_deal_purchase = Factory(:daily_deal_purchase)
      publisher = daily_deal_purchase.publisher
      publisher.daily_deal_logo = File.open(Rails.root.join('test/fixtures/files/advertiser_logo.png'))
      publisher.save!
      email = DailyDealMailer.create_purchase_confirmation_with_certificates daily_deal_purchase
      assert_not_nil (html_part = email.parts[0].parts.select { |p| p.content_type == 'text/html' }.first), 'Expected html part'
      assert_match %r{<img src="#{Regexp.escape publisher.daily_deal_logo.url}"}, html_part.body, 'Expected publisher logo'
    end

    should "render for publisher with default and custom templates" do
      [nil, 'entertainment', 'thomsonlocal'].each do |label|
        daily_deal_purchase = Factory(:daily_deal_purchase)
        publisher = daily_deal_purchase.publisher
        if label
          publisher.label = label
          publisher.save!
        end

        DailyDealMailer.deliver_purchase_confirmation_with_certificates daily_deal_purchase

        # Check that all partials are rendered
        assert_select_email do
          ['your_vouchers_are_attached', 'voucher_redemption_message', 'purchase_confirmation_closing_paragraph'].each do |css_class|
            assert_select "p.#{css_class}", /[^\s]+/ # check has some content
          end
        end
      end
    end

    context "email offer" do
      context "without offer" do
        setup do
          @daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => Factory(:daily_deal, :email_voucher_offer => nil))
          @email = DailyDealMailer.create_purchase_confirmation_with_certificates @daily_deal_purchase
        end

        should "not have a coupon link in the plaintext part" do
          part = @email.parts[0].parts[0]
          assert_equal 'text/plain', part.content_type
          assert_no_match %r{coupon.*here:\s+http(s)?://}i, part.body
        end

        should "not have a coupon in the html part" do
          part = @email.parts[0].parts[1]
          assert_equal 'text/html', part.content_type
          DailyDealMailer.deliver(@email)
          assert_select_email do
            assert_select 'div.offer', :count => 0
          end
        end
      end

      context "with offer" do
        setup do
          @daily_deal_purchase = Factory(:captured_daily_deal_purchase)
          @offer = Factory(:offer, :advertiser => @daily_deal_purchase.daily_deal.advertiser)
          dd = @daily_deal_purchase.daily_deal
          dd.email_voucher_offer = @offer
          dd.save!
          @offer_url = "http://#{@offer.publisher.daily_deal_host}/publishers/#{@offer.publisher.id}/offers?offer_id=#{@offer.id}"
          @email = DailyDealMailer.create_purchase_confirmation_with_certificates @daily_deal_purchase
        end

        should "have a coupon link in the plaintext part" do
          part = @email.parts[0].parts[0]
          assert_equal 'text/plain', part.content_type
            assert part.body.include?(@offer_url), "Coupon link was not in email body"
        end

        should "have a coupon in the html part" do
          DailyDealMailer.deliver_purchase_confirmation_with_certificates @daily_deal_purchase
          @email = DailyDealMailer.deliveries.last
          part = @email.parts[0].parts[1]
          assert_equal 'text/html', part.content_type
          DailyDealMailer.deliver(@email)
          assert_select_email do
            assert_select 'div.offer' do
              assert_select 'h2', 'OFFER'
              assert_select "a[href='#{@offer_url}']"
            end
          end
        end
      end
      
      context "with offer for timewarnercable publishing group" do
        
        setup do
          publishing_group = Factory(:publishing_group, :label => 'rr')
          @daily_deal_purchase = Factory(:captured_daily_deal_purchase)
          @daily_deal_purchase.publisher.update_attribute(:publishing_group, publishing_group)
          DailyDealPurchase.any_instance.stubs(:custom_voucher_template_exists?).returns(false)
          @offer = Factory(:offer, :advertiser => @daily_deal_purchase.daily_deal.advertiser)
          dd = @daily_deal_purchase.daily_deal
          dd.email_voucher_offer = @offer
          dd.save!
          @offer_url = "http://#{@offer.publisher.daily_deal_host}/publishers/#{@offer.publisher.id}/offers?offer_id=#{@offer.id}"
          @email = DailyDealMailer.create_purchase_confirmation_with_certificates @daily_deal_purchase          
        end
        
        should "have twc redemption message in the plaintext part" do
          part = @email.parts[0].parts[0]
          assert_equal 'text/plain', part.content_type
          assert part.body.include?("Really good news!  Your ClickedIn™ voucher is attached to this email.  You can also visit your account at:")
        end
        
        should "have a coupon link in the plaintext part" do
          part = @email.parts[0].parts[0]
          assert_equal 'text/plain', part.content_type
          assert part.body.include?(@offer_url), "Coupon link was not in email body"
          assert part.body.include?("ADDITIONAL SAVINGS OFFER"), "ADDITIONAL SAVINGS OFFER not in email body"
          assert part.body.include?("To thank you for your ClickedIn #{@offer.advertiser.name} purchase, take advantage of an additional #{@offer.advertiser.name} money savings coupon here:"), "To thank you text not in email body"
        end

        should "have a coupon in the html part" do
          DailyDealMailer.deliver_purchase_confirmation_with_certificates @daily_deal_purchase
          @email = DailyDealMailer.deliveries.last
          part = @email.parts[0].parts[1]
          assert_equal 'text/html', part.content_type
          DailyDealMailer.deliver(@email)
          assert_select_email do
            assert_select 'div.offer' do
              assert_select 'h2', 'ADDITIONAL SAVINGS OFFER'
              assert_select 'p', "To thank you for your ClickedIn #{@offer.advertiser.name} purchase, take advantage of an additional #{@offer.advertiser.name} money savings coupon here:"
              assert_select "a[href='#{@offer_url}']"
            end
          end
        end
        
        
      end
      
    end
  
    context "email subject" do
      
      context "with publisher that has enable_daily_deal_voucher_headline" do
        
        setup do
          @daily_deal_purchase = Factory(:captured_daily_deal_purchase)
          @daily_deal_purchase.publisher.update_attribute(:enable_daily_deal_voucher_headline, true)
        end
        
        context "with no voucher headline set on daily deal" do
          
          setup do
            @daily_deal_purchase.daily_deal.update_attribute(:voucher_headline, nil)
            @email = DailyDealMailer.create_purchase_confirmation_with_certificates @daily_deal_purchase
          end
          
          should "render the default subject" do
            assert_equal "Purchase Confirmed: $30.00 Deal to #{@daily_deal_purchase.daily_deal.advertiser.name}", @email.subject
          end
          
        end
        
        context "with a voucher headline set on daily deal" do
          
          setup do
            @daily_deal_purchase.daily_deal.update_attribute(:voucher_headline, "Voucher Headline")
            @email = DailyDealMailer.create_purchase_confirmation_with_certificates @daily_deal_purchase          
          end
          
          should "render with the subject with the voucher headline" do
            assert_equal "Purchase Confirmed: Voucher Headline", @email.subject
          end
          
        end
        
      end
      
    end
    
    context "translations" do
      
      context "purchase confirmation email in locale 'en'" do
        
        setup do
          I18n.locale = 'en'
          @daily_deal = Factory :daily_deal
          @consumer = Factory :consumer, :publisher => @daily_deal.publisher
          @purchase = Factory :captured_daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer
          @purchase_confirmation = DailyDealMailer.create_purchase_confirmation_with_certificates(@purchase)
          @html_part = @purchase_confirmation.parts[0].parts.detect { |p| p.content_type = "text/html" }
          @text_part = @purchase_confirmation.parts[0].parts.detect { |p| p.content_type = "text/plain" }
        end
        
        should "show the subject in locale 'en'" do
          assert_equal "Purchase Confirmed: #{@purchase.line_item_name}", @purchase_confirmation.subject
        end
        
        should "show the opening salutation in locale 'en'" do
          assert_match /Dear .+/, @html_part.body
          assert_match /Dear .+/, @text_part.body
        end
        
        should "show the 'your vouchers are attached' paragraph in locale 'en'" do
          assert_match /Your deal certificates are attached/i, @html_part.body
          assert_match /Your deal certificates are attached/i, @text_part.body
        end
        
        should "show the 'and print any deals' paragraph in locale 'en'" do
          assert_match /and print any deals/, @html_part.body
          assert_match /and print any deals/, @text_part.body
        end
        
        should "show the 'please bring your printed voucher' paragraph in locale 'en'" do
          assert_match /Please bring your printed voucher/i, @html_part.body
          assert_match /Please bring your printed voucher/i, @text_part.body
        end
        
        should "show the 'INVOICE' label in locale 'en'" do
          assert_match /INVOICE/, @html_part.body
          assert_match /INVOICE/, @text_part.body
        end
        
        should "show the 'The Deal:' label in locale 'en'" do
          assert_match /The Deal:/, @html_part.body
          assert_match /The Deal:/, @text_part.body
        end
        
        should "show the 'Quantity:' label in locale 'en'" do
          assert_match /Quantity:/, @html_part.body
          assert_match /Quantity:/, @text_part.body
        end
        
        should "show the 'Total Paid:' label in locale 'en'" do
          assert_match /Total Paid:/, @html_part.body
          assert_match /Total Paid:/, @text_part.body
        end
        
        should "show the 'kindly note' paragraph in locale 'en'" do
          assert_match /Kindly note that your/i, @html_part.body
          assert_match /Kindly note that your/i, @text_part.body
        end
        
        should "show the 'SUPPORT' heading in locale 'en'" do
          assert_match /SUPPORT/, @html_part.body
          assert_match /SUPPORT/, @text_part.body
        end
        
        should "show the 'please contact us' paragraph in locale 'en'" do
          assert_match /Please contact us if you have any questions:/, @html_part.body
          assert_match /Please contact us if you have any questions:/, @text_part.body
        end
        
        should "show the 'thank you' paragraph in locale 'en'" do
          assert_match /Thank you for your purchase today!/, @html_part.body
          assert_match /Thank you for your purchase today!/, @text_part.body
        end
        
      end
      
      context "purchase confirmation email in locale 'es-MX'" do

        context "paypal daily deal" do
          setup do
            @daily_deal = Factory :paypal_daily_deal
            I18n.locale = 'es-MX'
            @consumer = Factory :consumer, :publisher => @daily_deal.publisher
            I18n.locale = 'en'
            @purchase = Factory :paypal_daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer
            @purchase_confirmation = DailyDealMailer.create_purchase_confirmation_with_certificates(@purchase)
            @text_part = @purchase_confirmation.parts[0].parts[0]
            @html_part = @purchase_confirmation.parts[0].parts[1]
          end

          should "not be a braintree payment" do
            assert !@purchase.braintree?
          end

          should "show the 'kindly note' paragraph in locale 'es-MX' with paypal_part" do
            assert_match /Su tarjeta de PayPal o crédito se/i, @html_part.body
            assert_match /Su tarjeta de PayPal o crédito se/i, @text_part.body
          end

        end

        context "non-paypal daily deal" do
          setup do
            @daily_deal = Factory :daily_deal
            I18n.locale = 'es-MX'
            @consumer = Factory :consumer, :publisher => @daily_deal.publisher
            I18n.locale = 'en'
            @purchase = Factory :captured_daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer
            @purchase_confirmation = DailyDealMailer.create_purchase_confirmation_with_certificates(@purchase)
            @text_part = @purchase_confirmation.parts[0].parts[0]
            @html_part = @purchase_confirmation.parts[0].parts[1]
          end

          should "show the subject in locale 'es-MX'" do
            assert_equal "Su compra ha sido confirmada: #{@purchase.line_item_name}", @purchase_confirmation.subject
          end

          should "show the opening salutation in locale 'es-MX'" do
            assert_match /Estimado .+/, @html_part.body
            assert_match /Estimado .+/, @text_part.body
          end

          should "show the 'your vouchers are attached' paragraph in locale 'es-MX'" do
            assert_match /Anexo encontrará le\/los vales para/i, @html_part.body
            assert_match /Anexo encontrará le\/los vales para/i, @text_part.body
          end

          should "show the 'and print any deals' paragraph in locale 'es-MX'" do
            assert_match /e imprimir qualquier otra oferta/, @html_part.body
            assert_match /e imprimir qualquier otra oferta/, @text_part.body
          end

          should "show the 'please bring your printed voucher' paragraph in locale 'es-MX'" do
            assert_match /Por favor lleve una copia del vale/i, @html_part.body
            assert_match /Por favor lleve una copia del vale/i, @text_part.body
          end

          should "show the 'INVOICE' label in locale 'es-MX'" do
            assert_match /FACTURA/, @html_part.body
            assert_match /FACTURA/, @text_part.body
          end

          should "show the 'The Deal:' label in locale 'es-MX'" do
            assert_match /La Oferta Semanal:/, @html_part.body
            assert_match /La Oferta Semanal:/, @text_part.body
          end

          should "show the 'Quantity:' label in locale 'es-MX'" do
            assert_match /Cantidad:/, @html_part.body
            assert_match /Cantidad:/, @text_part.body
          end

          should "show the 'Total Paid:' label in locale 'es-MX'" do
            assert_match /Usted pagó un total de:/, @html_part.body
            assert_match /Usted pagó un total de:/, @text_part.body
          end

          should "show the 'kindly note' paragraph in locale 'es-MX'" do
            assert_match /Nota:\n\nSu tarjeta de crédito/i, @html_part.body
            assert_match /Nota:\n\nSu tarjeta de crédito/i, @text_part.body
          end

          should "show the 'SUPPORT' heading in locale 'es-MX'" do
            assert_match /SERVICIO AL CLIENTE/, @html_part.body
            assert_match /SERVICIO AL CLIENTE/, @text_part.body
          end

          should "show the 'please contact us' paragraph in locale 'es-MX'" do
            assert_match /Si tiene alguna duda, favor/, @html_part.body
            assert_match /Si tiene alguna duda, favor/, @text_part.body
          end

          should "show the 'thank you' paragraph in locale 'es-MX'" do
            assert_match /¡Gracias por su compra!/, @html_part.body
            assert_match /¡Gracias por su compra!/, @text_part.body
          end

        end
      end
    end
  
    context "Entercom purchase that earned a promotion discount code" do
      setup do
        @deal = Factory(:daily_deal)
        @deal.publishing_group.update_attributes!(:label => 'entercomnew')
        @purchase = Factory(:daily_deal_purchase, :daily_deal => @deal)
        @discount = Factory(:discount)
        @promotion = mock('promotion')
        @purchase.stubs(:earned_discount).returns(@discount)
      end

      should "render Entercom's earned discount section and promotional logo" do
        DailyDealMailer.deliver_purchase_confirmation_with_certificates(@purchase)
        email = ActionMailer::Base.deliveries.last
        part_multi_alt = email.parts.detect { |p| p.content_type == "multipart/alternative" }
        assert_not_nil part_multi_alt, "multipart/alternative"
        assert_equal 2, part_multi_alt.parts.size, "Alternative part should have 2 parts"

        [:plain, :html].each do |ctype|
          part = part_multi_alt.parts.detect { |p| p.content_type == "text/#{ctype}" }
          assert_not_nil part, "Should have text/#{ctype} part"
          body_part = part_multi_alt.parts.detect { |p| p.content_type == "text/#{ctype}" }

          case ctype
            when :plain
              assert_match /promo code \(see below\)/, body_part.body
              assert_match /code: #{@discount.code}/, body_part.body
            when :html
              assert_select_email do
                assert_select "p#promotion_explanation", /promo code \(see below\)/
                assert_select "p#promotion_discount_code", /code: #{@discount.code}/
                assert_select "img.promotion_logo"
              end
            else
              raise "unexpected content type: #{ctype.inspect}"
          end
        end
      end

      context "without earned discount" do
        setup do
          @purchase.stubs(:earned_discount).returns(nil)
        end

        should "not render the promotional logo" do
          DailyDealMailer.deliver_purchase_confirmation_with_certificates(@purchase)
          assert_select_email do
            assert_select "img.promotion_logo", :count => 0
          end
        end

        should "render the publisher logo" do
          DailyDealMailer.deliver_purchase_confirmation_with_certificates(@purchase)
          assert_select_email do
            assert_select "h1 > img[src=#{@purchase.consumer.publisher.daily_deal_logo.url}]"
          end
        end
      end
    end
  end
end
