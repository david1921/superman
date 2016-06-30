require File.dirname(__FILE__) + "/../../../test_helper"
require File.dirname(__FILE__) + '/../entertainment_setup'

# hydra class Report::Entertainment::DealEmailFileTest
module Report
  module Entertainment

    class DealEmailFileTest < ActiveSupport::TestCase

      include Report::EntertainmentSetup

      context "with big setup" do
        setup do
          entertainment_setup
        end

        context "#generate_deal_email_file" do
          setup do
            @csv = []
          end

          fast_context "for entire publishing group" do
            setup do
              Report::Entertainment.generate_deal_email_file(@entertainment, @csv)
              @john_index = row_index_for_consumer(@john_detroit)
              @fred_index = row_index_for_consumer(@fred_fortworth)
            end

            should "generate 5 rows" do
              assert_equal 5, @csv.size
            end

            should "have correct column indexes" do
              assert_equal 0, DealEmailFile.index_of_column_name("EMAIL")
              assert_equal 10, DealEmailFile.index_of_column_name("FIRSTNAME")
            end

            should "capitalize the email" do
              (1..4).each do |i|
                assert_no_match /[a-z]/, DealEmailFile.value_of_field_for_row("EMAIL", @csv, i)
              end
            end

            should "have the city for TESTSEGMENT" do
              assert_equal "Detroit", DealEmailFile.value_of_field_for_row("TESTSEGMENT", @csv, @john_index)
            end

            should "have the merchant fields populated" do
              assert_equal "Detroit", DealEmailFile.value_of_field_for_row("MERCHANTCITY1", @csv, @john_index)
              assert_equal "MI", DealEmailFile.value_of_field_for_row("MERCHANTSTATE1", @csv, @john_index)
              assert_equal "detroit addr line 1", DealEmailFile.value_of_field_for_row("MERCHANTADDRESS1", @csv, @john_index)
              assert_equal "99999", DealEmailFile.value_of_field_for_row("MERCHANTZIPCODE1", @csv, @john_index)
            end

            should "not have the 2nd merchant fields populated (for now)" do
              assert_equal "", DealEmailFile.value_of_field_for_row("MERCHANTCITY2", @csv, @john_index)
              assert_equal "", DealEmailFile.value_of_field_for_row("MERCHANTSTATE2", @csv, @john_index)
              assert_equal "", DealEmailFile.value_of_field_for_row("MERCHANTADDRESS2", @csv, @john_index)
              assert_equal "", DealEmailFile.value_of_field_for_row("MERCHANTZIPCODE2", @csv, @john_index)
            end

            should "Y for multilocation flag when multiple stores and N when one store" do
              assert_equal "JOHN@HELLO.COM", DealEmailFile.value_of_field_for_row("EMAIL", @csv, @john_index)
              assert_equal "Y", DealEmailFile.value_of_field_for_row("MERCHANTMULTILOCATIONFLAG", @csv, @john_index)

              assert_equal "FRED@HELLO.COM", DealEmailFile.value_of_field_for_row("EMAIL", @csv, @fred_index)
              assert_equal "N", DealEmailFile.value_of_field_for_row("MERCHANTMULTILOCATIONFLAG", @csv, @fred_index)
            end

            should "be ok when there is no merchant" do
              assert_equal "FRED@HELLO.COM", DealEmailFile.value_of_field_for_row("EMAIL", @csv, @fred_index)
              assert_equal "", DealEmailFile.value_of_field_for_row("MERCHANTCITY2", @csv, @fred_index)
              assert_equal "", DealEmailFile.value_of_field_for_row("MERCHANTSTATE2", @csv, @fred_index)
              assert_equal "", DealEmailFile.value_of_field_for_row("MERCHANTADDRESS2", @csv, @fred_index)
              assert_equal "", DealEmailFile.value_of_field_for_row("MERCHANTZIPCODE2", @csv, @fred_index)
            end

            should "weirdly named url to deal field" do
              assert_equal "http://deals.entertainment.com/daily_deals/#{@detroit_deal.id}",
                           DealEmailFile.value_of_field_for_row("ENDECAKEY1", @csv, @john_index)
            end

            should "format money fields as money" do
              assert_equal "JOHN@HELLO.COM", DealEmailFile.value_of_field_for_row("EMAIL", @csv, @john_index)
              assert_equal "$15.00", DealEmailFile.value_of_field_for_row("PRODUCTPRICE", @csv, @john_index)
              assert_equal "$15.00", DealEmailFile.value_of_field_for_row("PRODUCTPROMOPRICE", @csv, @john_index)
              assert_equal "$30.00", DealEmailFile.value_of_field_for_row("OFFERUPTOVALUE1", @csv, @john_index)
            end

            should "format percentage fields as a percentage" do
              assert_equal "JOHN@HELLO.COM", DealEmailFile.value_of_field_for_row("EMAIL", @csv, @john_index)
              assert_equal "50%", DealEmailFile.value_of_field_for_row("PRODUCTTOTALVALUE", @csv, @john_index)
            end

            should "truncate output column values" do
              assert_equal "J"*50, DealEmailFile.value_of_field_for_row("FIRSTNAME", @csv, @john_index)
            end

          end

          should "filter by publisher label" do
            Report::Entertainment.generate_deal_email_file(@entertainment, @csv, ["detroit"])
            assert_equal 3, @csv.size
          end

          should "filter out signups with no matching deal" do
            @fred_fortworth.city = "Mexico City Where There Are No Deals"
            @fred_fortworth.save!
            signups            = @entertainment.signups
            deals_by_city      = @entertainment.todays_deals_by_publisher_label
            csv = []
            Report::Entertainment.generate_deal_email_file(@entertainment, csv)
            assert_nil csv.detect { |row| row.grep(%r{@fred_fortworth.email}).any? }
          end

        end

        context "#deals_by_publisher_label" do
          context "three featured deals today (first 5 mins, last 5 mins, and in between)" do
            setup do
              @start_of_day = (@detroit_publisher.now - 1.year).beginning_of_day # avoid conflict with deal from setup
              Timecop.freeze(@start_of_day) do
                now = @detroit_publisher.now
                @featured_first_5 = Factory(:featured_daily_deal, :advertiser => @detroit_advertiser, :start_at => now - 1.day + 5.minutes, :hide_at => now + 5.minutes)
                @featured_most_of_day = Factory(:featured_daily_deal, :advertiser => @detroit_advertiser, :start_at => now + 5.minutes, :hide_at => now.end_of_day - 5.minutes)
                @featured_last_5 = Factory(:featured_daily_deal, :advertiser => @detroit_advertiser, :start_at => now.end_of_day - 5.minutes, :hide_at => now + 1.day - 5.minutes)
              end
            end

            should "include the featured deal, not a side deal" do
              Timecop.freeze(@start_of_day + 3.hours) do # when Entertainment cron runs for EST
                email_file = Report::Entertainment::DealEmailFile.new(@entertainment, [@detroit_publisher.label])
                assert_equal @featured_most_of_day.id, email_file.deals_by_publisher_label[@detroit_publisher.label][:deal_id]
              end
            end
          end

          context "featured deals today, but none right now" do
            setup do
              @start_of_day = (@detroit_publisher.now - 1.year).beginning_of_day # avoid conflict with deal from setup
              Timecop.freeze(@start_of_day) do
                now = @detroit_publisher.now
                @featured_first_5 = Factory(:featured_daily_deal, :advertiser => @detroit_advertiser, :start_at => now - 1.day + 5.minutes, :hide_at => now + 5.minutes)
                @featured_last_5 = Factory(:featured_daily_deal, :advertiser => @detroit_advertiser, :start_at => now.end_of_day - 5.minutes, :hide_at => now + 1.day - 5.minutes)
              end
            end

            should "include the featured deal, not a side deal" do
              Timecop.freeze(@start_of_day + 3.hours) do # when Entertainment cron runs for EST
                email_file = Report::Entertainment::DealEmailFile.new(@entertainment, [@detroit_publisher.label])
                assert_nil email_file.deals_by_publisher_label[@detroit_publisher.label]
              end
            end
          end
        end

        should "truncate description field" do
          rows                      = []
          textiled_paragraph        = "hello\n\n"
          @detroit_deal.description = textiled_paragraph * 85
          @detroit_deal.save!
          assert_equal ("<p>hello</p>\n" * 85).chomp, @detroit_deal.description
          actual = HtmlTruncator.truncate_html(@detroit_deal.description, 960)
          assert_equal 79, actual.count("h")
          assert actual.length <= 960
          assert_equal ("<p>hello</p>" * 79).chomp + "...", actual
          generator = DealEmailFile.new(@entertainment)
          generator.generate_deal_email_file(rows)
          john_index = row_index_for_consumer(@john_detroit, rows)
          assert_equal ("<p>hello</p>" * 79).chomp + "...", DealEmailFile.value_of_field_for_row("OFFERCOPYLONG1", rows,
                                                                                                 john_index)
        end

        should "deals by publisher" do
          assert_equal 4, @entertainment.daily_deals.size
          deals_by_publisher = DealEmailFile.new(@entertainment).deals_by_publisher_label
          assert_equal 3, deals_by_publisher.keys.size, "Unlaunched publishers should be filtered out"
          assert_equal @detroit_deal.id, deals_by_publisher[@detroit_publisher.label][:deal_id]
          assert_equal @dallas_deal.id, deals_by_publisher[@dallas_publisher.label][:deal_id]
          assert_equal @fortworth_deal.id, deals_by_publisher[@fortworth_publisher.label][:deal_id]
        end

        should "blend records to fill in missing values" do
          rows      = []
          @john_subscriber = Factory(:subscriber, :publisher=>@detroit_publisher, :email => @john_detroit.email, :first_name => "Henry")
          @john_detroit.first_name = nil
          @john_detroit.save!
          generator = DealEmailFile.new(@entertainment)
          generator.generate_deal_email_file(rows)
          john_index = row_index_for_consumer(@john_detroit, rows)
          assert_equal "Henry", DealEmailFile.value_of_field_for_row("FIRSTNAME", rows, john_index)
        end

        should "use publisher city if signup's city is blank" do
          generator = DealEmailFile.new(@entertainment)
          @don_dallas.city = nil
          assert_equal "Dallas", generator.signup_hash_from_signup(@dallas_publisher, @don_dallas, {})[:city]
        end

      end

      should "clean file value cleans tab as well as newline and pipe which is delim" do
        assert_equal "foobar__foo__bar__", DealEmailFile.clean_field_value("\tfoo\tb|||ar__\tfoo__|bar__\n\n")
      end

      private

      def row_index_for_consumer(consumer, rows=@csv)
        email_column_index = DealEmailFile.index_of_column_name("EMAIL")
        email = consumer.email.upcase
        rows.each_with_index do |row, i|
          return i if row[email_column_index] == email
        end
        raise "#{email} does not exist in csv file"
      end

    end
  end
end
