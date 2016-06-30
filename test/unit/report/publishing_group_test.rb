require File.dirname(__FILE__) + "/../../test_helper"
require File.dirname(__FILE__) + '/entertainment_setup'

class PublishingGroupTest < ActiveSupport::TestCase

  include Report::EntertainmentSetup

  setup :entertainment_setup

  test "setup" do
    assert_equal 2, @detroit_publisher.signups.size
    assert_equal 1, @fortworth_publisher.signups.size
    assert_equal 1, @dallas_publisher.signups.size
  end

  test "can get all deals for all launched publishers in a group" do
    assert_equal [@detroit_deal, @dallas_deal, @fortworth_deal], @entertainment.todays_deals
  end

  test "deals can be grouped by city" do
    deals_by_city = @entertainment.todays_deals_by_city
    assert_equal [@detroit_deal], deals_by_city["Detroit"]
    assert_equal [@dallas_deal], deals_by_city["Dallas"]
    assert_equal [@fortworth_deal], deals_by_city["Fort Worth"]
  end

  test "signups across publishing group" do
    assert_equal ["don@hello.com", "fred@hello.com", "jill@hello.com", "john@hello.com"], @entertainment.signups.map {|s| s["email"]}.sort
  end

  test "to_csv methods don't raise exceptions" do
    assert @entertainment.advertisers_to_csv([]), "advertisers_to_csv"
    assert @entertainment.consumers_to_csv([]), "consumers_to_csv"
    assert @entertainment.daily_deal_certificates_to_csv([]), "daily_deal_certificates_to_csv"
    assert @entertainment.daily_deal_purchases_to_csv([]), "daily_deal_purchases_to_csv"
    assert @entertainment.daily_deal_revenue_to_csv([]), "daily_deal_revenue_to_csv"
    assert @entertainment.daily_deals_to_csv([]), "daily_deals_to_csv"
    assert @entertainment.subscribers_to_csv([]), "subscribers_to_csv"
  end

  test "active discounts to csv simple case" do
    publisher = Factory(:publisher)
    discount = Factory(:usable_discount, :publisher => publisher, :amount => 13.45)
    consumer = Factory(:consumer, :publisher => publisher, :signup_discount => discount)
    assert_not_nil consumer.signup_discount, "The consumer should have a signup discount"
    csv = []
    expected = [[consumer.created_at.to_s, consumer.name, consumer.email, discount.amount.to_s]]
    publisher.publishing_group.active_discounts_to_csv(csv)
    assert_equal expected, csv
  end

  test "active discounts to csv multiple publishers in the publishing_group" do
    discounts = []
    consumers = []
    publishing_group = Factory(:publishing_group)
    3.times do |i|
      publisher = Factory(:publisher, :publishing_group => publishing_group)
      discount = Factory(:usable_discount, :publisher => publisher, :amount => (13.45 * (i + 1)))
      consumer = Factory(:consumer, :publisher => publisher, :signup_discount => discount)
      discounts << discount
      consumers << consumer
    end
    csv = []
    expected = []
    3.times do |i|
      expected << [consumers[i].created_at.to_s, consumers[i].name, consumers[i].email, discounts[i].amount.to_s]
    end
    publishing_group.active_discounts_to_csv(csv)
    assert_equal expected, csv
  end

  test "active discounts to csv ignores soft_deleted discounts" do
    publisher = Factory(:publisher)
    discount = Factory(:usable_discount, :publisher => publisher, :amount => 13.45)
    consumer = Factory(:consumer, :publisher => publisher, :signup_discount => discount)
    soft_deleted_discount = Factory(:soft_deleted_discount, :publisher => publisher)
    Factory(:consumer, :publisher => publisher, :signup_discount => soft_deleted_discount)
    assert_not_nil consumer.signup_discount, "The consumer should have a signup discount"
    csv = []
    expected = [[consumer.created_at.to_s, consumer.name, consumer.email, discount.amount.to_s]]
    publisher.publishing_group.active_discounts_to_csv(csv)
    assert_equal expected, csv
  end

  test "active discounts to csv ignores expired discounts" do
    publisher = Factory(:publisher)
    discount = Factory(:usable_discount, :publisher => publisher, :amount => 13.45)
    consumer = Factory(:consumer, :publisher => publisher, :signup_discount => discount)
    expired_discount = Factory(:expired_discount, :publisher => publisher)
    assert !expired_discount.usable?
    Factory(:consumer, :publisher => publisher, :signup_discount => expired_discount)
    assert_not_nil consumer.signup_discount, "The consumer should have a signup discount"
    csv = []
    expected = [[consumer.created_at.to_s, consumer.name, consumer.email, discount.amount.to_s]]
    publisher.publishing_group.active_discounts_to_csv(csv)
    assert_equal expected, csv
  end

  context "#daily_deal_certificates_to_csv" do
    setup do
      @daily_deal_certificate1  = Factory(:daily_deal_certificate)
      @consumer                 = Factory(:consumer,
                                          :publisher => @daily_deal_certificate1.publisher)
      @daily_deal               = Factory(:side_daily_deal,
                                          :advertiser => @daily_deal_certificate1.advertiser)
      @daily_deal_purchase      = Factory(:authorized_daily_deal_purchase,
                                          :consumer => @consumer,
                                          :daily_deal => @daily_deal)
      @daily_deal_certificate2  = Factory(:daily_deal_certificate,
                                          :daily_deal_purchase => @daily_deal_purchase)
      @publishing_group         = @daily_deal_certificate1.publisher.publishing_group
    end

    should "get all daily deal certificates for a publishing group" do
      csv = []
      @publishing_group.daily_deal_certificates_to_csv(csv)
      assert_equal csv.length, 3
      assert_equal csv.first,  ["ID", "Daily Deal Purchase ID", "Purchaser", "Recipient",
                                "Serial Number", "Redeemed On", "Redeemed At", "Deal",
                                "Value", "Price", "Purchase Price", "Purchase Date"]
      assert_equal csv[1][0], @daily_deal_certificate1.id
      assert_equal csv[2][0], @daily_deal_certificate2.id
    end

    should "allow ActiveRecord#find options to be used" do
      csv = []
      @daily_deal_certificate1.redeem!
      @daily_deal_certificate2.update_attribute(:redeemed_at, 2.weeks.ago)
      @publishing_group.daily_deal_certificates_to_csv(csv, ["redeemed_at > ?", 1.week.ago])
      assert_equal csv.length, 2
    end
  end

  test "generate consumers list with no consumers or subscribers" do
    publishing_group = publishing_groups(:student_discount_handbook)
    publishing_group.publishers.each { |publisher| publisher.subscribers.destroy_all; publisher.consumers.delete_all }

    publishing_group.generate_consumers_list_lang_style(csv = [])

    assert_equal 1, csv.size, "Should only have title row"
    assert_equal ["First Name", "Last Name", "Email", "Student Discount Handbook Austin", "Student Discount Handbook Boulder"], csv[0]
  end

  test "generate consumers list with publisher bitmap with consumers activated" do
    publishing_group = publishing_groups(:student_discount_handbook)
    consumer = publishers(:sdh_boulder).consumers.create!(
      :name => "Jack Public",
      :email => "jack@public.com",
      :password => "secret",
      :password_confirmation => "secret",
      :agree_to_terms => "1"
    )
    consumer.activate!

    publishing_group.generate_consumers_list_lang_style(csv = [])

    assert_equal 4, csv.size, "Should have title row and three consumers"
    assert_equal ["First Name", "Last Name", "Email", "Student Discount Handbook Austin", "Student Discount Handbook Boulder"], csv[0]
    assert_equal ["John", "Public", "john@public.com", 1, 0], csv[1]
    assert_equal ["Jane", "Public", "jane@public.com", 1, 0], csv[2]
    assert_equal ["Jack", "Public", "jack@public.com", 0, 1], csv[3]
  end

  test "generate consumers list with publisher bitmap subscribers" do
    publishing_group = publishing_groups(:student_discount_handbook)
    publishing_group.publishers.each { |publisher| publisher.consumers.delete_all }

    publishers(:sdh_austin).subscribers.create!(:email => "john@public.com")
    publishers(:sdh_austin).subscribers.create!(:email => "jane@public.com")
    publishers(:sdh_boulder).subscribers.create!(:email => "jack@public.com")

    publishing_group.generate_consumers_list_lang_style(csv = [])

    assert_equal 4, csv.size, "Should have title row and three consumers"
    assert_equal ["First Name", "Last Name", "Email", "Student Discount Handbook Austin", "Student Discount Handbook Boulder"], csv[0]
    csv = csv.sort_by { |row| row[2] }
    assert_equal [nil, nil, "jack@public.com", 0, 1], csv[1]
    assert_equal [nil, nil, "jane@public.com", 1, 0], csv[2]
    assert_equal [nil, nil, "john@public.com", 1, 0], csv[3]
  end

  test "generate consumers list with publisher bitmap and consumers and subscribers that overlap" do
    publishing_group = publishing_groups(:student_discount_handbook)

    publishers(:sdh_austin).subscribers.create!(:email => "john@public.com")
    publishers(:sdh_boulder).subscribers.create!(:email => "jack@public.com")

    publishing_group.generate_consumers_list_lang_style(csv = [])

    assert_equal 4, csv.size, "Should have title row and three consumers"
    assert_equal ["First Name", "Last Name", "Email", "Student Discount Handbook Austin", "Student Discount Handbook Boulder"], csv[0]
    assert_equal ["John", "Public", "john@public.com", 1, 0], csv[1]
    assert_equal ["Jane", "Public", "jane@public.com", 1, 0], csv[2]
    assert_equal [nil, nil, "jack@public.com", 0, 1], csv[3]
  end

  test "generate consumers list with publisher bitmap and with consumers and subscribers that overlap and belong to multiple publishers" do
    publishing_group = publishing_groups(:student_discount_handbook)

    publishers(:sdh_austin).subscribers.create!(:email => "john@public.com")
    publishers(:sdh_boulder).subscribers.create!(:email => "john@public.com")
    publishers(:sdh_boulder).subscribers.create!(:email => "jack@public.com")

    publishing_group.generate_consumers_list_lang_style(csv = [])

    assert_equal 4, csv.size, "Should have title row and three consumers"
    assert_equal ["First Name", "Last Name", "Email", "Student Discount Handbook Austin", "Student Discount Handbook Boulder"], csv[0]
    assert_equal ["John", "Public", "john@public.com", 1, 1], csv[1]
    assert_equal ["Jane", "Public", "jane@public.com", 1, 0], csv[2]
    assert_equal [nil, nil, "jack@public.com", 0, 1], csv[3]
  end

  test "generate consumers list with with publisher bitmap and consumers and subscribers that overlap and publisher selection" do
    publishing_group = publishing_groups(:student_discount_handbook)

    publishers(:sdh_austin).subscribers.create!(:email => "john@public.com")
    publishers(:sdh_boulder).subscribers.create!(:email => "jack@public.com")

    publishing_group.generate_consumers_list_lang_style(csv = [], :publisher_labels => %w{ mysdh-austin })

    assert_equal 3, csv.size, "Should have title row and three consumers"
    assert_equal ["First Name", "Last Name", "Email", "Student Discount Handbook Austin"], csv[0]
    assert_equal ["John", "Public", "john@public.com", 1], csv[1]
    assert_equal ["Jane", "Public", "jane@public.com", 1], csv[2]
  end

  test "todays_deals_by_publisher_label entertainment" do
    unlaunched_publisher = Factory(:publisher, :publishing_group => @entertainment, :launched => false)
    unlaunched_advertiser = Factory(:advertiser, :publisher => unlaunched_publisher)
    ulaunched_but_active_deal = Factory(:daily_deal, :advertiser => unlaunched_advertiser, :start_at => Time.now.beginning_of_day, :hide_at => Time.now.end_of_day)
    deals_by_publisher = @entertainment.todays_deals_by_publisher_label
    assert_equal 3, deals_by_publisher.size
    assert_equal 1, deals_by_publisher[@detroit_publisher.label].size
    assert_equal 1, deals_by_publisher[@dallas_publisher.label].size
    assert_equal 1, deals_by_publisher[@fortworth_publisher.label].size
    assert_equal "detroit deal", deals_by_publisher[@detroit_publisher.label][0].short_description
    assert_equal "dallas deal", deals_by_publisher[@dallas_publisher.label][0].short_description
    assert_equal "fortworth deal", deals_by_publisher[@fortworth_publisher.label][0].short_description
  end

  context "generate_consumers_list" do

    setup do
      @publishing_group = Factory(:publishing_group)
      @publisher1 = Factory(:publisher, :publishing_group => @publishing_group, :label => "publisher1", :name => "Publisher 1")
      @publisher2 = Factory(:publisher, :publishing_group => @publishing_group, :label => "publisher2", :name => "Publisher 2")
      @csv = []
    end

    context "no signups" do
      should "have header" do
        @publishing_group.generate_consumers_list(@csv)
        assert_equal [%w{status email name subject}], @csv
      end

      should "have no header" do
        @publishing_group.generate_consumers_list(@csv, :include_header => false)
        assert_equal [], @csv
      end

      should "have default columns if nil is passed for columns" do
        @publishing_group.generate_consumers_list(@csv, :include_header => true, :columns => nil)
        assert_equal [%w{status email name subject}], @csv
      end
    end

    context "with signups" do

      setup do
        @consumer1 = Factory(:consumer, :publisher => @publisher1, :email => "consumer1@email.com")
        @consumer2 = Factory(:consumer, :publisher => @publisher2, :email => "consumer2@email.com")
        I18n.locale = :es
        @subscriber1 = Factory(:subscriber, :publisher => @publisher1, :email => "subscriber1@email.com")
        I18n.locale = :en
      end

      should "have signups from all publishers in the group" do
        @publishing_group.generate_consumers_list(@csv, :columns => ["email"])
        assert_equal [["email"], ["consumer1@email.com"], ["subscriber1@email.com"], ["consumer2@email.com"]], @csv
      end

      should "respect publisher labels" do
        @publishing_group.generate_consumers_list(@csv, :publisher_labels => ["publisher2"], :columns => ["email"])
        assert_equal [["email"], ["consumer2@email.com"]], @csv
      end

      should "include publisher_bitmap if requested" do
        @publishing_group.generate_consumers_list(@csv, :columns => ["email"], :include_publisher_bitmap => true)
        assert_equal [
                      ["email", "Publisher 1", "Publisher 2"],
                      ["consumer1@email.com", 1, 0],
                      ["subscriber1@email.com", 1, 0],
                      ["consumer2@email.com", 0, 1]
                     ], @csv
      end

      should "include preferred_locale if requested" do
        @publishing_group.generate_consumers_list(@csv, :columns => ["email", "preferred_locale"])
        assert_equal [
                      ["email", "preferred_locale"],
                      ["consumer1@email.com", "en"],
                      ["subscriber1@email.com", "es"],
                      ["consumer2@email.com", "en"]
                     ], @csv
      end
    end

    context "with duplicate signups" do
      setup do
        @consumer1 = Factory(:consumer, :publisher => @publisher1, :email => "consumer1@email.com")
        @consumer2 = Factory(:consumer, :publisher => @publisher2, :email => "consumer1@email.com")
      end
      should "raise an exception if de-duping is required but email is not a column" do
        assert_raise ArgumentError do
          @publishing_group.generate_consumers_list(@csv, :columns => ["first_name"], :allow_duplicates => false)
        end
      end
      should "de-dup on email" do
        @publishing_group.generate_consumers_list(@csv, :columns => ["email"])
        assert_equal [["email"], ["consumer1@email.com"]], @csv
      end
      should "do not de-dup if duplicates=true" do
        @publishing_group.generate_consumers_list(@csv, :columns => ["email"], :allow_duplicates => true)
        assert_equal [["email"], ["consumer1@email.com"], ["consumer1@email.com"]], @csv
      end
      should "include publisher_bitmap if requested" do
        @publishing_group.generate_consumers_list(@csv, :columns => ["email"], :include_publisher_bitmap => true)
        assert_equal [["email", "Publisher 1", "Publisher 2"], ["consumer1@email.com", 1, 1]], @csv
      end
    end

  end

  context "generate_consumers_totals_list" do
    setup do
      @publishing_group = Factory(:publishing_group)
      @publisher1 = Factory(:publisher, :publishing_group => @publishing_group, :name => "Publisher 1")
      @publisher2 = Factory(:publisher, :publishing_group => @publishing_group, :name => "Publisher 2")
      @csv = []
    end

    should "have counts of 0 when there are no signups" do
      @publishing_group.generate_consumers_totals_list(@csv)
      assert_equal 2, @csv.length
      assert_equal ["Publisher 1", 0], @csv[0]
      assert_equal ["Publisher 2", 0], @csv[1]
    end

    context "with signups" do
      setup do
        # make some signups in date range
        Timecop.freeze(Time.zone.local(2010, 10, 4, 4, 6, 8)) do
          Factory(:consumer, :publisher => @publisher1)
          Factory(:subscriber, :publisher => @publisher1)
          Factory(:consumer, :publisher => @publisher2)
        end
        # make a signups outside of date range
        Timecop.freeze(Time.zone.local(2010, 10, 5, 4, 6, 8)) do
          Factory(:consumer, :publisher => @publisher1)
        end
      end

      should "count all signups when no date range is given" do
        @publishing_group.generate_consumers_totals_list(@csv)
        assert_equal 2, @csv.length
        assert_equal ["Publisher 1", 3], @csv[0]
        assert_equal ["Publisher 2", 1], @csv[1]
      end

      should "count only signups within a given date range" do
        dates = Time.zone.local(2010, 10, 4, 0, 0, 0) .. Time.zone.local(2010, 10, 5, 0, 0, 0)
        @publishing_group.generate_consumers_totals_list(@csv, :date_range => dates)

        assert_equal 2, @csv.length
        assert_equal ["Publisher 1", 2], @csv[0]
        assert_equal ["Publisher 2", 1], @csv[1]
      end

      should "have counts of 0 when there are no signups in the given date range" do
        dates = Time.zone.local(2010, 10, 2, 0, 0, 0) .. Time.zone.local(2010, 10, 3, 0, 0, 0)
        @publishing_group.generate_consumers_totals_list(@csv, :date_range => dates)

        assert_equal 2, @csv.length
        assert_equal ["Publisher 1", 0], @csv[0]
        assert_equal ["Publisher 2", 0], @csv[1]
      end
    end
  end

  context "signups_for_cities for publishing group with subscribers and consumers in several cities" do
    setup do
      @publishing_group = Factory(:publishing_group)

      @houston_publisher = Factory(:publisher, {
        :publishing_group => @publishing_group,
        :address_line_1 => "123 Main Street",
        :city => "Houston",
        :state => "TX",
        :zip => "77001"
      })
      Factory(:consumer, :publisher => @houston_publisher, :email => "consumer1@houston.com", :first_name => "Bif", :zip_code => "77004")
      Factory(:consumer, :publisher => @houston_publisher, :email => "consumer2@houston.com", :first_name => "Tim")

      @chicago_publisher = Factory(:publisher, {
        :publishing_group => @publishing_group,
        :address_line_1 => "123 Main Street",
        :city => "Chicago",
        :state => "IL",
        :zip => "60601"
      })
      Factory(:subscriber, {
        :publisher => @chicago_publisher,
        :email => "consumer1@chicago.com",
        :first_name => "Tom",
        :zip_code => "60611",
        :city => "Chicago"
      })

      @detroit_publisher = Factory(:publisher, {
        :publishing_group => @publishing_group,
        :address_line_1 => "123 Main Street",
        :city => "Detroit",
        :state => "MI",
        :zip => "48201"
      })
      Factory(:consumer, :publisher => @detroit_publisher, :email => "consumer1@detroit.com", :first_name => "Pip", :state => "MI")

    end

    should "include everyone in selected cities" do
      expected_signups = [{
        :email => "consumer1@chicago.com",
        :first_name => "Tom",
        :city => "Chicago",
        :state => "",
        :zip_code => "60611"
      }, {
        :email => "consumer1@houston.com",
        :first_name => "Bif",
        :city => "Houston",
        :zip_code => "77004",
        :state => ""
      }, {
        :email => "consumer2@houston.com",
        :first_name => "Tim",
        :city => "Houston",
        :zip_code => "",
        :state => ""
      }].sort_by { |signup| signup[:email] }

      assert_equal expected_signups, @publishing_group.signups_for_cities(["Houston", "Chicago", "UnliveCity"]).sort_by { |signup| signup[:email] }
    end

    should "select subscriber when city is padded with blanks" do
      Factory(:subscriber, {
        :publisher => @chicago_publisher,
        :email => "consumer2@chicago.com",
        :first_name => "Pat",
        :zip_code => "60600",
        :city => "Chicago "
      })
      expected_signups = [{
        :email => "consumer1@chicago.com",
        :first_name => "Tom",
        :city => "Chicago",
        :state => "",
        :zip_code => "60611"
      }, {
        :email => "consumer2@chicago.com",
        :first_name => "Pat",
        :city => "Chicago",
        :state => "",
        :zip_code => "60600"
      }].sort_by { |signup| signup[:email] }

      assert_equal expected_signups, @publishing_group.signups_for_cities(["Chicago", "UnliveCity"]).sort_by { |signup| signup[:email] }
    end

    should "select subscriber with requested city when owned by a publisher in a different city" do
      Factory(:subscriber, {
        :publisher => @houston_publisher,
        :email => "consumer2@chicago.com",
        :first_name => "Pat",
        :zip_code => "60600",
        :city => "Chicago"
      })
      expected_signups = [{
        :email => "consumer1@chicago.com",
        :first_name => "Tom",
        :city => "Chicago",
        :state => "",
        :zip_code => "60611"
      }, {
        :email => "consumer2@chicago.com",
        :first_name => "Pat",
        :city => "Chicago",
        :state => "",
        :zip_code => "60600"
      }].sort_by { |signup| signup[:email] }

      assert_equal expected_signups, @publishing_group.signups_for_cities(["Chicago", "UnliveCity"]).sort_by { |signup| signup[:email] }
    end

    should "use consumer attributes first when a subscriber exists with the same email" do
      Factory(:consumer, {
        :publisher => @chicago_publisher,
        :email => "consumer1@chicago.com",
        :first_name => "Thomas",
        :state => "IL"
      })
      expected_signups = [{
        :email => "consumer1@chicago.com",
        :first_name => "Thomas",
        :city => "Chicago",
        :state => "IL",
        :zip_code => "60611"
      }].sort_by { |signup| signup[:email] }

      assert_equal expected_signups, @publishing_group.signups_for_cities(["Chicago", "UnliveCity"]).sort_by { |signup| signup[:email] }
    end
  end

  context "#daily_deal_purchases_to_csv" do
    setup do
      @columns = %w{
        consumer_id email listing merchant_id aa_merchant_id market
        payment_status advertiser_name created_at refund_amount quantity
        gross_price credit_used executed_at refunded_at recipient_names
        actual_purchase_price gift redeemed_at serial_number origin_name
      }

      @publishing_group = Factory(:publishing_group)
      @daily_deal = Factory(:daily_deal, :publisher => Factory(:publisher, :publishing_group => @publishing_group))
      @authorized_purchases = (1..2).inject([]) do |arr, i|
        arr << Factory(:authorized_daily_deal_purchase, :daily_deal => @daily_deal)
      end
      @pending_purchases = (1..2).inject([]) do |arr, i|
        arr << Factory(:daily_deal_purchase, :daily_deal => @daily_deal)
      end
    end

    should "have the correct column headers" do
      @publishing_group.daily_deal_purchases_to_csv(results = [])
      assert_equal @columns.map(&:titleize), results[0] # assert result headers
    end

    should "have data that matches the column headers" do
      @publishing_group.daily_deal_purchases_to_csv(results = [])

      ddp = @authorized_purchases.first.reload # get rid of sub-second accuracy of time attributes (MySQL datetime is accurate to a second)
      daily_deal = ddp.daily_deal
      row = results[1]

      @columns.each_with_index do |column, i|
        assert_equal case column.intern
                       when :email
                         ddp.consumer.send(column.intern)
                       when :listing
                         daily_deal.send(column.intern)
                       when :merchant_id
                         daily_deal.advertiser.merchant_id
                       when :aa_merchant_id
                         daily_deal.advertiser_id
                       when :market
                         daily_deal.publisher.market_name_or_city
                       when :advertiser_name
                         daily_deal.advertiser.name
                       when :redeemed_at
                         ddp.daily_deal_certificates.map(&:redeemed_at).join(',')
                       when :recipient_names
                         ddp.recipient_names.try(:join, ',')
                       when :serial_number
                         ddp.daily_deal_certificates.map(&:serial_number).join(',')
                       else
                         ddp.send(column.intern) # consumer_id, payment_status, created_at, refund_amount, quantity,
                                                 # gross_price, credit_used, executed_at, refunded_at, actual_purchase_price, gift
                     end, row[i], column.titleize
      end
    end

    should "not include another publishing group's' purchases" do
      assert_no_difference "@publishing_group.daily_deal_purchases_to_csv(csv = []).size" do
        Factory(:authorized_daily_deal_purchase)
      end
    end

    should "include off-platform purchases" do
      purchase = Factory(:off_platform_daily_deal_purchase, :daily_deal => @daily_deal)
      purchase.capture!
      @publishing_group.daily_deal_purchases_to_csv(results = [])
      results = results.sort_by(&:last)
      row = results.last
      assert_equal purchase.api_user.name, row[20]
    end

    context "payment status updated within specified time period" do
      setup do
        @start = 24.hours.ago
        @end = Time.zone.now
        @too_old = Factory(:authorized_daily_deal_purchase, :daily_deal => @daily_deal, :payment_status_updated_at => @start - 1.day)
        @too_new = Factory(:authorized_daily_deal_purchase, :daily_deal => @daily_deal, :payment_status_updated_at => @end + 1.day)
      end

      should "not include purchases with a payment status updated outside the time period" do
        @publishing_group.daily_deal_purchases_to_csv(csv = [], (@start..@end))
        [@too_new, @too_old].each do |ddp|
          assert_equal 0, find_purchase_in_csv_data(ddp, csv).size
        end
      end
    end
  end

  private

  def find_purchase_in_csv_data(daily_deal_purchase, csv)
    # Assuming only one purchase per consumer
    csv[1..-1].select{|row| row[@columns.index('email')] == daily_deal_purchase.consumer.email }
  end
end
