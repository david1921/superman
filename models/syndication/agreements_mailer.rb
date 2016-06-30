module Syndication
  class AgreementsMailer < ActionMailer::Base
    def confirmation(agreement)
      subject "Analog Analytics Syndication Agreement"
      recipients agreement.email
      from "info@analoganalytics.com"
      bcc [ "legal@analoganalytics.com", "info@analoganalytics.com" ]
      body :agreement => agreement
    end
  end
end
