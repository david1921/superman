require File.dirname(__FILE__) + "/../../test_helper"

class PublishingGroupsMailerTest < ActionMailer::TestCase
  context "deliver_consumer_counts" do
    setup do
      ActionMailer::Base.deliveries.clear
      @publishing_group = Factory(:publishing_group,
                                  :consumer_recipients => 'test@example.com',
                                  :name => "Publishing Group")
      @publisher = Factory(:publisher,
                           :publishing_group => @publishing_group,
                           :name => "Example Publisher")
      Factory(:subscriber, :publisher => @publisher)
    end

    should "deliver email with attachement when consumer_recipients is given" do
      email = PublishingGroupsMailer.deliver_consumer_counts(@publishing_group)
      assert_equal 1, ActionMailer::Base.deliveries.size, "Should send one email"

      assert_equal ["test@example.com"], email.to
      assert_equal ["support@analoganalytics.com"], email.from
      assert_equal "Publishing Group Signup Counts", email.subject

      assert_equal 1, email.attachments.size, "Should have one attachment"
      attachment = email.attachments.first
      assert_match /\Aconsumer-counts-\d{4}-\d{2}-\d{2}.csv\z/, attachment.original_filename
      assert_equal "text/csv", attachment.content_type

      actual_counts = FasterCSV.parse(attachment, :headers => true).to_a
      expected_counts = [["Publisher", "Signup Count"], ["Example Publisher", "1"]]
      assert_equal expected_counts, actual_counts
    end

    should "fail when consumer_recipients not given" do
      @publishing_group.update_attribute(:consumer_recipients, nil)

      assert_raise ArgumentError do
        PublishingGroupsMailer.deliver_consumer_counts(@publishing_group)
      end
    end

  end

  test "latest_consumers_and_subscribers" do
    ActionMailer::Base.deliveries.clear

    publishing_group = Factory(:publishing_group,
                               :name => "Example Publishing Group",
                               :consumer_recipients => "foo@example.com")

    File.expects(:read).returns("Jon, Doe, jon@doe.com")
    File.expects(:basename).returns("consumers_file.csv")

    email = PublishingGroupsMailer.deliver_latest_consumers_and_subscribers(publishing_group, "consumers_file.csv")

    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [ "foo@example.com" ], email.to
    assert_equal [ "support@analoganalytics.com" ], email.from
    assert_equal "Example Publishing Group Sign Ups", email.subject

    assert_equal 1, email.attachments.size, "Should have one attachment"
    attachment = email.attachments.first
    assert_match /\Aconsumers_file.csv\z/, attachment.original_filename     
    assert_equal "text/csv", attachment.content_type

  end
end
