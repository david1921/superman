module BraintreeRedirectResultsHelper
  
  def braintree_results_failure_rate_percentage(results_count, failures_count)
    (100.0 * failures_count / results_count).round
  end
  
  def braintree_nagios_check_status(failures_count)
    failures_count >= 8 ? "CRITICAL" : (failures_count >= 6 ? "WARNING" : "")
  end
  
end