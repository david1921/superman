class DailyDealMailer < ApplicationMailer

  helper :daily_deal_purchase, :daily_deal

  #
  # ActionMailer doesn't perform implicit template rendering (e.g. of latest.text.plain.erb) when attachments are present
  #
  def purchase_confirmation_with_certificates(daily_deal_purchase)
    publisher = daily_deal_purchase.publisher

    I18n.locale = daily_deal_purchase.consumer.preferred_locale if daily_deal_purchase.consumer.preferred_locale.present?
    recipients daily_deal_purchase.consumer.email
    subject Analog::Themes::I18n.t(publisher, "daily_deal.purchase_confirmation.subject", :line_item_name => daily_deal_purchase.line_item_name)
    from daily_deal_sending_email_address(publisher)
    sent_on Time.now
    content_type "multipart/mixed"

    vars = {
      :daily_deal_purchase => daily_deal_purchase,
      :publisher => publisher,
      :offer => daily_deal_purchase.daily_deal.email_voucher_offer,
    }

    if offer = vars[:offer]
      vars[:offer_url] = public_offers_url(publisher, :host => publisher.daily_deal_host, :offer_id => offer.id)
    end

    part :content_type => 'multipart/alternative' do |alt|
      alt.part :content_type => 'text/plain' do |plain|
        template_path = theme_template("daily_deal_mailer/purchase_confirmation_with_certificates.text.plain", publisher)
        plain.body = render_message(template_path, vars)
      end
      alt.part :content_type => 'text/html' do |html|
        template_path = theme_template("daily_deal_mailer/purchase_confirmation_with_certificates.text.html", publisher)
        html.body = render_message(template_path, vars)
      end
    end

    # Send separate attachments for each recipient for gift purchases; single file for any quantity bought for oneself
    case daily_deal_purchase.gift
    when true
      daily_deal_purchase.daily_deal_certificates.each do |certificate|
        attachment(
          :content_type => 'application/pdf',
          :filename => certificate.pdf_filename,
          :body => certificate.to_pdf
        )
      end
    else
      attachment(
        :content_type => 'application/pdf',
        :filename => daily_deal_purchase.daily_deal_certificates_file_name,
        :body => daily_deal_purchase.daily_deal_certificates_pdf
      )
    end
  end

  def daily_deal(daily_deal, to, body)
    recipients to
    subject "[TEST]: #{daily_deal.value_proposition}"
    from "support@anaoganalytics.com"
    sent_on Time.now
    part(
      :content_type => "text/html",
      :body => body
    )
  end
end

