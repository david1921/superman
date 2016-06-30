require File.dirname(__FILE__) + "/../test_helper"

class ResqueExtentionsTest < ActiveSupport::TestCase

  class TestJob
    @queue = :test
    def self.perform
    end
  end

  class JobThatRaises
    @queue = :test
    def self.perform
      raise "This just doesn't work"
    end
  end

  class JobWithArgs
    @queue = :test
    def self.perform(arg1, arg2, arg3)
    end
  end

  test "exceptional behaves as expected" do
    e = Exception.new("This is a test")
    Exceptional::Catcher.expects(:handle).with(e, nil)
    Exceptional.rescue do
      raise e
    end
  end

  test "a job that does not raise" do
    Exceptional::Catcher.expects(:handle).never
    TestJob.expects(:perform).once
    Resque.enqueue(TestJob)
  end

  test "a job that does raise when Resque.inline is false" do
    Resque.stubs(:inline?).returns(false)
    Resque.stubs(:original_enqueue).raises(RuntimeError)
    Exceptional::Catcher.expects(:handle).once
    Resque.enqueue(JobThatRaises)
  end

  test "a job that does raise when Resque.inline? is true" do
    Resque.stubs(:inline?).returns(true)
    Exceptional::Catcher.expects(:handle).never
    assert_raises(RuntimeError) { Resque.enqueue(JobThatRaises) }
  end

  test "args get passed to jobs" do
    JobWithArgs.expects(:perform).with(1, 2.0, "three")
    Resque.enqueue(JobWithArgs, 1, 2.0, "three")
  end

end
