require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::EmailBlastTest < ActiveSupport::TestCase
  setup do
    @now = Time.parse("2012-02-15T05:10:00Z")
  end

  should "delegate :send_todays_email_blast_at to publisher" do
    publisher = Factory(:publisher, :time_zone => "Eastern Time (US & Canada)", :email_blast_hour => 6, :email_blast_minute => 25)
    deal = Factory(:daily_deal, :publisher => publisher)
    assert_equal publisher.send_todays_email_blast_at, deal.send_todays_email_blast_at
  end

  context "#expected_email_blast_at?" do

    should "return false if email blast disabled" do
      Timecop.freeze(@now) do
        deal = Factory(:featured_daily_deal, :enable_daily_email_blast => false, :start_at => 23.hours.ago)
        assert !deal.expected_email_blast_at?(Time.zone.now)
      end
    end

    should "return true even if deal becomes featured more than 24 hours after starting" do
      Timecop.freeze(@now) do
        deal = Factory(:daily_deal, :enable_daily_email_blast => true, :start_at => 24.hours.ago, :side_start_at => 24.hours.ago,
                       :side_end_at => Time.zone.now)
        assert deal.expected_email_blast_at?(5.minutes.from_now)
      end
    end

    should "return false if there was a previous featured window that had a scheduled mailing" do
      Timecop.freeze(@now) do
        deal = Factory(:daily_deal, :enable_daily_email_blast => true, :start_at => 1.week.ago, :side_start_at => 6.days.ago,
                       :side_end_at => 12.hours.ago, :hide_at => 1.day.from_now)
        Factory(:scheduled_mailing, :publisher => deal.publisher, :mailing_date => 1.week.ago.to_date)
        assert !deal.expected_email_blast_at?(5.minutes.from_now)
      end
    end

    should "return true if there was a previous featured window but only other scheduled mailings (not for this deal)" do
      Timecop.freeze(@now) do
        deal = Factory(:daily_deal, :enable_daily_email_blast => true, :start_at => 1.week.ago, :side_start_at => 6.days.ago,
                       :side_end_at => 12.hours.ago, :hide_at => 1.day.from_now)
        other_mailing_before = Factory(:scheduled_mailing, :publisher => deal.publisher, :mailing_date => (deal.start_at + 1.day).to_date)
        other_mailing_after = Factory(:scheduled_mailing, :publisher => deal.publisher, :mailing_date => (deal.start_at - 1.day).to_date)
        assert deal.expected_email_blast_at?(5.minutes.from_now)
      end
    end

    should "return true if email blast enable and deal started < 24 hours ago" do
      Timecop.freeze(Time.zone.now) do
        deal = Factory(:daily_deal, :enable_daily_email_blast => true, :start_at => 23.hours.ago)
        assert deal.expected_email_blast_at?(Time.zone.now)
      end
    end

    should "return false if email blast enable but deal started > 24 hours ago" do
      Timecop.freeze(Time.zone.now) do
        deal = Factory(:daily_deal, :enable_daily_email_blast => true, :start_at => 25.hours.ago)
        assert !deal.expected_email_blast_at?(Time.zone.now)
      end
    end

    should "return false if deal start time is after blast time" do
      Timecop.freeze(Time.zone.now) do
        deal = Factory(:daily_deal, :enable_daily_email_blast => true, :start_at => 1.hour.ago)
        assert !deal.expected_email_blast_at?(2.hours.ago)
      end
    end

  end
end
