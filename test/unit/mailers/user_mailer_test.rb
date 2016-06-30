require File.dirname(__FILE__) + "/../../test_helper"

class UserMailerTest < ActionMailer::TestCase
  context "UserMailer" do
    setup do
      @user = Factory(:user, :email => "jorgeb@dimilles.com")
      @user.publisher.update_attributes(:name => "Valley News")
      @user.reset_perishable_token!

      ActionMailer::Base.deliveries.clear
    end

    context "deliver_account_setup_instructions" do
      should "not send if user email address is blank" do
        @user.update_attributes! :email => ""
        UserMailer.deliver_account_setup_instructions(@user)
        assert_equal 0, ActionMailer::Base.deliveries.size, "Should not generate an email"
      end

      context "given a user with a publisher as a company" do
        should "deliver email" do
          @user.publisher.update_attributes!(
            :support_email_address => "support@sdhaustin.com",
            :approval_email_address => "approval@sdhaustin.com"
          )

          UserMailer.deliver_account_setup_instructions(@user)

          assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email"
          email = ActionMailer::Base.deliveries.first

          assert_equal ["support@sdhaustin.com"], email.from, "From: header"
          assert_equal "Valley News", email.friendly_from, "From: header (friendly)"
          assert_equal ["jorgeb@dimilles.com"], email.to, "To: header"
          assert_equal ["approval@sdhaustin.com"], email.bcc, "Should BCC approval email"
          assert_equal "Valley News Account Setup", email.subject, "Subject: header"
          assert_equal "multipart/alternative", email.content_type, "Content-Type: header"

          assert_equal 1, email.parts.size, "Should have 1 part"

          part = email.parts.first
          assert_equal "text/plain", part.content_type, "Content-Type: of first part"
          assert_equal "quoted-printable", part.transfer_encoding, "Content-Transfer-Encoding: of first part"
          assert_match(/http:\/\/[^\/]+#{Regexp.escape("/password_resets/#{@user.perishable_token}/edit")}/i, part.body)
          assert_match(/support@sdhaustin\.com/, part.body)
        end

        should "respect publisher support email address" do
          @user.publisher.update_attributes!(
            :support_email_address => "Student Discount <support@sdhaustin.com>"
          )

          UserMailer.deliver_account_setup_instructions(@user)
          email = ActionMailer::Base.deliveries.first

          assert_equal ["support@sdhaustin.com"], email.from, "From: header"
          assert_equal "Student Discount", email.friendly_from, "From: header (friendly)"

          part = email.parts.first
          assert_match(/support@sdhaustin\.com/, part.body)
        end
      end

      context "given a user with a publishing group as a company" do
        setup do
          publishing_group = Factory(:publishing_group, :name => "XYZ News")
          @user.user_companies.destroy_all
          @user.user_companies.create(:company => publishing_group)
        end

        should "deliver email" do
          assert !@user.publisher

          UserMailer.deliver_account_setup_instructions(@user)

          assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email"
          email = ActionMailer::Base.deliveries.first

          assert_equal ["support@analoganalytics.com"], email.from, "From: header"
          assert_equal "XYZ News", email.friendly_from, "From: header (friendly)"
          assert_equal ["jorgeb@dimilles.com"], email.to, "To: header"
          assert_equal nil, email.bcc
          assert_equal "XYZ News Account Setup", email.subject, "Subject: header"

          part = email.parts.first
          assert_match(/support@analoganalytics\.com/, part.body)
        end
      end

      context "given a user with no company" do
        setup do
          @user.user_companies.destroy_all
        end

        should "deliver email" do
          UserMailer.deliver_account_setup_instructions(@user)

          assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email"
          email = ActionMailer::Base.deliveries.first

          assert_equal ["support@analoganalytics.com"], email.from, "From: header"
          assert_equal "Analog Analytics", email.friendly_from, "From: header (friendly)"
          assert_equal ["jorgeb@dimilles.com"], email.to, "To: header"
          assert_equal "Analog Analytics Account Setup", email.subject, "Subject: header"

          part = email.parts.first
          assert_match(/support@analoganalytics\.com/, part.body)
        end
      end

    end

    context "deliver_account_reactivation_instructions" do
      should "not send if user email address is blank" do
        @user.update_attributes! :email => ""
        UserMailer.deliver_account_reactivation_instructions(@user)
        assert_equal 0, ActionMailer::Base.deliveries.size, "Should not generate an email"
      end

      context "given a user with a publisher as a company" do
        should "deliver email" do
          @user.publisher.update_attributes!(:support_email_address => "support@sdhaustin.com")

          UserMailer.deliver_account_reactivation_instructions(@user)

          assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email"
          email = ActionMailer::Base.deliveries.first

          assert_equal ["support@sdhaustin.com"], email.from, "From: header"
          assert_equal "Valley News", email.friendly_from, "From: header (friendly)"
          assert_equal ["jorgeb@dimilles.com"], email.to, "To: header"
          assert_equal "Valley News Account Reactivation", email.subject, "Subject: header"
          assert_equal "multipart/alternative", email.content_type, "Content-Type: header"

          assert_equal 1, email.parts.size, "Should have 1 part"

          part = email.parts.first
          assert_equal "text/plain", part.content_type, "Content-Type: of first part"
          assert_equal "quoted-printable", part.transfer_encoding, "Content-Transfer-Encoding: of first part"
          assert_match(/http:\/\/[^\/]+#{Regexp.escape("/password_resets/#{@user.perishable_token}/edit")}/i, part.body)
          assert_match(/support@sdhaustin\.com/, part.body)
        end

        should "respect publisher support email address" do
          @user.publisher.update_attributes!(
            :support_email_address => "Student Discount <support@sdhaustin.com>"
          )

          UserMailer.deliver_account_reactivation_instructions(@user)
          email = ActionMailer::Base.deliveries.first

          assert_equal ["support@sdhaustin.com"], email.from, "From: header"
          assert_equal "Student Discount", email.friendly_from, "From: header (friendly)"

          part = email.parts.first
          assert_match(/support@sdhaustin\.com/, part.body)
        end
      end

      context "given a user with a publishing group as a company" do
        setup do
          publishing_group = Factory(:publishing_group, :name => "XYZ News")
          @user.user_companies.destroy_all
          @user.user_companies.create(:company => publishing_group)
        end

        should "deliver email" do
          assert !@user.publisher

          UserMailer.deliver_account_reactivation_instructions(@user)

          assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email"
          email = ActionMailer::Base.deliveries.first

          assert_equal ["support@analoganalytics.com"], email.from, "From: header"
          assert_equal "XYZ News", email.friendly_from, "From: header (friendly)"
          assert_equal ["jorgeb@dimilles.com"], email.to, "To: header"
          assert_equal "XYZ News Account Reactivation", email.subject, "Subject: header"

          part = email.parts.first
          assert_match(/support@analoganalytics\.com/, part.body)
        end
      end

      context "given a user with no company" do
        setup do
          @user.user_companies.destroy_all
        end

        should "deliver email" do
          UserMailer.deliver_account_reactivation_instructions(@user)

          assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email"
          email = ActionMailer::Base.deliveries.first

          assert_equal ["support@analoganalytics.com"], email.from, "From: header"
          assert_equal "Analog Analytics", email.friendly_from, "From: header (friendly)"
          assert_equal ["jorgeb@dimilles.com"], email.to, "To: header"
          assert_equal "Analog Analytics Account Reactivation", email.subject, "Subject: header"

          part = email.parts.first
          assert_match(/support@analoganalytics\.com/, part.body)
        end
      end

    end

    context "deliver_password_reset_instructions" do
      should "not send if user email address is blank" do
        @user.update_attributes! :email => ""
        UserMailer.deliver_password_reset_instructions(@user)
        assert_equal 0, ActionMailer::Base.deliveries.size, "Should not generate an email"
      end

      context "given a user with a publisher as a company" do
        should "deliver email" do
          @user.publisher.update_attributes!(:support_email_address => "support@sdhaustin.com")

          UserMailer.deliver_password_reset_instructions(@user)

          assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email"
          email = ActionMailer::Base.deliveries.first

          assert_equal ["support@sdhaustin.com"], email.from, "From: header"
          assert_equal "Valley News", email.friendly_from, "From: header (friendly)"
          assert_equal ["jorgeb@dimilles.com"], email.to, "To: header"
          assert_equal "Valley News Password Reset", email.subject, "Subject: header"
          assert_equal "multipart/alternative", email.content_type, "Content-Type: header"

          assert_equal 1, email.parts.size, "Should have 1 part"

          part = email.parts.first
          assert_equal "text/plain", part.content_type, "Content-Type: of first part"
          assert_equal "quoted-printable", part.transfer_encoding, "Content-Transfer-Encoding: of first part"
          assert_match(/http:\/\/[^\/]+#{Regexp.escape("/password_resets/#{@user.perishable_token}/edit")}/i, part.body)
          assert_match(/support@sdhaustin\.com/, part.body)
        end

        should "respect publisher support email address" do
          @user.publisher.update_attributes!(
            :support_email_address => "Student Discount <support@sdhaustin.com>"
          )

          UserMailer.deliver_password_reset_instructions(@user)
          email = ActionMailer::Base.deliveries.first

          assert_equal ["support@sdhaustin.com"], email.from, "From: header"
          assert_equal "Student Discount", email.friendly_from, "From: header (friendly)"

          part = email.parts.first
          assert_match(/support@sdhaustin\.com/, part.body)
        end
      end

      context "given a user with a publishing group as a company" do
        setup do
          publishing_group = Factory(:publishing_group, :name => "XYZ News")
          @user.user_companies.destroy_all
          @user.user_companies.create(:company => publishing_group)
        end

        should "deliver email" do
          assert !@user.publisher

          UserMailer.deliver_password_reset_instructions(@user)

          assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email"
          email = ActionMailer::Base.deliveries.first

          assert_equal ["support@analoganalytics.com"], email.from, "From: header"
          assert_equal "XYZ News", email.friendly_from, "From: header (friendly)"
          assert_equal ["jorgeb@dimilles.com"], email.to, "To: header"
          assert_equal "XYZ News Password Reset", email.subject, "Subject: header"

          part = email.parts.first
          assert_match(/support@analoganalytics\.com/, part.body)
        end
      end

      context "given a user with no company" do
        setup do
          @user.user_companies.destroy_all
        end

        should "deliver email" do
          UserMailer.deliver_password_reset_instructions(@user)

          assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email"
          email = ActionMailer::Base.deliveries.first

          assert_equal ["support@analoganalytics.com"], email.from, "From: header"
          assert_equal "Analog Analytics", email.friendly_from, "From: header (friendly)"
          assert_equal ["jorgeb@dimilles.com"], email.to, "To: header"
          assert_equal "Analog Analytics Password Reset", email.subject, "Subject: header"

          part = email.parts.first
          assert_match(/support@analoganalytics\.com/, part.body)
        end
      end
    end
  end
end
