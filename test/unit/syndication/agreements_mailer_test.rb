require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::AgreementsMailerTest
module Syndication
  class AgreementsMailerTest < ActionMailer::TestCase
    def test_confirmation
      agreement = Factory.build(:agreement, :distribution_publisher => true)
      agreement.save!
      email = AgreementsMailer.deliver_confirmation(agreement)
      assert_equal [ agreement.email ], email.to
      assert_equal [ "info@analoganalytics.com" ], email.from
      assert_equal [ "legal@analoganalytics.com", "info@analoganalytics.com" ], email.bcc
      assert_equal "Analog Analytics Syndication Agreement", email.subject
      assert email.body["Distribution Publisher"], "Email body should include 'Distribution Publisher' in:\n #{email.body}"
      assert email.body[agreement.serial_number.to_s], "Email body should include serial number in:\n #{email.body}"
    end
  end
end