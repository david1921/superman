require File.dirname(__FILE__) + "/../../test_helper"
require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Consumers::AfterCommitTest
class Consumers::AfterCommitTest < ActiveSupport::TestCase

  # we are testing after_commit and so if transactions work as they do normally
  # we can not really test what we want to test
  self.use_transactional_fixtures = false

  context "enqueue_resque_job_after_commit" do

    setup do
      @consumer = Factory.build(:consumer)
    end

    should "be able to enqueue some resqueue work with a single arg" do
      @consumer.enqueue_resque_job_after_commit(NewSilverpopRecipients::ResqueJob, 123456)
      assert @consumer.resque_jobs_to_enqueue_in_after_commit.include?({ :job_class => NewSilverpopRecipients::ResqueJob, :args => [123456] })
    end

    should "be able to enqueue some resqueue work with a multiple args" do
      @consumer.enqueue_resque_job_after_commit(NewSilverpopRecipients::ResqueJob, 123456, "shoe", "bat mitzvah")
      assert @consumer.resque_jobs_to_enqueue_in_after_commit.include?({ :job_class => NewSilverpopRecipients::ResqueJob, :args => [123456, "shoe", "bat mitzvah"] })
    end

    should "enqueue jobs in after_commit if there are any" do
      @consumer.enqueue_resque_job_after_commit(NewSilverpopRecipients::ResqueJob, 123456)
      @consumer.enqueue_resque_job_after_commit(SendCertificates, 987654)
      assert_equal @consumer.resque_jobs_to_enqueue_in_after_commit.size, 2
      @consumer.email = "something_different@yahoo.com"
      Resque.expects(:enqueue).with(NewSilverpopRecipients::ResqueJob, 123456).once
      Resque.expects(:enqueue).with(SendCertificates, 987654).once
      @consumer.save!
      @consumer.email = "newemail@yahoo.com"
      @consumer.save!
      assert_equal 0, @consumer.resque_jobs_to_enqueue_in_after_commit.size
    end

  end

end
