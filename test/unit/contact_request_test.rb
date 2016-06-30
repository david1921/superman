require File.dirname(__FILE__) + "/../test_helper"

class ContactRequestTest < ActiveSupport::TestCase

  should "include the Core module" do
    assert_contains ContactRequest.ancestors, ContactRequests::Core
  end

  should "validate the presence of name, email and message" do
    cr = ContactRequest.new
    assert !cr.valid?
    assert_match /blank/, cr.errors[:first_name]
    assert_match /blank/, cr.errors[:last_name]
    assert_match /blank/, cr.errors[:email]
    assert_match /blank/, cr.errors[:message]
  end

  should "validate email" do
    cr = ContactRequest.new(:email => "not an email address")
    assert !cr.valid?
    assert_equal "Email should look like an email address", cr.errors[:email]
  end

end
