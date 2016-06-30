require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Publishers::SilverpopTest
module Publishers
  class SilverpopTest < ActiveSupport::TestCase

    context "schedule_todays_silverpop_mailing for publisher with configured silverpop options" do

      setup do
        publishing_group = Factory(:publishing_group, :label => "entercom")
        @publisher = Factory(:publisher, {
          :publishing_group => publishing_group,
          :label => "entercom-unit-test",
          :time_zone => "Eastern Time (US & Canada)",
          :email_blast_hour => 6,
          :email_blast_minute => 15,
          :silverpop_template_identifier => "111111",
          :silverpop_list_identifier => "222222"
        })
        @publisher.stubs(:silverpop_account_time_zone).returns(nil)
        Time.stubs(:now).returns(Time.parse("Dec 14, 2010 23:00:00 PST"))
      end

      should "create a scheduled mailing if called with no block while no scheduled mailing exists" do
        silverpop_session = mock("silverpop_session") do
          expects(:schedule_mailing).with do |options|
            "111111" == options[:template_id] && "222222" == options[:list_id] &&
              Time.parse("Dec 15, 2010 06:15:00 EST")== options[:send_at] &&
              "analog-entercom-unit-test-20101215061500" == options[:mailing_name]
          end.returns("12345678")
        end
        silverpop = mock("silverpop") { expects(:open).yields(silverpop_session) }
        Analog::ThirdPartyApi::Silverpop.expects(:new).returns(silverpop)

        assert_difference '@publisher.scheduled_mailings.count' do
          @publisher.schedule_todays_silverpop_mailing
        end
        scheduled_mailing = @publisher.scheduled_mailings.first
        assert_equal Date.parse("Dec 15, 2010"), scheduled_mailing.mailing_date
        assert_equal "analog-entercom-unit-test-20101215061500", scheduled_mailing.mailing_name
        assert_equal "12345678", scheduled_mailing.remote_mailing_id
        assert_not_nil scheduled_mailing.success_at
        assert_nil scheduled_mailing.error_at
        assert_nil scheduled_mailing.error_message
      end

      should "not create a scheduled mailing if called with no block while a scheduled mailing exists" do
        @publisher.scheduled_mailings.create!(
          :mailing_date => Date.parse("Dec 15, 2010"),
          :mailing_name => "analog-entercom-unit-test-20101215",
          :remote_mailing_id => "12345678"
        )
        Analog::ThirdPartyApi::Silverpop.expects(:new).never

        assert_no_difference '@publisher.scheduled_mailings.count' do
          @publisher.schedule_todays_silverpop_mailing
        end
      end

      should "create a scheduled mailing if called with a block returning an empty hash while no scheduled mailing exists" do
        silverpop_session = mock("silverpop_session") do
          expects(:schedule_mailing).with do |options|
            "111111" == options[:template_id] && "222222" == options[:list_id] &&
              Time.parse("Dec 15, 2010 06:15:00 EST")== options[:send_at] &&
              "analog-entercom-unit-test-20101215061500" == options[:mailing_name]
          end.returns("12345678")
        end
        silverpop = mock("silverpop") { expects(:open).yields(silverpop_session) }
        Analog::ThirdPartyApi::Silverpop.expects(:new).returns(silverpop)

        assert_difference '@publisher.scheduled_mailings.count' do
          @publisher.schedule_todays_silverpop_mailing do |blast_time|
            assert_equal Time.parse("Dec 15, 2010 03:15:00 PST"), blast_time
            {}
          end
        end
        scheduled_mailing = @publisher.scheduled_mailings.first
        assert_equal Date.parse("Dec 15, 2010"), scheduled_mailing.mailing_date
        assert_equal "analog-entercom-unit-test-20101215061500", scheduled_mailing.mailing_name
        assert_equal "12345678", scheduled_mailing.remote_mailing_id
      end

      should "create a scheduled mailing with additional options if called with a block returning options while no scheduled mailing exists" do
        silverpop_session = mock("silverpop_session") do
          expects(:schedule_mailing).with do |options|
            "111111" == options[:template_id] && "222222" == options[:list_id] &&
              Time.parse("Dec 15, 2010 06:15:00 EST")== options[:send_at] &&
              "analog-entercom-unit-test-20101215061500" == options[:mailing_name] &&
              "A fantastic deal awaits" == options[:subject]
          end.returns("12345678")
        end
        silverpop = mock("silverpop") { expects(:open).yields(silverpop_session) }
        Analog::ThirdPartyApi::Silverpop.expects(:new).returns(silverpop)

        assert_difference '@publisher.scheduled_mailings.count' do
          @publisher.schedule_todays_silverpop_mailing do |blast_time|
            assert_equal Time.parse("Dec 15, 2010 03:15:00 PST"), blast_time
            { :subject => "A fantastic deal awaits" }
          end
        end
        scheduled_mailing = @publisher.scheduled_mailings.first
        assert_equal Date.parse("Dec 15, 2010"), scheduled_mailing.mailing_date
        assert_equal "analog-entercom-unit-test-20101215061500", scheduled_mailing.mailing_name
        assert_equal "12345678", scheduled_mailing.remote_mailing_id
      end

      should "not create a scheduled mailing if called with a block returning true while a scheduled mailing exists" do
        @publisher.scheduled_mailings.create!(
          :mailing_date => Date.parse("Dec 15, 2010"),
          :mailing_name => "analog-entercom-unit-test-20101215",
          :remote_mailing_id => "12345678"
        )
        Analog::ThirdPartyApi::Silverpop.expects(:new).never

        assert_no_difference '@publisher.scheduled_mailings.count' do
          @publisher.schedule_todays_silverpop_mailing do |blast_time|
            assert_equal Time.parse("Dec 15, 2010 03:15:00 PST"), blast_time
            true
          end
        end
      end

      should "not create a scheduled mailing if called with a block returning nil while no scheduled mailing exists" do
        Analog::ThirdPartyApi::Silverpop.expects(:new).never

        assert_no_difference '@publisher.scheduled_mailings.count' do
          @publisher.schedule_todays_silverpop_mailing do |blast_time|
            assert_equal Time.parse("Dec 15, 2010 03:15:00 PST"), blast_time
            nil
          end
        end
      end

      context "schedule mailing error handling" do

        should "create a scheduled mailing even if no mailing id is returned" do
          silverpop_session = mock("silverpop_session") do
            stubs(:schedule_mailing).returns("")
          end
          silverpop = mock("silverpop") { expects(:open).yields(silverpop_session) }
          Analog::ThirdPartyApi::Silverpop.expects(:new).returns(silverpop)
          assert_difference '@publisher.scheduled_mailings.count' do
            assert_raise RuntimeError do
              @publisher.schedule_todays_silverpop_mailing
            end
          end
          scheduled_mailing = @publisher.scheduled_mailings.first
          assert_nil scheduled_mailing.success_at
          assert_not_nil scheduled_mailing.error_at
          assert_equal "no mailing_id returned from silverpop", scheduled_mailing.error_message
        end

        should "create a scheduled mailing even if an exception is raised" do
          silverpop_session = mock("silverpop_session") do
            stubs(:schedule_mailing).raises(RuntimeError)
          end
          silverpop = mock("silverpop") { expects(:open).yields(silverpop_session) }
          Analog::ThirdPartyApi::Silverpop.expects(:new).returns(silverpop)
          assert_difference '@publisher.scheduled_mailings.count' do
            assert_raise RuntimeError do
              @publisher.schedule_todays_silverpop_mailing
            end
          end
          scheduled_mailing = @publisher.scheduled_mailings.first
          assert_nil scheduled_mailing.success_at
          assert_not_nil scheduled_mailing.error_at
          assert_not_nil scheduled_mailing.error_message
        end
      end

    end

    context "schedule weekly mailing" do

      context "basic logic of schedule weekly mailings" do

        setup do
          @publisher = Factory(:publisher, :email_blast_day_of_week => "Saturday", :email_blast_hour => 10, :email_blast_minute => 0)
        end

        should "not schedule anything if not configured for weekly scheduling" do
          @publisher.expects(:configured_to_schedule_weekly_emails?).returns(false)
          @publisher.expects(:schedule_weekly_email_blast_for_seed_list_if_configured).never
          @publisher.expects(:schedule_weekly_email_blast_for_contact_list_if_configured).never
          @publisher.schedule_this_weeks_silverpop_mailings
        end

        should "not schedule anything if there is no active deal" do
          @publisher.expects(:configured_to_schedule_weekly_emails?).returns(true)
          @publisher.expects(:in_weekly_blast_scheduling_window?).returns(true)
          @publisher.expects(:active_featured_deal_at?).returns(false)
          @publisher.expects(:schedule_weekly_email_blast_for_seed_list_if_configured).never
          @publisher.expects(:schedule_weekly_email_blast_for_contact_list_if_configured).never
          @publisher.schedule_this_weeks_silverpop_mailings
        end

        should "not schedule anything if there's one schedule for the week" do
          @publisher.expects(:configured_to_schedule_weekly_emails?).returns(true)
          @publisher.expects(:in_weekly_blast_scheduling_window?).returns(true)
          @publisher.expects(:active_featured_deal_at?).returns(true)
          @publisher.expects(:weekly_email_already_scheduled?).returns(true)
          @publisher.expects(:schedule_weekly_email_blast_for_seed_list_if_configured).never
          @publisher.expects(:schedule_weekly_email_blast_for_contact_list_if_configured).never
          @publisher.schedule_this_weeks_silverpop_mailings
        end

        should "not schedule both if there's a deal to schedule that has not been scheduled yet" do
          @publisher.expects(:configured_to_schedule_weekly_emails?).returns(true)
          @publisher.expects(:active_featured_deal_at?).returns(true)
          @publisher.expects(:weekly_email_already_scheduled?).returns(false)
          @publisher.expects(:in_weekly_blast_scheduling_window?).returns(true)
          @publisher.expects(:schedule_weekly_email_blast_for_seed_list_if_configured).once
          @publisher.expects(:schedule_weekly_email_blast_for_contact_list_if_configured).once
          @publisher.schedule_this_weeks_silverpop_mailings
        end
      end

      context "schedule weekly mailings for reals" do
        setup do
          publishing_group = Factory(:publishing_group, :label => "bcbsa", :silverpop_account_time_zone => "Pacific Time (US & Canada)")
          @publisher = Factory(:publisher, {
            :publishing_group => publishing_group,
            :label => "bcbsa-unit-test",
            :time_zone => "Eastern Time (US & Canada)",
            :email_blast_hour => 6,
            :email_blast_minute => 15,
            :email_blast_day_of_week => "Saturday",
            :silverpop_template_identifier => "111111",
            :silverpop_list_identifier => "222222",
            :silverpop_seed_template_identifier => "333333",
            :silverpop_seed_database_identifier => "444444",
            :send_weekly_email_blast_to_contact_list => true,
            :send_weekly_email_blast_to_seed_list => true
          })
          @advertiser = Factory(:advertiser, :publisher => @publisher)
        end

        should "create a two scheduled mailings" do
          deal = Factory(:daily_deal,
                         :advertiser => @advertiser,
                         :featured => true,
                         :start_at => Time.local(2012, 1, 15),
                         :hide_at => Time.local(2012, 1, 24))
          silverpop_session = mock("silverpop_session") do
            expects(:schedule_mailing).with do |options|
              "111111" == options[:template_id] &&
              "222222" == options[:list_id] &&
              Time.parse("Jan 21, 2012 06:15:00 EST") == options[:send_at] &&
              "weekly-contact-analog-bcbsa-unit-test-20120121061500" == options[:mailing_name]
            end.returns("12345678")
            stubs(:schedule_mailing).with do |options|
              "333333" == options[:template_id] &&
              "444444" == options[:list_id] &&
              Time.parse("Jan 21, 2012 06:15:00 EST") == options[:send_at] &&
              "Pacific Time (US & Canada)" == options[:time_zone] &&
              "weekly-seed-analog-bcbsa-unit-test-20120121061500" == options[:mailing_name]
            end.returns("12345679")
          end
          silverpop = mock("silverpop") { stubs(:open).yields(silverpop_session) }
          @publisher.stubs(:silverpop).returns(silverpop)
          @publisher.stubs(:in_weekly_blast_scheduling_window?).returns(true)

          Timecop.freeze(Time.local(2012, 1, 18)) do
            assert_equal 0, @publisher.scheduled_mailings.size
            send_at = Time.parse("Jan 21, 2012 06:15:00 EST")
            assert_equal send_at, @publisher.send_this_weeks_email_blast_at
            assert @publisher.active_featured_deal_at?(send_at)
            assert !@publisher.weekly_email_already_scheduled?(send_at)
            @publisher.schedule_this_weeks_silverpop_mailings

            assert_equal 2, @publisher.scheduled_mailings.size

            contact_mailing = @publisher.scheduled_mailings.find_by_mailing_name("weekly-contact-analog-bcbsa-unit-test-20120121061500")
            assert_not_nil contact_mailing
            assert_equal Date.parse("Jan 21, 2012"), contact_mailing.mailing_date
            assert_equal "12345678", contact_mailing.remote_mailing_id

            seed_mailing = @publisher.scheduled_mailings.find_by_mailing_name("weekly-seed-analog-bcbsa-unit-test-20120121061500")
            assert_not_nil seed_mailing
            assert_equal Date.parse("Jan 21, 2012"), seed_mailing.mailing_date
            assert_equal "12345679", seed_mailing.remote_mailing_id
          end
        end

      end

      context "send_this_weeks_email_blast_at" do

        should "raise if not configured for weekly sends" do
          publisher = Factory.build(:publisher)
          assert_nil publisher.email_blast_day_of_week
          assert_raise RuntimeError do
            publisher.send_this_weeks_email_blast_at
          end
        end

        should "use the email blast dates and times to calc the proper send at for a given week" do
          publisher = Factory.build(:publisher, :time_zone => "UTC")
          publisher.email_blast_day_of_week = "Thursday"
          publisher.email_blast_hour = "10"
          publisher.email_blast_minute = "22"
          Timecop.freeze(Time.utc(2012, 1, 3, 5, 30)) do
            assert_equal Time.utc(2012, 1, 5, 10, 22), publisher.send_this_weeks_email_blast_at
          end
          Timecop.freeze(Time.utc(2012, 1, 6, 5, 30)) do
            assert_equal Time.utc(2012, 1, 5, 10, 22), publisher.send_this_weeks_email_blast_at, "should use same week even after time has past"
          end
        end

      end

      context "active_featured_deal_at" do

        setup do
          @publisher = Factory(:publisher)
          @advertiser = Factory(:advertiser, :publisher => @publisher)
          @deal = Factory(:daily_deal, :advertiser => @advertiser)
        end

        should "work" do
          assert_equal 1, @publisher.daily_deals.size
          Timecop.freeze(Time.local(2012, 1, 3)) do
            @deal.start_at = Time.zone.now
            @deal.hide_at = Time.zone.now + 2.days
            @deal.save!
            assert !@publisher.active_featured_deal_at?(Time.zone.now - 1.hour)
            assert @publisher.active_featured_deal_at?(Time.zone.now + 1.day)
            assert !@publisher.active_featured_deal_at?(Time.zone.now + 3.days)
          end
        end

      end

      context "close_enough_to_blast_time?" do
        should "respect publisher setting for blast window" do
          @publisher = Factory.build(:publisher, :weekly_email_blast_scheduling_window_start_in_hours => 12)
          Timecop.freeze(Time.utc(2012, 1, 10, 11, 15)) do
            assert !@publisher.in_weekly_blast_scheduling_window?(5.days.ago), "send at well before the blast window"

            assert !@publisher.in_weekly_blast_scheduling_window?(1.second.ago), "send at just before start of blast window"
            assert @publisher.in_weekly_blast_scheduling_window?(Time.zone.now), "send at just at start of blast window"
            assert @publisher.in_weekly_blast_scheduling_window?(1.second.from_now), "send at just after start of blast window"

            assert @publisher.in_weekly_blast_scheduling_window?((12.hours - 1.second).from_now), "send at just before the end of blast window"
            assert @publisher.in_weekly_blast_scheduling_window?(12.hours.from_now), "just at end of blast window"
            assert !@publisher.in_weekly_blast_scheduling_window?((12.hours + 1.second).from_now), "send at just after end of blast window"


            assert !@publisher.in_weekly_blast_scheduling_window?(5.days.from_now), "send at well after the blast window"

          end
        end
      end

      context "configured to send weekly emails" do

        setup do
          @publisher = Factory.build(:publisher)
        end

        should "be false if no day of week set" do
          @publisher.stubs(:email_blast_day_of_week).returns("")
          assert !@publisher.configured_to_schedule_weekly_emails?
        end

        should "be false if neither weelky send option is set" do
          @publisher.stubs(:send_weekly_email_blast_to_seed_list).returns(false)
          @publisher.stubs(:send_weekly_email_blast_to_contact_list).returns(false)
          assert !@publisher.configured_to_schedule_weekly_emails?
        end

        should "be true if day of week + send to seed list is set" do
          @publisher.stubs(:email_blast_day_of_week).returns("Saturday")
          @publisher.stubs(:send_weekly_email_blast_to_seed_list).returns(true)
          @publisher.stubs(:send_weekly_email_blast_to_contact_list).returns(false)
          assert @publisher.configured_to_schedule_weekly_emails?
        end

        should "be true if day of week + send to contact list is set" do
          @publisher.stubs(:email_blast_day_of_week).returns("Saturday")
          @publisher.stubs(:send_weekly_email_blast_to_seed_list).returns(false)
          @publisher.stubs(:send_weekly_email_blast_to_contact_list).returns(true)
          assert @publisher.configured_to_schedule_weekly_emails?
        end

      end

    end

    context "silverpop_account_time_zone" do

      should "return nil if publishing group has none set" do
        publishing_group = Factory.build(:publishing_group, :silverpop_account_time_zone => nil)
        publisher = Factory.build(:publisher, :publishing_group => publishing_group)
        assert_nil publisher.silverpop_account_time_zone
      end

      should "return nil if there is no publishing_group" do
        publisher = Factory.build(:publisher, :publishing_group => nil)
        assert_nil publisher.silverpop_account_time_zone
      end

      should "return value if publishing group has one set" do
        publishing_group = Factory.build(:publishing_group, :silverpop_account_time_zone => "Pacific Time (US & Canada)")
        publisher = Factory.build(:publisher, :publishing_group => publishing_group)
        assert_equal "Pacific Time (US & Canada)", publisher.silverpop_account_time_zone
      end

    end

    context "#scheduled_mailing_exists?" do
      should "return true when a successful mailing exists" do
        Timecop.freeze do
          mailing = Factory(:scheduled_mailing, :mailing_date => "2012-03-01")
          assert mailing.publisher.successful_scheduled_mailing_exists?(Time.parse("2012-03-01T09:00:00Z"))
        end
      end

      should "return false when only failed mailings exist" do
        mailing = Factory(:scheduled_mailing, :mailing_date => "2012-03-01", :remote_mailing_id => nil)
        assert !mailing.publisher.successful_scheduled_mailing_exists?(Time.parse("2012-03-01T09:00:00Z"))
      end
    end

    context "daily_deal_for_email_blast" do

      should "be okay if the deal is not featured at the time of the run but only at the time of the blast" do
        start_at = 10.hours.from_now
        hide_at = 24.hours.from_now
        blast_time = start_at + 1.hour
        publisher = Factory(:publisher)
        deal = Factory(:daily_deal, :publisher => publisher, :start_at => start_at, :hide_at => hide_at)
        assert_equal 0, publisher.daily_deals.featured.size
        assert_equal deal, publisher.daily_deals.featured_at(blast_time).first
        assert_equal deal, publisher.daily_deal_for_email_blast(blast_time + 1.hour)
      end

    end

  end
end

