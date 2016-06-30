require File.dirname(__FILE__) + "/../../lib_helper"
require File.dirname(__FILE__) + "/../../../../../../lib/export/newsweek/purchase_export"
require 'ostruct'

# hydra class Export::Newsweek::PurchaseExportTest

module Export
  module Newsweek

    class Country < Struct.new(:name)
      COUNTRIES = {
        "CA" => new("Canada"),
        "US" => new("United States"),
        "UK" => new("United Kingdom"),
        "NA" => new("Not A Real Country")
      }

      def self.find_by_code(code)
        COUNTRIES[code]
      end
    end

    class PurchaseExportTest < Test::Unit::TestCase
      context "purchase export test" do

        context "#write" do

          context "the header" do
            should "output characters 1-3 as 'PCD'" do
              assert_match /^PCD/, export_with_test_data
            end

            should "output characters 4-9 as current UTC date in MMDDYY" do
              Timecop.freeze(Time.zone.parse("December 1, 2010 22:00 PDT")) do
                output = export_with_test_data
                assert_equal "120210", output[3..8]
              end
            end

            should "output characters 10-15 as the daily_deal_purchase count right justified" do
              assert_equal "000000", export_with_test_data[9..14]

              daily_deal_purchases = [dummy_daily_deal_purchase, dummy_daily_deal_purchase]
              assert_equal "000002", export_with_test_data(daily_deal_purchases)[9..14]
            end

            should "output characters 16-25 as the 3rd party publisher name" do
              assert_equal PurchaseExport::THIRD_PARTY_NAME.ljust(10), export_with_test_data[15..24]
            end

            should "output characters 26-1500 as blanks" do
              assert_match /^.{25}\040{1475}/, export_with_test_data
            end

            should "make sure that length is exactly 1500" do
              assert_equal "\n", export_with_test_data[1500..1500]

              daily_deal_purchases = []
              daily_deal_purchases.stubs(:length).returns(10_000_000)

              purchase_export = PurchaseExport.new(StringIO.new, daily_deal_purchases)
              exception = assert_raise RuntimeError do
                purchase_export.write
              end
              assert_equal "Too many purchases. Number of purchases can not exceed 999,999.", exception.message
            end

          end

          context "the rows" do
            setup do
              @report_output = export_with_test_data([dummy_daily_deal_purchase], true)
            end

            should "output characters 1-3 as the Client Code" do
              assert_equal PurchaseExport::CLIENT_CODE, @report_output[0..2]
            end

            should "output characters 4-5 as the publication code" do
              assert_equal PurchaseExport::PUBLICATION_CODE, @report_output[3..4]
            end

            should "output characters 6-11 as order date in MMDDYY" do
              assert_equal "122600", @report_output[5..10]
            end

            should "output characters 12-19 as blanks" do
              assert_equal " " * 8, @report_output[11..18]
            end

            should "output character 20 as the order flag" do
              assert_equal PurchaseExport::ORDER_FLAG, @report_output[19..19]
            end

            should "output characters 21-53 as blanks" do
              assert_equal " " * 33, @report_output[20..52]
            end

            should "output characters 54-60 as the left justified source key" do
              assert_equal PurchaseExport::SOURCE_KEY.ljust(7), @report_output[53..59]
            end

            should "output characters 61-63 as the term" do
              assert_equal PurchaseExport::TERM.to_s.rjust(3, "0"), @report_output[60..62]
            end

            should "output characters 64-70 as the cash value (price * quantity) as price with no decimal point" do
              assert_equal "0010395", @report_output[63..69]
            end

            should "output characters 71-97 as left justified full name" do
              assert_equal dummy_recipient.name.ljust(27), @report_output[70..96]
            end

            should "have a warning if full name is too long" do
              recipient = dummy_recipient(:name => "Jacqueline Wolfeschlegelsteinhausenbergerdorff")
              assert_warning_on_field_length(:recipients, [recipient])
            end

            should "have a warning if full name contains a comma" do
              recipient = dummy_recipient(:name => "Doe, John")
              dummy_purchase = dummy_daily_deal_purchase
              dummy_purchase.stubs(:recipients => [recipient])
              output = StringIO.new
              purchase_export = PurchaseExport.new(output, [dummy_purchase])
              purchase_export.write

              assert_equal 1, purchase_export.warnings.length
              assert_equal "Comma was removed from full name: Doe, John", purchase_export.warnings.first
            end

            should "output characters 98-151 as blanks" do
              assert_equal " " * 54, @report_output[97..150]
            end

            should "output characters 152-178 as address line 1" do
              assert_equal "123 Main Street".ljust(27), @report_output[151..177]
            end

            should "have a warning if address line 1 is too long" do
              recipient = dummy_recipient(:address_line_1 => "12321 NE Bolderwood Arboretum Ornamental Drive")
              assert_warning_on_field_length(:recipients, [recipient])
            end

            should "output characters 179-205 as address line 2" do
              assert_equal "Apartment #4005".ljust(27), @report_output[178..204]
            end

            should "have a warning if address line 2 is too long" do
              recipient = dummy_recipient(:address_line_2 => "Suite 5043, Apartment 953, Sector 72, International Space Station 4")
              assert_warning_on_field_length(:recipients, [recipient])
            end

            should "output characters 206-225 as city" do
              assert_equal "Seattle".ljust(20), @report_output[205..224]
            end

            should "have a warning if city is too long" do
              recipient = dummy_recipient(:city => "Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch")
              assert_warning_on_field_length(:recipients, [recipient])
            end

            should "output characters 226-227 as state/province" do
              assert_equal "WA", @report_output[225..226]
            end

            should "output characters 228-236 as the postal/zip code" do
              assert_equal "98133".ljust(9), @report_output[227..235]
            end

            should "accept 9 digit zip codes" do
              recipient = dummy_recipient(:zip_code => "98133-1231")
              daily_deal_purchases = dummy_daily_deal_purchase(:recipients => [recipient])
              @report_output = export_with_test_data([daily_deal_purchases], true)
              assert_equal "981331231", @report_output[227..235]
            end

            should "accept Canadian postal codes" do
              recipient = dummy_recipient(:zip_code => "K1A 0B1", :country_code => "CA")
              daily_deal_purchases = dummy_daily_deal_purchase(:recipients => [recipient])
              @report_output = export_with_test_data([daily_deal_purchases], true)
              assert_equal "K1A 0B1".ljust(9), @report_output[227..235]
            end

            should "accept UK postal codes" do
              recipient = dummy_recipient(:zip_code => "AA9A 9AA", :country_code => "UK")
              daily_deal_purchases = dummy_daily_deal_purchase(:recipients => [recipient])
              @report_output = export_with_test_data([daily_deal_purchases], true)
              assert_equal "AA9A 9AA".ljust(9), @report_output[227..235]
            end

            should "output characters 237-256 as country" do
              assert_equal " " * 20, @report_output[236..255]
            end

            should "accept Canada as a country" do
              recipient = dummy_recipient(:country_code => "CA")
              daily_deal_purchases = dummy_daily_deal_purchase(:recipients => [recipient])
              @report_output = export_with_test_data([daily_deal_purchases], true)
              assert_equal "CANADA".ljust(20), @report_output[236..255]
            end

            should "accept UK as a country" do
              recipient = dummy_recipient(:country_code => "UK")
              daily_deal_purchases = dummy_daily_deal_purchase(:recipients => [recipient])
              @report_output = export_with_test_data([daily_deal_purchases], true)
              assert_equal "United Kingdom".ljust(20), @report_output[236..255]
            end

            should "have error when country is not supported by format" do
              recipient = dummy_recipient(:country_code => "NA")
              dummy_purchase = dummy_daily_deal_purchase
              dummy_purchase.stubs(:recipients => [recipient])
              output = StringIO.new
              purchase_export = PurchaseExport.new(output, [dummy_purchase])

              exception = assert_raise RuntimeError do
                purchase_export.write
              end
              assert_equal "Country not expected by Newsweek.", exception.message
            end

            should "output characters 257-262 as blanks" do
              assert_equal " " * 6, @report_output[256..261]
            end

            should "output characters 263-272 as zeroes" do
              assert_equal "0" * 10, @report_output[262..271]
            end

            should "output characters 273-491 as blanks" do
              assert_match /^\040{219}$/, @report_output[272..490]
            end

            should "output characters 492-494 as bulk quantity" do
              assert_equal "009", @report_output[491..493]
            end

            should "output characters 495-514 as blanks" do
              assert_match /^\040{20}$/, @report_output[494..513]
            end

            should "output characters 515-603 as blanks" do
              assert_match /^0{89}$/, @report_output[514..602]
            end

            should "output characters 604-653 as email" do
              assert_equal "john.smith@example.com".ljust(50), @report_output[603..652]
            end

            should "have a warning if email is too long" do
              consumer = dummy_consumer(:email => "john.alexander.jones.smith@the.international.space.statation.co.uk")
              assert_warning_on_field_length(:consumer, consumer)
            end

            should "output characters 654-1500 as blanks" do
              assert_match /^\040{847}\n$/, @report_output[653..1501]
            end

          end

          context "purchase with multiple recipients" do
            setup do
              recipients = [
                dummy_recipient(:name => "Bob Smith", :address_line_1 => "828 122nd Ave"),
                dummy_recipient(:name => "Jane Doe", :address_line_1 => "504 Pike St")
              ]
              daily_deal_purchases = [dummy_daily_deal_purchase(:recipients => recipients)]

              report_output = export_with_test_data(daily_deal_purchases, true)
              @rows = report_output.split("\n")
            end

            should "output a row for each recipient" do
              assert_equal 2, @rows.length
            end

            should "output the consumer email for both recipient rows" do
              assert_equal "john.smith@example.com".ljust(50), @rows[0][603..652]
              assert_equal "john.smith@example.com".ljust(50), @rows[1][603..652]
            end

            should "output the recipients respective name and address for each row" do
              assert_equal "Bob Smith".ljust(27), @rows[0][70..96]
              assert_equal "Jane Doe".ljust(27), @rows[1][70..96]

              assert_equal "828 122nd Ave".ljust(27), @rows[0][151..177]
              assert_equal "504 Pike St".ljust(27), @rows[1][151..177]
            end

            should "output bulk quantity as 1 for each row" do
              assert_equal "001", @rows[0][491..493]
              assert_equal "001", @rows[1][491..493]
            end
          end

          context "purchase with no recipients" do
            setup do
              daily_deal_purchases = [dummy_daily_deal_purchase(:recipients => [])]
              @report_output = export_with_test_data(daily_deal_purchases, true)
            end

            should "output bulk quantity as the total quantity for the purchase" do
              assert_equal "009", @report_output[491..493]
            end
          end

          context "purchase with one recipient and quantity > 1" do
            setup do
              daily_deal_purchases = [dummy_daily_deal_purchase(:recipients => [dummy_recipient], :quantity => 3)]
              @report_output = export_with_test_data(daily_deal_purchases, true)
            end

            should "output bulk quantity as the total quantity for the purchase" do
              assert_equal "003", @report_output[491..493]
            end
          end
        end
      end

      private

      def export_with_test_data(daily_deal_purchases = [], omit_header = false)
        output = StringIO.new
        purchase_export = PurchaseExport.new(output, daily_deal_purchases)

        purchase_export.write

        output.rewind
        output.seek(1501) if omit_header
        output.read
      end

      def dummy_daily_deal_purchase(attributes = {})
        stub({
          :price => 11.55,
          :consumer => dummy_consumer,
          :executed_at => Time.zone.parse("December 25, 2000 22:00 PDT"),
          :quantity => 9,
          :recipients => [dummy_recipient]
        }.merge(attributes))
      end

      def dummy_recipient(attributes = {})
        stub({
          :name => "John Doe",
          :address_line_1 => "123 Main Street",
          :address_line_2 => "Apartment #4005",
          :city => "Seattle",
          :state => "WA",
          :zip_code => "98133",
          :country_code => "US"
        }.merge(attributes))
      end

      def dummy_consumer(attributes = {})
        stub({
          :name => "John Doe",
          :email => "john.smith@example.com",
          :address_line_1 => "123 Main Street",
          :address_line_2 => "Apartment #4005",
          :city => "Seattle",
          :state => "WA",
          :zip_code => "98133",
          :country_code => "US"
        }.merge(attributes))
      end

      def assert_warning_on_field_length(key, value)
        dummy_purchase = dummy_daily_deal_purchase
        dummy_purchase.stubs(key => value)

        output = StringIO.new
        purchase_export = PurchaseExport.new(output, [dummy_purchase])

        purchase_export.write

        assert_equal 1, purchase_export.warnings.length
        assert_match /^Field was \d+ characters/, purchase_export.warnings.first
      end
    end
  end
end
