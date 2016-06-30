require File.dirname(__FILE__) + "/../test_helper"

class EmailRecipientTest < ActionMailer::TestCase
  test "create" do
    assert_difference 'EmailRecipient.count' do
      EmailRecipient.create(:email_address => 'name@example.com')
    end

    assert (email_recipient = EmailRecipient.find_by_email_address("name@example.com"))
    assert email_recipient.email_allowed
    assert_not_nil (code = email_recipient.random_code.try(:to_s))
    assert code.size > 8, "Random code should be fairly long"
    code.each_byte { |byte| assert EmailRecipient::RANDOM_CODE_ALPHABET.include?(byte.chr) }
  end

  test "email address required" do
    assert !EmailRecipient.new(:email_address => '').valid?
  end
  
  test "opt_out" do
    email_recipient = EmailRecipient.create!(:email_address => 'name@example.com')
  
    assert_not_nil email_recipient.opt_out
    assert !email_recipient.email_allowed
    assert email_recipient.email_allowed_before

    assert_not_nil email_recipient.opt_out
    assert !email_recipient.email_allowed
    assert !email_recipient.email_allowed_before
  end
  
  test "trigger_opt_in while opted out" do
    email_recipient = EmailRecipient.create!(:email_address => 'name@example.com')
    assert email_recipient.opt_out
    assert !email_recipient.email_allowed
    assert_not_nil (code1 = email_recipient.random_code.try(:to_s))
  
    email_recipient.trigger_opt_in
    assert_not_nil (code2 = email_recipient.random_code.try(:to_s))
    
    assert !email_recipient.email_allowed, "Email should not be allowed when opted out"
    assert_not_equal code1, code2, "Random code should change when opted out"
    assert ActionMailer::Base.deliveries.any?, "Should generate an email when opted out"
  end

  test "trigger_opt_in while opted in" do
    email_recipient = EmailRecipient.create!(:email_address => 'name@example.com')
    assert email_recipient.email_allowed
    assert_not_nil (code1 = email_recipient.random_code.try(:to_s))
  
    email_recipient.trigger_opt_in
    assert_not_nil (code2 = email_recipient.random_code.try(:to_s))
    
    assert email_recipient.email_allowed, "Email should still be allowed when opted in"
    assert_equal code1, code2, "Random code should not change when opted in"
    assert ActionMailer::Base.deliveries.empty?, "Should not generate an email when opted in"
  end

  test "opt_in while opted out" do
    email_recipient = EmailRecipient.create!(:email_address => 'name@example.com')
    assert email_recipient.opt_out
    assert !email_recipient.email_allowed
  
    assert email_recipient.opt_in
    
    assert !email_recipient.email_allowed_before
    assert email_recipient.email_allowed, "Email should be allowed after opt_in"
  end

  test "opt_in while opted in" do
    email_recipient = EmailRecipient.create!(:email_address => 'name@example.com')
    assert email_recipient.email_allowed
  
    assert email_recipient.opt_in
    
    assert email_recipient.email_allowed_before
    assert email_recipient.email_allowed, "Email should be allowed after opt_in"
  end
  
  def test_random_code_for_with_existing_email
    EmailRecipient.create! :email_address => "ltyagi22@gmail.com"
    assert_not_nil EmailRecipient.random_code_for("ltyagi22@gmail.com")
    assert_equal 1, EmailRecipient.count("email_address='ltyagi22@gmail.com'"), "Should have only one EmailRecipient with email 'ltyagi22@gmail.com'"
  end
end
