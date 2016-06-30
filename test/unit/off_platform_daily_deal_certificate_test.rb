require File.dirname(__FILE__) + "/../test_helper"

class OffPlatformDailyDealCertificateTest < ActiveSupport::TestCase
  test "requires consumer and download url" do
    cert = OffPlatformDailyDealCertificate.new

    assert !cert.valid?, "valid?"

    cert.consumer = Factory(:consumer)
    assert !cert.valid?, "valid?"

    cert.executed_at = 2.months.ago
    assert !cert.valid?, "valid?"

    cert.redeemer_names = "John Ford"
    assert !cert.valid?, "valid?"

    cert.line_item_name = "$45 pizza"
    assert !cert.valid?, "valid?"

    cert.download_url = "http://example.com"
    assert cert.valid?, cert.errors.full_messages

    cert.expires_on = 2.months.from_now
    assert cert.valid?, "valid?"
  end

  test "requires consumer and voucher pdf" do
    cert = Factory(:off_platform_daily_deal_certificate)
    assert cert.valid?, "valid?"
    cert.download_url = nil
    assert !cert.valid?, "valid?"
    cert.voucher_pdf_file_name = "/tmp/test"
    assert cert.valid?, 'valid?'
  end

  test "shared reader methods with DailyDealPurchase" do
    cert = Factory(:off_platform_daily_deal_certificate,
      :line_item_name => "$30 pizza for $10",
      :redeemer_names => "Ben Parker",
      :executed_at => Time.zone.local(2010, 5, 12),
      :expires_on => Time.zone.local(2013, 12, 31).to_date,
      :download_url => "http://example.com/cert.pdf"
    )
    assert_equal "$30 pizza for $10", cert.line_item_name, "line_item_name"
    assert_equal "Ben Parker", cert.redeemer_names, "redeemer_names"
    assert_equal "May 12, 2010", cert.humanize_created_on, "humanize_created_on"
    assert_equal "December 31, 2013", cert.humanize_expires_on, "humanize_expires_on"
    assert_equal "http://example.com/cert.pdf", cert.download_url, "download_url"
    assert_equal 1, cert.quantity_excluding_refunds, "quantity_excluding_refunds"
    assert_equal 1, cert.quantity, "quantity"
  end

  test "expires_on can be nil" do
    cert = Factory(:off_platform_daily_deal_certificate, :expires_on => nil)
    assert_equal nil, cert.humanize_expires_on, "humanize_expires_on"
  end
end
