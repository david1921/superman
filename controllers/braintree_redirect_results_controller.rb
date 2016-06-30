class BraintreeRedirectResultsController < ApplicationController
  layout false
  
  before_filter :user_required
  
  def index
    @braintree_redirect_results = BraintreeRedirectResult.latest_for_distinct_consumers
  end
end
