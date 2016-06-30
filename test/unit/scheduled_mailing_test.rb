require File.dirname(__FILE__) + "/../test_helper"

class ScheduledMailingTest < ActiveSupport::TestCase
  
  context "named scopes" do
    
    context ":before" do
      should "return mailings with mailing_date before specified date" do
        Timecop.freeze(Time.now) do
          m1 = Factory(:scheduled_mailing, :mailing_date => 2.days.ago.to_date)
          m2 = Factory(:scheduled_mailing, :mailing_date => 1.day.ago.to_date)
          mailings = ScheduledMailing.before(Time.now.to_date)
          assert_equal Set.new([m1, m2]), Set.new(mailings), "Expected mailings #{[m1, m2].map(&:id).sort.inspect}, was #{mailings.map(&:id).sort.inspect}"
        end
      end
    end

    context ":mailing_date_between" do
      should "work like a charm" do
        Timecop.freeze(Time.local(2012, 1, 3)) do
          publisher = Factory(:publisher)
          mailing1 = Factory(:scheduled_mailing, :publisher => publisher, :mailing_date => 1.day.from_now)
          mailing2 = Factory(:scheduled_mailing, :publisher => publisher, :mailing_date => 4.days.from_now)
          assert_same_elements [mailing1, mailing2], publisher.scheduled_mailings
          assert_same_elements [mailing1, mailing2], publisher.scheduled_mailings.mailing_date_between(1.day.ago..5.days.from_now)
          assert_same_elements [mailing1], publisher.scheduled_mailings.mailing_date_between(1.day.ago..3.days.from_now)
          assert_same_elements [mailing2], publisher.scheduled_mailings.mailing_date_between(3.day.from_now..5.days.from_now)
          assert_equal [], publisher.scheduled_mailings.mailing_date_between(5.day.ago..3.days.ago)
          assert_equal [], publisher.scheduled_mailings.mailing_date_between(5.day.from_now..7.days.from_now)
        end
      end
    end

    context ":successful" do
      should "only return mailings with a remote_mailing_id" do
        sm1 = Factory(:scheduled_mailing, :remote_mailing_id => "not null")
        sm2 = Factory(:scheduled_mailing, :remote_mailing_id => nil)
        assert_equal Set.new([sm1, sm2]), Set.new(ScheduledMailing.all)
        assert_equal [sm1], ScheduledMailing.successful
      end
    end
  end
end
