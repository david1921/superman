require File.dirname(__FILE__) + "/../../test_helper"

class ContactRequests::CoreTest < ActiveSupport::TestCase
  should "deliver a support contact request email" do
    @scr = SupportContactRequest.new(
        :publisher => Factory(:publisher), :first_name => "John", :last_name => "Doe", :email => "jd@aa.com",
        :message => "this is my message", :reason_for_request => "I need help",
        :email_subject_format => "Support Request - {{first_name}} {{ last_name }}"
    )
    assert @scr.valid?
    assert_difference "ActionMailer::Base.deliveries.size" do
      @scr.deliver
    end
    assert_equal "Support Request - John Doe", ActionMailer::Base.deliveries.last.subject
  end
end