require File.dirname(__FILE__) + "/../test_helper"

class NagiosChecksControllerTest < ActionController::TestCase

  include NagiosChecksTestHelper

  action_should_verify_that_job_finished_before_1pm(
    :action_name => "ensure_advertiser_sanctions_file_uploaded_before_1pm",
    :job_key     => "sanction_screening:export_and_uploaded_encrypted_advertiser_file")

  action_should_verify_that_job_finished_before_1pm(
    :action_name => "ensure_publisher_sanctions_file_uploaded_before_1pm",
    :job_key     => "sanction_screening:export_and_uploaded_encrypted_publisher_file")

  action_should_verify_that_job_finished_before_1pm(
    :action_name => "ensure_consumer_sanctions_file_uploaded_before_1pm",
    :job_key     => "sanction_screening:export_and_uploaded_encrypted_consumer_file")

end
