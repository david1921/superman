module TravelsaversTestHelper
  
  TS_TEST_DATA_DIR = Rails.root.join("test/unit/travelsavers/data")

  def travelsavers_booking_url(booking_id)
    "https://psclient:TSvH78%23L$@bookingservices.travelsavers.com:443/productservice.svc/REST/BookingTransaction?TransactionID=#{booking_id}"
  end

  def update_ts_booking_from_xml_file(booking, xml_filename)
    booking.send(:update_from_xml!, File.read(xml_filename))
  end

  def stub_ts_pending_response(url)
    FakeWeb.register_uri(:get, url, :body => File.read(TS_TEST_DATA_DIR.join("book_transaction_pending.xml")))
  end
  
  def stub_ts_success_response(url)
    FakeWeb.register_uri(:get, url, :body => File.read(TS_TEST_DATA_DIR.join("book_transaction_success.xml")))
  end

  def stub_ts_validation_errors_response(url)
    FakeWeb.register_uri(:get, url, :body => File.read(TS_TEST_DATA_DIR.join("book_transaction_validation_errors.xml")))
  end
  
  def stub_ts_vendor_booking_errors_response(url)
    FakeWeb.register_uri(:get, url, :body => File.read(TS_TEST_DATA_DIR.join("book_transaction_booking_errors.xml")))
  end
  
  def stub_ts_vendor_fixable_booking_errors_response(url)
    FakeWeb.register_uri(:get, url, :body => File.read(TS_TEST_DATA_DIR.join("book_transaction_fixable_booking_errors.xml")))
  end
  
  def stub_ts_unknown_errors_response(url)
    FakeWeb.register_uri(:get, url, :body => File.read(TS_TEST_DATA_DIR.join("book_transaction_status_unknown.xml")))
  end

  def stub_ts_sold_out_error_response(url)
    FakeWeb.register_uri(:get, url, :body => File.read(TS_TEST_DATA_DIR.join("book_transaction_sold_out.xml")))
  end
  
  def stub_ts_success_with_vendor_booking_retrieval_errors_response(url)
    FakeWeb.register_uri(:get, url, :body => File.read(TS_TEST_DATA_DIR.join("book_transaction_vendor_booking_retrieval_errors.xml")))
  end
  
  def stub_ts_invalid_post_certificate_response(url)
    FakeWeb.register_uri(:get, url, :body => File.read(TS_TEST_DATA_DIR.join("book_transaction_invalid_post_certificate.xml")))
  end
  
  def stub_ts_server_500_error_response(url)
    FakeWeb.register_uri(:get, url, :body => "an error occurred", :status => ["500", "Server error"])
  end
  
  def stub_ts_invalid_book_transaction_response(url)
    FakeWeb.register_uri(:get, url, :body => "this is not a valid book transaction!")
  end

  def stub_ts_price_mismatch_response(url)
    FakeWeb.register_uri(:get, url, :body => File.read(TS_TEST_DATA_DIR.join("book_transaction_price_mismatch.xml")))
  end
end
