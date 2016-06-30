require File.dirname(__FILE__) + "/../../models_helper"
require 'timecop'

# hydra class NewSilverpopRecipients::AddRecipientToSilverpopTest
module NewSilverpopRecipients

  class AddRecipientToSilverpopTest < Test::Unit::TestCase

    module SilverpopDouble
      def open
        yield
      end
    end

    context "add recipient to silverpop" do

      setup do
        @publisher = stub
        @publisher.stubs(:create_silverpop_contact_list_as_needed!)
        @silverpop = stub("silverpop")
        @silverpop.extend(SilverpopDouble)
        @new_silverpop_recipient = stub("new_silverpop_recipient")
        @new_silverpop_recipient.extend(NewSilverpopRecipients::AddRecipientToSilverpop)
        @new_silverpop_recipient.stubs(:silverpop).returns(@silverpop)
        @new_silverpop_recipient.stubs(:publisher).returns(@publisher)
      end

      context "method that calls everything else" do

        should "raise database_id when is missing" do
          @new_silverpop_recipient.expects(:database_id).returns(nil)
          assert_raises RuntimeError do
            @new_silverpop_recipient.add_recipient_to_silverpop
          end
        end

        should "raise if email address is missing" do
          @new_silverpop_recipient.expects(:database_id).returns("ignored")
          @new_silverpop_recipient.expects(:email).returns(nil)
          @new_silverpop_recipient.expects(:consumer).returns(stub("consumer"))
          assert_raises RuntimeError do
            @new_silverpop_recipient.add_recipient_to_silverpop
          end
        end

        should "have a happy happy path" do
          silverpop = stub
          silverpop.extend(SilverpopDouble)
          silverpop.stub_everything
          @new_silverpop_recipient.stubs(:silverpop).returns(silverpop)
          @new_silverpop_recipient.expects(:database_id).at_least_once.returns("not_nil")
          @new_silverpop_recipient.expects(:email).at_least_once.returns("not_nil")
          @new_silverpop_recipient.expects(:capture_silverpop_fields)
          @new_silverpop_recipient.expects(:remove_old_recipient_from_silverpop)
          @new_silverpop_recipient.expects(:opt_out_of_silverpop_seed_database)
          @new_silverpop_recipient.expects(:add_recipient_to_silverpop_database)
          @new_silverpop_recipient.expects(:remove_from_any_extra_silverpop_contact_lists)
          @new_silverpop_recipient.expects(:create_silverpop_contact_list)
          @new_silverpop_recipient.expects(:add_to_silverpop_contact_list)
          @new_silverpop_recipient.expects(:success_at=)
          @new_silverpop_recipient.expects(:save!)
          @new_silverpop_recipient.add_recipient_to_silverpop
        end

        should "record error for error path and re-raise" do
          silverpop = stub
          silverpop.extend(SilverpopDouble)
          silverpop.stub_everything
          @new_silverpop_recipient.stubs(:silverpop).returns(silverpop)
          @new_silverpop_recipient.expects(:database_id).at_least_once.returns("not_nil")
          @new_silverpop_recipient.expects(:email).at_least_once.returns("not_nil")
          @new_silverpop_recipient.expects(:capture_silverpop_fields)
          @new_silverpop_recipient.expects(:remove_old_recipient_from_silverpop)
          @new_silverpop_recipient.expects(:opt_out_of_silverpop_seed_database)
          @new_silverpop_recipient.expects(:add_recipient_to_silverpop_database)
          @new_silverpop_recipient.expects(:remove_from_any_extra_silverpop_contact_lists)
          @new_silverpop_recipient.expects(:create_silverpop_contact_list)
          @new_silverpop_recipient.expects(:add_to_silverpop_contact_list).raises(RuntimeError)
          @new_silverpop_recipient.expects(:error_at=)
          @new_silverpop_recipient.expects(:error_message=)
          @new_silverpop_recipient.expects(:save!)
          assert_raises RuntimeError do
            @new_silverpop_recipient.add_recipient_to_silverpop
          end
        end

      end

      context "opt_out_of_silverpop_seed_database" do

        should "not attempt opt out if there is no seed database id" do
          @new_silverpop_recipient.stubs(:seed_database_id).returns(nil)
          @silverpop.expects(:recipient_exists?).never
          @silverpop.expects(:opt_out_recipient).never
          @new_silverpop_recipient.opt_out_of_silverpop_seed_database
        end

        should "not attempt opt out if the recipient does not exist" do
          @new_silverpop_recipient.stubs(:seed_database_id).returns(123)
          @new_silverpop_recipient.stubs(:email).returns("foobar@yahoo.com")
          @silverpop.expects(:recipient_exists?).returns(false)
          @silverpop.expects(:opt_out_recipient).never
          @new_silverpop_recipient.opt_out_of_silverpop_seed_database
        end

        should "opt out if the recipient already exists" do
          @new_silverpop_recipient.stubs(:seed_database_id).returns(123)
          @new_silverpop_recipient.stubs(:email).returns("foobar@yahoo.com")
          @new_silverpop_recipient.expects(:opted_out_of_silverpop_seed_database_at=)
          @silverpop.expects(:recipient_exists?).returns(true)
          @silverpop.expects(:opt_out_recipient).with(123, "foobar@yahoo.com")
          @new_silverpop_recipient.opt_out_of_silverpop_seed_database
        end
      end

      context "add_recipient_to_silverpop_database" do

        should "not add recipient if recipient already exists" do
          @new_silverpop_recipient.stubs(:database_id).returns(124)
          @new_silverpop_recipient.stubs(:email).returns("foobar@yahoo.com")
          @silverpop.expects(:recipient_exists?).returns(true)
          @silverpop.expects(:add_recipient).never
          @new_silverpop_recipient.add_recipient_to_silverpop_database
        end

        should "add recipient if recipient does not already exist" do
          @new_silverpop_recipient.stubs(:database_id).returns(124)
          @new_silverpop_recipient.stubs(:email).returns("foobar@yahoo.com")
          @new_silverpop_recipient.expects(:recipient_added_to_silverpop_database_at=)
          @silverpop.expects(:recipient_exists?).returns(false)
          @silverpop.expects(:add_recipient).with(124, "foobar@yahoo.com")
          @new_silverpop_recipient.add_recipient_to_silverpop_database
        end

      end

      context "create_contact_list_if_needed" do

        should "create contact list if there's none already" do
          publisher = stub("publisher")
          publisher.expects(:create_silverpop_contact_list_as_needed!)
          @new_silverpop_recipient.stubs(:publisher).returns(publisher)
          @new_silverpop_recipient.create_silverpop_contact_list
        end

      end

      context "remove_old_recipient_from_silverpop" do

        should "do nothing of old_email is not set" do
          @new_silverpop_recipient.stubs(:old_email).returns(nil)
          @new_silverpop_recipient.remove_old_recipient_from_silverpop
        end

        should "call remove recpient if there is an old email set" do
          Timecop.freeze Time.zone.now do
            @new_silverpop_recipient.stubs(:old_email).returns("foobar@yahoo.com")
            @new_silverpop_recipient.stubs(:silverpop_database_identifier).returns(124)
            @silverpop.expects(:remove_recipient).with(124, "foobar@yahoo.com")
            @new_silverpop_recipient.expects(:old_email_removed_at=).with(Time.zone.now)
            @new_silverpop_recipient.remove_old_recipient_from_silverpop
          end
        end

      end

    end

  end
end
