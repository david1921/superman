require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Publishers::TritonLoyaltyTest
module Publishers
  class TritonLoyaltyTest < ActiveSupport::TestCase
    context "update_triton_loyalty_list for publisher with subscribers and configured triton loyalty site code" do
      setup do
        publishing_group = Factory(:publishing_group, :label => "entercom")
        @publisher = Factory(:publisher, :label => "entercom-unit-test", :publishing_group => publishing_group)
        Time.stubs(:now).returns(@time_1 = Time.parse("Jan 01, 2011 01:00:00 PST"))
        @publisher.subscribers.create!(:email => "subscriber1@example.com")
        Time.stubs(:now).returns(@time_2 = Time.parse("Jan 02, 2011 01:00:00 PST"))
        @publisher.subscribers.create!(:email => "subscriber2@example.com")
        Time.stubs(:now).returns(@time_3 = Time.parse("Jan 03, 2011 01:00:00 PST"))
        @publisher.subscribers.create!(:email => "subscriber3@example.com")
        Time.stubs(:now).returns(@time_4 = Time.parse("Jan 04, 2011 01:00:00 PST"))
        @publisher.subscribers.create!(:email => "subscriber2@example.com")
      end

      context "invoking triton loyalty update_member API but not the update_member_subscriptions API" do
        setup do
          triton_loyalty = mock("triton_loyalty") do
            expects(:update_member).at_least_once.with do |site_code, consumer|
              "dev4aa" == site_code
            end.returns("1234")
            expects(:update_member_subscriptions).never
          end
          TritonLoyalty.expects(:new).with do |options|
            %w{ analog d8bl3a6n6l7t1cs dev4aa 6219 } == options.values_at(:partner_code, :shared_secret, :site_code, :subscription_id)
          end.returns(triton_loyalty)
        end

        should "upload the two subscribers created before time_3 when the current time is before time_3 and no jobs have been run" do
          Time.stubs(:now).returns(@time_3 - 30.minutes)

          assert_difference 'Job.count' do
            assert_equal({ :number => 2, :errors => [] }, @publisher.update_triton_loyalty_list!)
          end
          job = Job.last
          assert_equal "publisher:entercom-unit-test:update_triton_loyalty_list", job.key
          assert_equal Time.now, job.increment_timestamp

          assert_equal 2, @publisher.consumers.count
          @publisher.consumers.each do |consumer|
            assert_match /subscriber[12]@example.com/, consumer.email
            assert_equal Time.now, consumer.remote_record_updated_at
            assert_equal "1234", consumer.remote_record_id
          end
        end

        should "upload the two subscribers created before time_3 when the current time is time_3 and no jobs have been run" do
          Time.stubs(:now).returns(@time_3)

          assert_difference 'Job.count' do
            assert_equal({ :number => 2, :errors => [] }, @publisher.update_triton_loyalty_list!)
          end
          job = Job.last
          assert_equal "publisher:entercom-unit-test:update_triton_loyalty_list", job.key
          assert_equal Time.now, job.increment_timestamp

          assert_equal 2, @publisher.consumers.count
          @publisher.consumers.each do |consumer|
            assert_match /subscriber[12]@example.com/, consumer.email
            assert_equal Time.now, consumer.remote_record_updated_at
            assert_equal "1234", consumer.remote_record_id
          end
        end

        should "upload only the subscriber created at time_3 when the current time is between time_3 and time_4 and a job was run at time_3" do
          Time.stubs(:now).returns(@time_3)
          Job.create!(
            :key => "publisher:entercom-unit-test:update_triton_loyalty_list",
            :increment_timestamp => @time_3,
            :started_at => @time_3,
            :finished_at => @time_3 + 30.minutes
          )
          Time.stubs(:now).returns(@time_4 - 30.minutes)

          assert_difference 'Job.count' do
            assert_equal({ :number => 1, :errors => [] }, @publisher.update_triton_loyalty_list!)
          end
          job = Job.last
          assert_equal "publisher:entercom-unit-test:update_triton_loyalty_list", job.key
          assert_equal Time.now, job.increment_timestamp

          assert_equal 1, @publisher.consumers.count
          consumer = @publisher.consumers.last
          assert_equal "subscriber3@example.com", consumer.email
          assert_equal Time.now, consumer.remote_record_updated_at
          assert_equal "1234", consumer.remote_record_id
        end
      end

      context "not invoking triton loyalty API" do
        setup do
          TritonLoyalty.expects(:new).never
        end

        should "not upload any subscribers when no jobs have been run and the current time is time_1" do
          Time.stubs(:now).returns(@time_1)

          assert_difference 'Job.count' do
            assert_equal({ :number => 0, :errors => [] }, @publisher.update_triton_loyalty_list!)
          end
          job = Job.last
          assert_equal "publisher:entercom-unit-test:update_triton_loyalty_list", job.key
          assert_equal Time.now, job.increment_timestamp

          assert_equal 0, @publisher.consumers.count
        end

        should "not upload any subscribers when the current time is time_3 and a job was run between time_2 and time_3" do
          Time.stubs(:now).returns(@time_3 - 30.minutes)
          Job.create!(
            :key => "publisher:entercom-unit-test:update_triton_loyalty_list",
            :increment_timestamp => @time_3,
            :started_at => @time_3 - 30.minutes,
            :finished_at => @time_3
          )
          Time.stubs(:now).returns(@time_3)

          assert_difference 'Job.count' do
            assert_equal({ :number => 0, :errors => [] }, @publisher.update_triton_loyalty_list!)
          end
          job = Job.last
          assert_equal "publisher:entercom-unit-test:update_triton_loyalty_list", job.key
          assert_equal Time.now, job.increment_timestamp

          assert_equal 0, @publisher.consumers.count
        end
      end
    
      should "upload two subscribers and resubscribe subscriber2 when the current time is after time_4 and a job was run after time_2" do
        Time.stubs(:now).returns(@time_3 - 30.minutes)
        Job.create!(
          :key => "publisher:entercom-unit-test:update_triton_loyalty_list",
          :increment_timestamp => @time_3,
          :started_at => @time_3 - 30.minutes,
          :finished_at => @time_3
        )
        Factory(:consumer, {
          :publisher => @publisher,
          :email => "subscriber1@example.com",
          :remote_record_id => "1111",
          :remote_record_updated_at => @time_3 - 20.minutes
        })
        Factory(:consumer, {
          :publisher => @publisher,
          :email => "subscriber2@example.com",
          :remote_record_id => "2222",
          :remote_record_updated_at => @time_3 - 20.minutes
        })
        
        triton_loyalty = mock("triton_loyalty") do
          expects(:update_member).twice.with do |site_code, consumer|
            "dev4aa" == site_code && %w{ subscriber3@example.com subscriber2@example.com }.include?(consumer.email)
          end.returns("1234")
          expects(:update_member_subscriptions).once.with do |site_code, remote_record_id, subscriptions|
            "dev4aa" == site_code && "2222" == remote_record_id && { "6219" => true } == subscriptions
          end
        end
        TritonLoyalty.expects(:new).with do |options|
          %w{ analog d8bl3a6n6l7t1cs dev4aa 6219 } == options.values_at(:partner_code, :shared_secret, :site_code, :subscription_id)
        end.returns(triton_loyalty)

        Time.stubs(:now).returns(@time_4 + 30.minutes)
        assert_difference 'Job.count' do
          assert_equal({ :number => 2, :errors => [] }, @publisher.update_triton_loyalty_list!)
        end
        job = Job.last
        assert_equal "publisher:entercom-unit-test:update_triton_loyalty_list", job.key
        assert_equal Time.now, job.increment_timestamp
      end
    end
  end
end
