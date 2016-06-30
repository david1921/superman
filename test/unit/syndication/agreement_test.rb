require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::AgreementTest

module Syndication
  class AgreementTest < ActiveSupport::TestCase
    def test_send_email_on_create
      assert_difference "ActionMailer::Base.deliveries.count" do
        agreement = Factory.build(:agreement)
        agreement.save!
        assert_not_nil agreement.serial_number, "Should generate serial_number"
      end
    end
  end
end