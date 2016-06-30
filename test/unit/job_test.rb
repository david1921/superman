require File.dirname(__FILE__) + "/../test_helper"

class JobTest < ActiveSupport::TestCase
  test "run with no previous jobs finished and block with no errors" do
    timestamp_1 = Time.parse("Jan 15, 2011 01:00:00")
    timestamp_2 = Time.parse("Jan 15, 2011 02:00:00")
    Time.stubs(:now).returns(timestamp_1)

    last_timestamp, this_timestamp = nil, nil
    assert_difference 'Job.count' do
      Job.run!("test-key", :incremental => true) do |last, this|
        last_timestamp, this_timestamp = last, this
        Time.stubs(:now).returns(timestamp_2)
      end
    end
    assert_equal nil, last_timestamp
    assert_equal timestamp_1, this_timestamp
    
    job = Job.last
    assert_equal "test-key", job.key
    assert_equal timestamp_1, job.started_at
    assert_equal timestamp_1, job.increment_timestamp
    assert_equal timestamp_2, job.finished_at
  end

  test "run with no previous jobs finished and block with errors" do
    timestamp_1 = Time.parse("Jan 15, 2011 01:00:00")
    timestamp_2 = Time.parse("Jan 15, 2011 02:00:00")
    Time.stubs(:now).returns(timestamp_1)

    last_timestamp, this_timestamp = nil, nil
    assert_no_difference 'Job.count' do
      assert_raises RuntimeError do
        Job.run!("test-key", :incremental => true) do |last, this|
          last_timestamp, this_timestamp = last, this
          raise RuntimeError
        end
      end
    end
    assert_equal nil, last_timestamp
    assert_equal timestamp_1, this_timestamp
  end

  test "run with a previous job finished" do
    timestamp_1 = Time.parse("Jan 15, 2011 01:00:00")
    timestamp_2 = Time.parse("Jan 15, 2011 02:00:00")
    timestamp_3 = Time.parse("Jan 15, 2011 03:00:00")

    Time.stubs(:now).returns(timestamp_1)
    Job.create! :key => "test-key", :increment_timestamp => timestamp_1, :started_at => timestamp_1, :finished_at => timestamp_1 + 30.minutes
    
    Time.stubs(:now).returns(timestamp_2)
    last_timestamp, this_timestamp = nil, nil
    assert_difference 'Job.count' do
      Job.run!("test-key", :incremental => true) do |last, this|
        last_timestamp, this_timestamp = last, this
        Time.stubs(:now).returns(timestamp_3)
      end
    end
    assert_equal timestamp_1, last_timestamp
    assert_equal timestamp_2, this_timestamp
    
    job = Job.last
    assert_equal "test-key", job.key
    assert_equal timestamp_2, job.started_at
    assert_equal timestamp_2, job.increment_timestamp
    assert_equal timestamp_3, job.finished_at
  end

  context ".last_finished_at(key)" do

    should "return the latest finished_at time for a given key" do
      Timecop.freeze(Time.zone.parse("2012-06-05 12:50:01 PDT")) { Job.run!("last_finished_at_test", :incremental => false) {} }
      Timecop.freeze(Time.zone.parse("2012-06-06 12:50:01 PDT")) { Job.run!("last_finished_at_test", :incremental => false) {} }
      Timecop.freeze(Time.zone.parse("2012-06-04 12:50:01 PDT")) { Job.run!("last_finished_at_test", :incremental => false) {} }

      assert_equal Time.zone.parse("2012-06-06 12:50:01 PDT"), Job.last_finished_at("last_finished_at_test")
    end

    should "return nil when no jobs with that key exist" do
      assert_nil Job.last_finished_at("doesntexist")
    end
    
  end
end
