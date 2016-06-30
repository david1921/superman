module BrowserTestHelper
  def login_consumer(consumer)
    visit "/publishers/#{consumer.publisher.id}/daily_deal/login"
    fill_in "session_email", :with => consumer.email
    fill_in "session_password", :with => consumer.password
    click_button "sign_in_button"
  end

end