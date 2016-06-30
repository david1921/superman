require File.dirname(__FILE__) + "/../../test_helper"

class FileMailerTest < ActionMailer::TestCase
  setup do
    ActionMailer::Base.deliveries.clear
  end
  
  context "#file" do
    should "send email with an attachment" do
      file_path = File.expand_path("test/fixtures/files/small.csv", Rails.root)
      email     = FileMailer.deliver_file("anemail@example.com", "My Awesome Subject", file_path)
      
      assert_equal 1, ActionMailer::Base.deliveries.size, "should deliver 1 email"
      assert_equal 1, email.attachments.size, "should have 1 attachment"
      assert_equal ["anemail@example.com"], email.to
      assert_equal "My Awesome Subject", email.subject
    end
  end
end

