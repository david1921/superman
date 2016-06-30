require File.dirname(__FILE__) + "/../../../../test_helper"
require 'timecop'

class SilverpopTest < Test::Unit::TestCase

  context "schedule_mailing_request" do

    should "be able to schedule valid request" do
      Timecop.freeze Time.utc(2012, 12, 10, 10, 15) do
        silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
        options = {
          :template_id => "1234",
          :list_id => "4567",
          :mailing_name => "abcd",
          :send_at => Time.zone.now,
          :subject => "I have been meaning to talk to you",
          :from_name => "Foo Barinski",
          :from_address => "3440 SE Sherman St",
          :reply_to => "foobar@yahoo.com"
        }
        request_hash = silverpop.schedule_mailing_request(options)
        assert_not_nil request_hash
        scheduled_mailing = request_hash["ScheduleMailing"]
        assert_not_nil scheduled_mailing
        assert_equal "Foo Barinski", scheduled_mailing["FROM_NAME"]
        assert_equal "abcd", scheduled_mailing["MAILING_NAME"]
        assert_equal "3440 SE Sherman St", scheduled_mailing["FROM_ADDRESS"]
        assert_equal "1234", scheduled_mailing["TEMPLATE_ID"]
        assert_equal "I have been meaning to talk to you", scheduled_mailing["SUBJECT"]
        assert_equal "TRUE", scheduled_mailing["SEND_HTML"]
        assert_equal "12/10/2012 10:15:00 AM", scheduled_mailing["SCHEDULED"]
        assert_equal "foobar@yahoo.com", scheduled_mailing["REPLY_TO"]
        assert_equal "4567", scheduled_mailing["LIST_ID"]
        assert_equal "1", scheduled_mailing["VISIBILITY"]
      end
    end

  end

  context "create_contact_list" do

    should "be able to create a contact list request" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      options = {
        :database_id => 1234,
        :contact_list_name => "bcbsany"
      }
      request_hash = silverpop.create_contact_list_request(options)
      assert_not_nil request_hash
      create_contact_list = request_hash["CreateContactList"]
      assert_not_nil create_contact_list
      assert_equal "1234", create_contact_list["DATABASE_ID"]
      assert_equal "bcbsany", create_contact_list["CONTACT_LIST_NAME"]
      assert_equal "0", create_contact_list["VISIBILITY"]
    end

    should "return the contact list id from the response on a success" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      silverpop.stubs(:execute_silverpop_request).returns({ "SUCCESS" => "TRUE", "CONTACT_LIST_ID" => "998877" })
      contact_list_id = silverpop.create_contact_list(1234, "foobar" )
      assert_equal "998877", contact_list_id
    end

    should "be grumpy if no database_id" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      assert_raises RuntimeError do
        silverpop.stubs(:execute_silverpop_request).returns({ "SUCCESS" => "TRUE", "CONTACT_LIST_ID" => "998877" })
        silverpop.create_contact_list(nil, "bcbsafoo" );
      end
    end

    should "be grumpy if no contact_list_name" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      assert_raises RuntimeError do
        silverpop.stubs(:execute_silverpop_request).returns({ "SUCCESS" => "TRUE", "CONTACT_LIST_ID" => "998877" })
        silverpop.create_contact_list(1234, nil);
      end
    end

  end

  context "add_recipient" do

    should "be able to create an add recipient request" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      options = {
        :list_id => 1234,
        :email => "foosball@yahoo.com"
      }
      request_hash = silverpop.add_recipient_request(options)
      assert_not_nil request_hash
      add_recipient_request = request_hash["AddRecipient"]
      assert_not_nil add_recipient_request
      assert_equal "1234", add_recipient_request["LIST_ID"]
      column = add_recipient_request["COLUMN"]
      assert_not_nil column
      assert_equal "EMAIL", column["NAME"]
      assert_equal "foosball@yahoo.com", column["VALUE"]
    end

    should "return recipient id" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      silverpop.stubs(:execute_silverpop_request).returns({ "SUCCESS" => "TRUE", "RecipientId" => "667" })
      recipient_id = silverpop.add_recipient(1234, "foobar@yahoo.com")
      assert_equal "667", recipient_id
    end

  end

  context "opt_out_recipient" do

    should "be able to create an add recipient request" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      options = {
        :list_id => 1234,
        :email => "foosball@yahoo.com"
      }
      request_hash = silverpop.opt_out_recipient_request(options)
      assert_not_nil request_hash
      add_recipient_request = request_hash["OptOutRecipient"]
      assert_not_nil add_recipient_request
      assert_equal "1234", add_recipient_request["LIST_ID"]
      assert_equal "foosball@yahoo.com", add_recipient_request["EMAIL"]
    end

    should "returns true" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      silverpop.stubs(:execute_silverpop_request).returns({ "SUCCESS" => "TRUE" })
      result = silverpop.opt_out_recipient(1234, "foobar@yahoo.com")
      assert_equal true, result
    end

  end

  context "add_contact_to_contact_list" do

    should "make a damn good request" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      options = {
        :contact_list_id => 4567,
        :email => "foosball@yahoo.com"
      }
      request_hash = silverpop.add_contact_to_contact_list_request(options)
      assert_not_nil request_hash
      add_recipient_request = request_hash["AddContactToContactList"]
      assert_not_nil add_recipient_request
      assert_equal "4567", add_recipient_request["CONTACT_LIST_ID"]
      column = add_recipient_request["COLUMN"]
      assert_not_nil column
      assert_equal "EMAIL", column["NAME"]
      assert_equal "foosball@yahoo.com", column["VALUE"]
    end

    should "returns true" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      silverpop.stubs(:execute_silverpop_request).returns({ "SUCCESS" => "TRUE" })
      result = silverpop.add_contact_to_contact_list(1234, "foobar@yahoo.com")
      assert_equal true, result
    end

  end

  context "remove_recipient" do

    should "be able to create an remove recipient request" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      options = {
        :list_id => 1234,
        :email => "foosball@yahoo.com"
      }
      request_hash = silverpop.remove_recipient_request(options)
      assert_not_nil request_hash
      remove_recipient_request = request_hash["RemoveRecipient"]
      assert_not_nil remove_recipient_request
      assert_equal "1234", remove_recipient_request["LIST_ID"]
      assert_equal "foosball@yahoo.com", remove_recipient_request["EMAIL"]
    end

    should "return recipient id" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      silverpop.stubs(:execute_silverpop_request).returns({ "SUCCESS" => "TRUE", "RecipientId" => "667" })
      result = silverpop.remove_recipient(1234, "foobar@yahoo.com")
      assert_equal true, result
    end

  end

  context "select_recipient" do
    should "make the correct request" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      options = {
        :list_id => 1234,
        :email => "foosball@yahoo.com"
      }
      request_hash = silverpop.select_recipient_request(options)
      assert_not_nil request_hash
      request = request_hash["SelectRecipientData"]
      assert_not_nil request
      assert_equal "1234", request["LIST_ID"]
      assert_equal "foosball@yahoo.com", request["EMAIL"]
      assert_equal "true", request["RETURN_CONTACT_LISTS"]
    end
    should "return whatever execute_silverpop_request returns" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      response = { :lots => "of stuff" }
      silverpop.stubs(:execute_silverpop_request).returns(response)
      result = silverpop.select_recipient(1234, "foobar@yahoo.com")
      assert_equal response, result
    end
    should "return nil if there's a recipient not found error" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      silverpop.stubs(:execute_silverpop_request).raises(SilverpopError.new(128, "recipient not found"))
      result = silverpop.select_recipient(1234, "foobar@yahoo.com")
      assert_nil result
    end
    should "raise if it's not a recipient not found error" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      silverpop.stubs(:execute_silverpop_request).raises(SilverpopError.new(129, "some other error"))
      assert_raises SilverpopError do
        silverpop.select_recipient(1234, "foobar@yahoo.com")
      end
    end
  end

  context "recipient_opted_in?" do
    should "be true if there is an opted in date but no opted out date" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      silverpop.stubs(:execute_silverpop_request).returns({ "SUCCESS" => "TRUE", "OptedIn" => "some non nil date" })
      assert_equal true, silverpop.recipient_opted_in?(1234, "foobar@yahoo.com")
    end
    should "be false if there is an opted in date and and opted out date" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      silverpop.stubs(:execute_silverpop_request).returns({ "SUCCESS" => "TRUE", "OptedIn" => "some non nil date", "OptedOut" => "some non nil date" })
      assert_equal false, silverpop.recipient_opted_in?(1234, "foobar@yahoo.com")
    end
    should "be false if recipient is not found" do
      silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
      silverpop.stubs(:execute_silverpop_request).raises(SilverpopError.new(128, "recipient not found"))
      assert_equal false, silverpop.recipient_opted_in?(1234, "foobar@yahoo.com")
    end
  end

  context "email is lower case in silverpop" do

    setup do
      @silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
    end

    should "lower case email for #prepare_options_for_silverpop :email attribute" do
      result = @silverpop.prepare_options_for_silverpop({ :do_not_touch => "YeahYeah", :email => "FooBar@yahoo.com"})
      assert_equal "foobar@yahoo.com", result[:email]
      assert_equal "YeahYeah", result[:do_not_touch]
    end

    should "lower case email for EMAIL column" do
      result = @silverpop.prepare_options_for_silverpop({:column=>{:value=>"FooBar@yahoo.com", :name=>"EMAIL"}, :list_id=>1234, :created_from=>2})
      assert_equal "foobar@yahoo.com", result[:column][:value]
    end

    should "not touch a non email column" do
      result = @silverpop.prepare_options_for_silverpop({:column=>{:value=>"FooBar@yahoo.com", :name=>"NOTEMAIL"}, :list_id=>1234, :created_from=>2})
      assert_equal "FooBar@yahoo.com", result[:column][:value]
    end

    should "work if there's nothing to do with email" do
      @silverpop.prepare_options_for_silverpop(nil)
    end

    should "work on an empty hash" do
      assert_equal Hash.new, @silverpop.prepare_options_for_silverpop({})
    end

    should "work on an email column with no value" do
      result = @silverpop.prepare_options_for_silverpop({:column=>{:value=>nil, :name=>"EMAIL"}, :list_id=>1234, :created_from=>2})
      assert_nil result[:column][:value]
    end

  end

  context "scheduled_time_in_silverpop_format" do

    setup do
      @silverpop = Analog::ThirdPartyApi::Silverpop.new("foo", "bar", "pass")
    end

    should "convert to utc if no time zone is specified" do
      the_time = Time.utc(2012, 2, 8, 13, 47)
      Timecop.freeze the_time.in_time_zone("Pacific Time (US & Canada)") do
        assert_equal "02/08/2012 01:47:00 PM", @silverpop.scheduled_time_in_silverpop_format({ :send_at => the_time})
      end
    end

    should "convert to utc if time zone is blank" do
      the_time = Time.utc(2012, 2, 8, 13, 47)
      Timecop.freeze the_time.in_time_zone("Pacific Time (US & Canada)") do
        assert_equal "02/08/2012 01:47:00 PM", @silverpop.scheduled_time_in_silverpop_format({ :send_at => the_time, :time_zone => "" })
      end
    end

    should "convert to time zone if specified" do
      the_time = Time.utc(2012, 2, 8, 13, 47)
      Timecop.freeze the_time.in_time_zone("Pacific Time (US & Canada)") do
        assert_equal "02/08/2012 05:47:00 AM", @silverpop.scheduled_time_in_silverpop_format({ :send_at => the_time, :time_zone => "Pacific Time (US & Canada)" })
      end
    end

  end

end
