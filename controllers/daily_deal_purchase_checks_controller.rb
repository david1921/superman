class DailyDealPurchaseChecksController < ApplicationController

  include ActionView::Helpers::TextHelper
  include Nagios::HttpPlugin

  def ensure_all_captured_and_refunded_purchases_have_vouchers
    purchases_missing_vouchers = DailyDealPurchase.purchases_that_should_have_vouchers_but_dont(:limit => 1)
    if purchases_missing_vouchers.present?
      render_nagios_critical(
        "Found one or more captured or refunded purchases missing vouchers. " +
        "Run 'rake debug:purchases_missing_vouchers' ** on util1 ** for more info.")
    else
      render_nagios_ok("All captured and refunded purchases have vouchers")
    end
  end
  
end
