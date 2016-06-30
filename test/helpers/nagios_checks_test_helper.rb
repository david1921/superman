module NagiosChecksTestHelper

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def action_should_verify_that_job_finished_before_1pm(options)
      action_name = options[:action_name]
      job_key = options[:job_key]

      context "GET to #{action_name}" do
        
        should "respond with a WARNING if called before 01:00PM on a given day" do
          Timecop.freeze(Time.zone.parse("2012-06-05 12:30:01 PDT")) do
            get :"#{action_name}"
            assert_response :success
            assert_equal "WARNING - Too early to check whether #{job_key} completed successfully. " +
                         "This job is allowed to finish anytime before 01:00 PM PST, and it's only " +
                         "12:30 PM right now.", @response.body
          end
        end

        should "respond with a CRITICAL when there is no Job entry for today" do
          Timecop.freeze(Time.zone.parse("2012-06-05 13:04:00 PDT")) do
            assert !Job.exists?(:key => job_key)
            get :"#{action_name}"
            assert_response :success
            assert_match %r{CRITICAL - Expected #{job_key} to finish running by 01:00 PM PST today, but it appears to have not run at all. See http.*},
                         @response.body
          end
        end

        should "respond with a CRITICAL when there is no Job entry for today, but its finished_at is after 1PM" do
          Timecop.freeze(Time.zone.parse("2012-06-05 13:02:00 PDT")) do
            Job.run!(job_key, :incremental => false) do
              # noop
            end
          end

          Timecop.freeze(Time.zone.parse("2012-06-05 13:05:00 PDT")) do
            get :"#{action_name}"
            assert_response :success
            assert_equal "CRITICAL - Expected #{job_key} to finish running by 01:00 PM PST today, " +
                         "but it finished at 01:02 PM", @response.body
          end
        end

        should "respond with a WARNING when there is a Job entry for today, but Job#finished_at is > 12:50PM and <= 01:00PM" do
          Timecop.freeze(Time.zone.parse("2012-06-05 12:50:01 PDT")) do
            Job.run!(job_key, :incremental => false) do
              # noop
            end
          end

          Timecop.freeze(Time.zone.parse("2012-06-05 13:10:12 PDT")) do
            get :"#{action_name}"
            assert_response :success
            assert_equal "WARNING - Expected #{job_key} to finish running by 01:00 PM PST. It " +
                         "finished at 12:50 PM, which is fine, but uncomfortably close to the " +
                         "hard cutoff time. We should investigate this ASAP.", @response.body
          end
        end

        should "respond with OK when there is Job entry for today, and Job#finished_at is >= 12:00PM and < 12:50PM" do
          Timecop.freeze(Time.zone.parse("2012-06-05 12:49:00 PDT")) do
            Job.run!(job_key, :incremental => false) do
              # noop
            end
          end

          Timecop.freeze(Time.zone.parse("2012-06-05 13:10:12 PDT")) do
            get :"#{action_name}"
            assert_response :success
            assert_equal "OK - #{job_key} finished at 12:49 PM", @response.body
          end
        end

      end

    end

  end

end
