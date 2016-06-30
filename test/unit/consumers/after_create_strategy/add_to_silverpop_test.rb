require File.dirname(__FILE__) + "/../../../test_helper"

class Consumers::AfterCreateStrategy::AddToSilverpopTest < ActiveSupport::TestCase

  context "creating a silverpop recipient" do

    setup do
      @publisher = Factory(:publisher, :consumer_after_create_strategy => "add_to_silverpop")
    end

    should "make a new silverpop recipient job" do
      consumer = Factory(:consumer, :publisher => @publisher)
      assert_not_nil NewSilverpopRecipient.find_by_consumer_id(consumer.id)
    end

    should "enqueue the new silverpop recipient job in after_commit" do
      consumer = Factory.build(:consumer, :publisher => @publisher)
      new_recipient = stub("new_recipient")
      new_recipient.stubs(:id => 12345)
      Consumers::AfterCreateStrategy::AddToSilverpop.any_instance.stubs(:create_new_silverpop_recipient).returns(new_recipient)
      consumer.expects(:enqueue_resque_job_after_commit).with(NewSilverpopRecipients::ResqueJob, new_recipient.id)
      consumer.save!
    end

  end

end
