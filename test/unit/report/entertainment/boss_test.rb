require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Report::Entertainment::BossTest
module Report
  module Entertainment

    class BossTest < ActiveSupport::TestCase

      def setup
        @publishing_group = Factory.build(:publishing_group)
        @publisher = Factory.build(:publisher, :publishing_group => @publishing_group, :listing => "prodcode")
        @consumer = Factory.build(:billing_address_consumer, :publisher => @publisher)
        @consumer2 = Factory.build(:billing_address_consumer, :publisher => @publisher, :first_name=>"Jeff")
        @deal = Factory.build(:daily_deal, :publisher => @publisher)
        @discount = Factory.build(:discount, :publisher => @publisher, :code => "discount_code")
        @daily_deal_purchase = Factory.build(:authorized_daily_deal_purchase, :consumer => @consumer, :daily_deal => @deal, :discount => @discount)
        @daily_deal_purchase2 = Factory.build(:authorized_daily_deal_purchase, :consumer => @consumer2, :daily_deal => @deal, :discount => @discount, :quantity=>2)
        @daily_deal_certificate = Factory.build(:daily_deal_certificate, :daily_deal_purchase => @daily_deal_purchase, :redeemer_name => "John Q Public")
        @daily_deal_certificate2 = Factory.build(:daily_deal_certificate, :daily_deal_purchase => @daily_deal_purchase2, :redeemer_name => "John Q Public")
        @daily_deal_certificate3 = Factory.build(:daily_deal_certificate, :daily_deal_purchase => @daily_deal_purchase2, :redeemer_name => "John Q Public")
      end

      def save_fixture!
        @publisher.save!
        @consumer.save!
        @consumer2.save!
        @deal.save!
        @discount.save!
        @daily_deal_purchase.save!
        @daily_deal_purchase.authorized_purchase_factory_after_create
        @daily_deal_purchase2.save!
        @daily_deal_purchase2.authorized_purchase_factory_after_create
        @daily_deal_certificate.save!
        @daily_deal_certificate2.save!
        @daily_deal_certificate3.save!
      end

      test "generate for publisher" do
        save_fixture!
        csv    = []
        boss   = Report::Entertainment::Boss.new
        actual = boss.generate_for_publisher(csv, @publisher.id)
        assert_equal 3, csv.size
        assert_equal [@daily_deal_purchase.id, @daily_deal_purchase2.id].sort, actual.sort
      end

      test "generate only includes purchases that have not yet been sent" do
        @daily_deal_purchase.sent_to_publisher_at = Time.utc(2010, 4, 22)
        save_fixture!
        csv    = []
        boss   = Report::Entertainment::Boss.new
        actual = boss.generate_for_publisher(csv, @publisher.id)
        assert_equal 2, csv.size
        assert_equal [@daily_deal_purchase2.id], actual
      end

      test "generate from publishing group includes all purchases in publishing group" do
        save_fixture!
        csv    = []
        boss   = Report::Entertainment::Boss.new
        actual = boss.generate_for_publishing_group(csv, @publishing_group)
        assert_equal 3, csv.size
        assert_equal [@daily_deal_purchase.id, @daily_deal_purchase2.id].sort, actual.sort
      end

      test "bloody line number" do
        save_fixture!
        csv  = []
        boss = Report::Entertainment::Boss.new
        boss.generate_for_publisher(csv, @publisher.id)
        purchases = boss.find_purchases(@publisher.id)

        # This sucks but created_at is not granular enough
        # and we can't rely on database id order.  Ideas?
        if purchases[0] == @daily_deal_purchase
          assert_equal "1 ", csv[0][19]
          assert_equal "1 ", csv[1][19]
          assert_equal "2 ", csv[2][19]
        elsif purchases[0] == @daily_deal_purchase2
          assert_equal "1 ", csv[0][19]
          assert_equal "2 ", csv[1][19]
          assert_equal "1 ", csv[2][19]
        else
          fail("should never happen")
        end
        new_cert = Factory(:daily_deal_certificate, :daily_deal_purchase => @daily_deal_purchase)
        assert_raise NoMethodError, "new certs should not have singleton method" do
          new_cert.line_item
        end
      end

      test "valid? true" do
        boss = Report::Entertainment::Boss.new
        assert boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
      end

      test "valid? first_name" do
        boss                                     = Report::Entertainment::Boss.new
        @daily_deal_purchase.consumer.first_name = nil
        assert !boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
        @daily_deal_purchase.consumer.first_name = ""
        assert !boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
        @daily_deal_purchase.consumer.first_name = " "
        assert !boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
      end

      test "valid? last_name" do
        boss                                    = Report::Entertainment::Boss.new
        @daily_deal_purchase.consumer.last_name = nil
        assert !boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
        @daily_deal_purchase.consumer.last_name = ""
        assert !boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
        @daily_deal_purchase.consumer.last_name = " "
        assert !boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
      end

      test "valid? addr 1" do
        boss                                         = Report::Entertainment::Boss.new
        @daily_deal_purchase.consumer.address_line_1 = nil
        assert !boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
        @daily_deal_purchase.consumer.address_line_1 = ""
        assert !boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
      end

      test "valid? city" do
        boss                                       = Report::Entertainment::Boss.new
        @daily_deal_purchase.consumer.billing_city = nil
        assert !boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
        @daily_deal_purchase.consumer.billing_city = ""
        assert !boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
      end

      test "valid? state" do
        boss                                = Report::Entertainment::Boss.new
        @daily_deal_purchase.consumer.state = nil
        assert !boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
        @daily_deal_purchase.consumer.state = ""
        assert !boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
      end

      test "valid? zip" do
        boss                                   = Report::Entertainment::Boss.new
        @daily_deal_purchase.consumer.zip_code = nil
        assert !boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
        @daily_deal_purchase.consumer.zip_code = ""
        assert !boss.valid?(@daily_deal_certificate, @daily_deal_purchase)
      end

      test "boss field calls lambda, converts to string" do
        field = Report::Entertainment::Boss::BossField.new(13, lambda { |cert, purchase| cert.redeemer_name })
        assert_equal "John Q Public", field.call(@daily_deal_certificate, @daily_deal_purchase)
      end

      test "boss field truncates at length" do
        field = Report::Entertainment::Boss::BossField.new(4, lambda { |cert, purchase| cert.redeemer_name })
        assert_equal "John", field.call(@daily_deal_certificate, @daily_deal_purchase)
      end

      test "boss field pads left" do
        field = Report::Entertainment::Boss::BossField.new(17, lambda { |cert, purchase| cert.redeemer_name })
        assert_equal "John Q Public    ", field.call(@daily_deal_certificate, @daily_deal_purchase)
      end

      test "boss field handles nil and empty" do
        field = Report::Entertainment::Boss::BossField.new(10, lambda { |val1, val2| val1 })
        assert_equal "          ", field.call(nil, nil)
        assert_equal "          ", field.call("", "")
      end

      test "index issue with field defintion raises argument error" do
        boss = Report::Entertainment::Boss.new
        assert_raises ArgumentError do
          boss.field(nil, 100)
        end
      end

      test "field 1 - first name" do
        boss       = Report::Entertainment::Boss.new
        first_name = boss.field(@daily_deal_certificate, 0)
        assert_equal @consumer.first_name.ljust(25), first_name
      end

      test "field 2 - last name" do
        boss      = Report::Entertainment::Boss.new
        last_name = boss.field(@daily_deal_certificate, 1)
        assert_equal @consumer.last_name.ljust(25), last_name
      end

      test "field 3 - phone home" do
        boss = Report::Entertainment::Boss.new
        assert_equal " " * 10, boss.field(@daily_deal_certificate, 2)
      end

      test "field 4 - phone work" do
        boss = Report::Entertainment::Boss.new
        assert_equal " " * 10, boss.field(@daily_deal_certificate, 3)
      end

      test "field 5 - email" do
        boss = Report::Entertainment::Boss.new
        assert_equal @consumer.email.ljust(100), boss.field(@daily_deal_certificate, 4)
      end

      test "fields 6-11 - billing address" do
        boss = Report::Entertainment::Boss.new
        assert_equal @consumer.address_line_1.ljust(50), boss.field(@daily_deal_certificate, 5) # addr 1
        assert_equal @consumer.address_line_2.ljust(50), boss.field(@daily_deal_certificate, 6) # addr 2
        assert_equal @consumer.billing_city.ljust(30), boss.field(@daily_deal_certificate, 7) # city
        assert_equal @consumer.state.ljust(2), boss.field(@daily_deal_certificate, 8) # state
        assert_equal "999COU00000001".ljust(14), boss.field(@daily_deal_certificate, 9) # country
        assert_equal @consumer.zip_code.ljust(9), boss.field(@daily_deal_certificate, 10) # zip
      end

      test "fields 6-11 - billing address - with nil values" do
        boss                     = Report::Entertainment::Boss.new
        @consumer.address_line_1 = nil
        @consumer.address_line_2 = nil
        @consumer.billing_city   = nil
        @consumer.state          = nil
        @consumer.country_code   = nil
        @consumer.zip_code       = nil
        assert_equal "".ljust(50), boss.field(@daily_deal_certificate, 5)
        assert_equal "".ljust(50), boss.field(@daily_deal_certificate, 6)
        assert_equal "".ljust(30), boss.field(@daily_deal_certificate, 7)
        assert_equal "".ljust(2), boss.field(@daily_deal_certificate, 8)
        assert_equal "".ljust(14), boss.field(@daily_deal_certificate, 9)
        assert_equal "".ljust(9), boss.field(@daily_deal_certificate, 10)
      end

      test "addr line 1 and 2 truncate after 30 chars but still pads left - yes, I'm afraid so" do
        boss                     = Report::Entertainment::Boss.new
        @consumer.address_line_1 = "address line 1 that is more than thirty characters"
        @consumer.address_line_2 = "address line 2 that is more than thirty characters"
        assert_equal "address line 1 that is more th                    ", boss.field(@daily_deal_certificate, 5) # addr 1
        assert_equal "address line 2 that is more th                    ", boss.field(@daily_deal_certificate, 6) # addr 2
        assert_equal "address line 1 that is more th                    ", boss.field(@daily_deal_certificate, 23) # addr 1
        assert_equal "address line 2 that is more th                    ", boss.field(@daily_deal_certificate, 24) # addr 2
      end

      test "field 12 - group number - not used" do
        boss = Report::Entertainment::Boss.new
        assert_equal "".ljust(8), boss.field(@daily_deal_certificate, 11)
      end

      test "field 13 - group type - not used" do
        boss = Report::Entertainment::Boss.new
        assert_equal "".ljust(25), boss.field(@daily_deal_certificate, 12)
      end

      test "field 14 - registered flag always the same" do
        boss = Report::Entertainment::Boss.new
        assert_equal "N", boss.field(@daily_deal_certificate, 13)
      end

      test "field 15 - order date" do
        @daily_deal_purchase.executed_at = Time.utc(2010, 10, 22, 6, 30)
        boss                             = Report::Entertainment::Boss.new
        assert_equal "201010220630".ljust(12), boss.field(@daily_deal_certificate, 14)
      end

      test "fields 16,17,18 - order id, credit card fields - not used" do
        boss = Report::Entertainment::Boss.new
        assert_equal "".ljust(9), boss.field(@daily_deal_certificate, 15)
        assert_equal "".ljust(16), boss.field(@daily_deal_certificate, 16)
        assert_equal "".ljust(4), boss.field(@daily_deal_certificate, 17)
      end

      test "field 19 - purchase amt" do
        boss = Report::Entertainment::Boss.new
        assert_equal @daily_deal_purchase.total_paid.to_s.ljust(8), boss.field(@daily_deal_certificate, 18)
      end

      test "field 20 - line number" do
        boss = Report::Entertainment::Boss.new
        assert_equal "".ljust(2), boss.field(@daily_deal_certificate, 19)
      end

      test "field 21 - quantity" do
        boss = Report::Entertainment::Boss.new
        assert_equal "1".to_s.ljust(6), boss.field(@daily_deal_certificate, 20), "quantity for the line item -- always 1 here"
      end

      test "fields 22, 23 - recipient first and last name" do
        boss = Report::Entertainment::Boss.new
        assert_equal "John".ljust(25), boss.field(@daily_deal_certificate, 21)
        assert_equal "Public".ljust(25), boss.field(@daily_deal_certificate, 22)
      end

      test "fields 24-29 - dup of billing info" do
        boss = Report::Entertainment::Boss.new
        assert_equal @consumer.address_line_1.ljust(50), boss.field(@daily_deal_certificate, 23) # addr 1
        assert_equal @consumer.address_line_2.ljust(50), boss.field(@daily_deal_certificate, 24) # addr 2
        assert_equal @consumer.billing_city.ljust(30), boss.field(@daily_deal_certificate, 25) # city
        assert_equal @consumer.state.ljust(2), boss.field(@daily_deal_certificate, 26) # state
        assert_equal "999COU00000001".ljust(14), boss.field(@daily_deal_certificate, 27) # country
        assert_equal @consumer.zip_code.ljust(9), boss.field(@daily_deal_certificate, 28) # zip
      end

      test "field 30 - promo code" do
        boss = Report::Entertainment::Boss.new
        assert_equal @daily_deal_purchase.discount.code.ljust(15), boss.field(@daily_deal_certificate, 29)
      end

      test "field 31 - product code" do
        boss = Report::Entertainment::Boss.new
        assert_equal "".ljust(8), boss.field(@daily_deal_certificate, 30)
      end

      test "field 32 - purchase amt quantity 1" do
        boss = Report::Entertainment::Boss.new
        assert_equal @daily_deal_purchase.total_paid.to_s.ljust(6), boss.field(@daily_deal_certificate, 31)
      end

      test "field 32 - purchase amount quantity > 1 clean math" do
        boss                                              = Report::Entertainment::Boss.new
        @daily_deal_purchase.daily_deal_payment.amount = 50.0
        @daily_deal_purchase.quantity = 2
        assert_equal (25.0).to_s.ljust(6), boss.field(@daily_deal_certificate, 31)
      end

      test "field 32 - purchase amount quantity > 1 messy math" do
        publisher           = Factory.create(:publisher, :listing => "prodcode")
        consumer            = Factory.create(:billing_address_consumer, :publisher => publisher)
        deal                = Factory.create(:daily_deal, :publisher => publisher)
        daily_deal_purchase = Factory.create(:authorized_daily_deal_purchase,
                                             :quantity                     => 3,
                                             :consumer                     => consumer,
                                             :daily_deal                   => deal)
        daily_deal_purchase.daily_deal_payment.amount = 50.0
        daily_deal_purchase.daily_deal_payment.save!
        Factory.create(:daily_deal_certificate, :daily_deal_purchase => daily_deal_purchase, :redeemer_name => "John Q Public")
        Factory.create(:daily_deal_certificate, :daily_deal_purchase => daily_deal_purchase, :redeemer_name => "John Q Public")
        Factory.create(:daily_deal_certificate, :daily_deal_purchase => daily_deal_purchase, :redeemer_name => "John Q Public")
        boss = Report::Entertainment::Boss.new
        csv  = []
        boss.generate_for_publisher(csv, publisher.id)
        assert_equal(3, csv.size)
        assert_equal("16.67".ljust(6), csv[0][31])
        assert_equal("16.67".ljust(6), csv[1][31])
        assert_equal("16.66".ljust(6), csv[2][31])
      end

      test "fields 33-60 - not used or defaults" do
        boss = Report::Entertainment::Boss.new
        assert_equal "".ljust(6), boss.field(@daily_deal_certificate, 32) # unit shipping
        assert_equal "0", boss.field(@daily_deal_certificate, 33) # rush flag
        assert_equal "N", boss.field(@daily_deal_certificate, 34) # continuity
        assert_equal "0", boss.field(@daily_deal_certificate, 35) # backorder
        assert_equal "".ljust(20), boss.field(@daily_deal_certificate, 36) # source id
        assert_equal "N", boss.field(@daily_deal_certificate, 37) # message flag
        assert_equal "".ljust(50), boss.field(@daily_deal_certificate, 38) # message text
        assert_equal "".ljust(15), boss.field(@daily_deal_certificate, 39) # ship to overseas
        assert_equal "".ljust(8), boss.field(@daily_deal_certificate, 40) # tax amount
        assert_equal "".ljust(1), boss.field(@daily_deal_certificate, 41) # filler
        assert_equal "".ljust(8), boss.field(@daily_deal_certificate, 42) # ship tax amount
        assert_equal "".ljust(20), boss.field(@daily_deal_certificate, 43) # site id
        assert_equal "".ljust(30), boss.field(@daily_deal_certificate, 44) # shipping promo
        assert_equal "".ljust(35), boss.field(@daily_deal_certificate, 45) # link id
        assert_equal "".ljust(35), boss.field(@daily_deal_certificate, 46) # entry id
        assert_equal "".ljust(40), boss.field(@daily_deal_certificate, 47) # custom
        assert_equal "".ljust(14), boss.field(@daily_deal_certificate, 48) # filler
        assert_equal "".ljust(13), boss.field(@daily_deal_certificate, 49) # group number
        assert_equal "".ljust(6), boss.field(@daily_deal_certificate, 50) # cc auth code
        assert_equal "".ljust(2), boss.field(@daily_deal_certificate, 51) # cc address verification response
        assert_equal "".ljust(10), boss.field(@daily_deal_certificate, 52) # seller id
        assert_equal "".ljust(22), boss.field(@daily_deal_certificate, 53) # ps2000
        assert_equal "".ljust(1), boss.field(@daily_deal_certificate, 54) # auth source
        assert_equal "".ljust(21), boss.field(@daily_deal_certificate, 55) # gift card number
        assert_equal "".ljust(1), boss.field(@daily_deal_certificate, 56) # gift card status
        assert_equal "".ljust(8), boss.field(@daily_deal_certificate, 57) # gift card activation date
        assert_equal "".ljust(13), boss.field(@daily_deal_certificate, 58) # gift card assoc
        assert_equal "".ljust(50), boss.field(@daily_deal_certificate, 59) # avatax doc ref
      end

      test "fields 61-70 - last batch" do
        boss = Report::Entertainment::Boss.new
        assert_equal @publisher.listing.ljust(10), boss.field(@daily_deal_certificate, 60) # product code
        assert_equal "".ljust(1), boss.field(@daily_deal_certificate, 61) # customer opt in for email
        assert_equal "".ljust(1), boss.field(@daily_deal_certificate, 62) # customer create profile
        assert_equal "".ljust(30), boss.field(@daily_deal_certificate, 63) # usbank 1
        assert_equal "".ljust(40), boss.field(@daily_deal_certificate, 64) # usbank 2
        assert_equal @deal.id.to_s.ljust(12), boss.field(@daily_deal_certificate, 65) # offer id
        assert_equal "N", boss.field(@daily_deal_certificate, 66) # gift indicator
        assert_equal "".ljust(19), boss.field(@daily_deal_certificate, 67) # ip address
        assert_equal "Y", boss.field(@daily_deal_certificate, 68) # privacy acceptance
        assert_equal @daily_deal_certificate.serial_number.to_s.ljust(12), boss.field(@daily_deal_certificate, 69) # serial number
      end

      test "row appears to behave" do
        @daily_deal_certificate.daily_deal_purchase.authorized_purchase_factory_after_create
        boss = Report::Entertainment::Boss.new
        row  = boss.row(@daily_deal_certificate)
        assert_equal 70, row.size
        # spot check a few values
        assert_equal @consumer.last_name.ljust(25), row[1]
        assert_equal @consumer.address_line_2.ljust(50), row[24]
        assert_equal @daily_deal_certificate.serial_number.to_s.ljust(12), row[69]
      end

      test "BOSSCountryCode" do
        us = Report::Entertainment::Boss::BOSSCountryCode.new("US")
        assert_equal "999COU00000001", us.to_s
        ca = Report::Entertainment::Boss::BOSSCountryCode.new("CA")
        assert_equal "999COU00000002", ca.to_s
        foo = Report::Entertainment::Boss::BOSSCountryCode.new("FO")
        assert_equal "FO", foo.to_s
      end

      test "BOSSName simple" do
        name = Report::Entertainment::Boss::BOSSName.new("John Public")
        assert_equal "John", name.first_name
        assert_equal "Public", name.last_name
      end

      test "BOSSName no last means nothing" do
        name = Report::Entertainment::Boss::BOSSName.new("Prince")
        assert_equal "", name.first_name
        assert_equal "", name.last_name
      end

      test "BOSSName middle initial" do
        name = Report::Entertainment::Boss::BOSSName.new("John Q Public")
        assert_equal "John", name.first_name
        assert_equal "Public", name.last_name
      end

      test "BOSSName rubbish means nothing" do
        name = Report::Entertainment::Boss::BOSSName.new("What a bunch of rubbish")
        assert_equal "", name.first_name
        assert_equal "", name.last_name
      end

      test "BOSSName handles nil and empty" do
        name = Report::Entertainment::Boss::BOSSName.new(nil)
        assert_equal "", name.first_name
        assert_equal "", name.last_name
        name = Report::Entertainment::Boss::BOSSName.new("")
        assert_equal "", name.first_name
        assert_equal "", name.last_name
      end

    end
  end
end

