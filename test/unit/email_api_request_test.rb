require File.dirname(__FILE__) + "/../test_helper"

class EmailApiRequestTest < ActiveSupport::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end
  
  def test_create
    publisher = publishers(:li_press)
    email_api_request = EmailApiRequest.create(
      :publisher => publisher,
      :email_subject => "test subject",
      :destination_email_address => "user@example.com",
      :text_plain_content => "test plain body"
    )
    assert_not_nil email_api_request
    assert_equal publisher, email_api_request.publisher
    assert_equal "test subject", email_api_request.email_subject
    assert_equal "user@example.com", email_api_request.destination_email_address
    assert_equal "test plain body", email_api_request.text_plain_content
  end

  def test_create_creates_email
    assert_equal 0, ActionMailer::Base.deliveries.size
    assert_difference 'ActionMailer::Base.deliveries.size' do
      publishers(:li_press).email_api_requests.create(
        :email_subject => "test subject",
        :destination_email_address => "user@example.com",
        :text_plain_content => "test plain body"
      )
    end
    email = ActionMailer::Base.deliveries.first
    assert_equal "test subject", email.subject
    assert_match /test plain body/, email.body
  end
end
