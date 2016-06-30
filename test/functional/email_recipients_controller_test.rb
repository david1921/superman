require File.dirname(__FILE__) + "/../test_helper"

class EmailRecipientsControllerTest < ActionController::TestCase
  setup :clear_deliveries
  
  def clear_deliveries
    ActionMailer::Base.deliveries.clear
  end
  
  test "opt_out while opted in" do
    assert((email_recipient = EmailRecipient.find_or_create_by_email_address("name@example.com")))
    assert email_recipient.email_allowed, "Email should be allowed initially"
    
    get :opt_out, :random_code => email_recipient.random_code
    
    assert_response :success
    assert !email_recipient.reload.email_allowed, "Email should not be allowed after opting out"
    assert_layout "txt411/application"
    assert_txt411_content Regexp.new(email_recipient.email_address)
    assert_txt411_content /to our do-not-email list/i
  end

  test "opt_out while opted out" do
    assert((email_recipient = EmailRecipient.find_or_create_by_email_address("name@example.com")))
    assert email_recipient.update_attribute(:email_allowed, false)
    
    get :opt_out, :random_code => email_recipient.random_code
    
    assert_response :success
    assert !email_recipient.reload.email_allowed, "Email should not be allowed after opting out"
    assert_layout "txt411/application"
    assert_txt411_content Regexp.new(email_recipient.email_address)
    assert_txt411_content /on our do-not-email list/i
  end
  
  test "trigger_opt_in while opted out" do
    assert((email_recipient = EmailRecipient.find_or_create_by_email_address("name@example.com")))
    assert email_recipient.update_attribute(:email_allowed, false)
    
    get :trigger_opt_in, :random_code => email_recipient.random_code
    
    assert_response :success
    assert !email_recipient.reload.email_allowed, "Email should not be allowed"
    assert_layout "txt411/application"
    assert_txt411_content Regexp.new(email_recipient.email_address)
    assert_txt411_content /sent you an email message/i
    
    assert_equal 1, ActionMailer::Base.deliveries.size, "Should have one email delivery"
    delivery = ActionMailer::Base.deliveries.first
    assert_equal [email_recipient.email_address], delivery.to, "Should deliver only to email recipient"
    assert !delivery.subject.empty?
    assert_match(confirm_email_opt_in_path(:random_code => email_recipient.random_code), delivery.body,
                 "Should contain link to confirm email opt-in")
  end

  test "trigger_opt_in while opted in" do
    assert((email_recipient = EmailRecipient.find_or_create_by_email_address("name@example.com")))
    assert email_recipient.email_allowed, "Email should be allowed initially"
    
    get :trigger_opt_in, :random_code => email_recipient.random_code
    
    assert_response :success
    assert email_recipient.reload.email_allowed, "Email should still be allowed"
    assert_layout "txt411/application"
    assert_txt411_content /already opted/i

    assert_equal 0, ActionMailer::Base.deliveries.size, "Should not deliver any email"
  end
  
  test "confirm_opt_in while opted out" do
    assert((email_recipient = EmailRecipient.find_or_create_by_email_address("name@example.com")))
    assert email_recipient.update_attribute(:email_allowed, false)
    
    get :confirm_opt_in, :random_code => email_recipient.random_code
    
    assert_response :success
    assert email_recipient.reload.email_allowed, "Email should be allowed after confirm_opt_in"
    assert_layout "txt411/application"
    assert_txt411_content /complete/i
  end

  test "confirm_opt_in while opted in" do
    assert((email_recipient = EmailRecipient.find_or_create_by_email_address("name@example.com")))
    assert email_recipient.email_allowed, "Email should be allowed initially"
    
    get :confirm_opt_in, :random_code => email_recipient.random_code
    
    assert_response :success
    assert email_recipient.reload.email_allowed, "Email should be allowed after confirm_opt_in"
    assert_layout "txt411/application"
        assert_txt411_content /complete/i
  end
  
  private
  
  def assert_txt411_content(match)
    path  = "div.main div.column2 div.indent div.box2 div.righttall div.lefttall "
    path += "div.bot_right div.bot_left div.toptall div.top_right div.top_left div"
    assert_select path, match
  end
end
