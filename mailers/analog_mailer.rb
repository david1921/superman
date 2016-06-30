class AnalogMailer < ActionMailer::Base

  def daily_purchase_summary_report(publishers_with_totals, currency_code)
    recipients AppConfig.analog_report_recipients
    from       "Analog Analytics <support@analoganalytics.com>"
    subject    "Daily-deal purchase summary (#{currency_code.to_s.upcase})"
    sent_on    Time.now
    body       :publishers_with_totals => publishers_with_totals,
               :currency_symbol => Publisher.currency_symbol_for(currency_code)
  end

  def simple_test_email(to)
    recipients to
    from       "Analog Analytics <support@analoganalytics.com>"
    subject    "Simple Test Email"
    sent_on    Time.now
  end

end

