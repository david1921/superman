require File.dirname(__FILE__) + "/../../models_helper"

# hydra class Users::SilverpopSyncTest
module Users
  class SilverpopSyncTest < Test::Unit::TestCase

    context "silverpopsync" do

      setup do
        @silverpop = stub("silverpop")
        @silverpop_sync = stub("silverpop_sync")
        @silverpop_sync.extend(::Users::SilverpopSync)
        @silverpop_sync.stubs(:silverpop).returns(@silverpop)
      end

      context "synchronize with silverpop" do
        should "make all the right moves" do
          @silverpop_sync.expects(:opt_out_of_silverpop_seed_database).once
          @silverpop_sync.expects(:add_to_silverpop_database_if_missing).once
          @silverpop_sync.expects(:remove_from_any_extra_silverpop_contact_lists).once
          @silverpop_sync.expects(:add_to_publishers_silverpop_contact_list_if_missing).once
          @silverpop_sync.synchronize_with_silverpop([])
        end
      end

      context "opt_out_of_silverpop_seed_database_if_needed" do

        should "do nothing if there is no seed database identifier" do
          @silverpop_sync.expects(:silverpop_seed_database_identifier).returns(nil)
          @silverpop_sync.stubs(:email).returns("foobar@yahoo.com")
          @silverpop_sync.opt_out_of_silverpop_seed_database([])
        end

        should "not call silverpop if the recipient is not opted in" do
          @silverpop_sync.stubs(:silverpop_seed_database_identifier).returns("12345")
          @silverpop_sync.stubs(:email).returns("foobar@yahoo.com")
          @silverpop.expects(:recipient_opted_in?).with("12345", "foobar@yahoo.com").returns(false)
          @silverpop_sync.opt_out_of_silverpop_seed_database([])
        end

        should "opt out the recipient from seed database if needs to be opted out" do
          @silverpop_sync.stubs(:silverpop_seed_database_identifier).returns("12345")
          @silverpop_sync.stubs(:email).returns("foobar@yahoo.com")
          @silverpop.stubs(:recipient_opted_in?).returns(true)
          @silverpop.expects(:opt_out_recipient).with("12345", "foobar@yahoo.com").returns(true)
          @silverpop_sync.opt_out_of_silverpop_seed_database([])
        end

      end

      context "add_to_silverpop_database_if_needed" do

        should "do nothing if there is no  database identifier" do
          @silverpop_sync.expects(:silverpop_database_identifier).returns(nil)
          @silverpop_sync.add_to_silverpop_database_if_missing([])
        end

        should "not call silverpop if the recipient already exists" do
          @silverpop_sync.stubs(:silverpop_database_identifier).returns("4566")
          @silverpop_sync.stubs(:email).returns("foobar@yahoo.com")
          @silverpop.expects(:recipient_exists?).with("4566", "foobar@yahoo.com").returns(true)
          @silverpop_sync.add_to_silverpop_database_if_missing([])
        end

        should "opt out the recipient from seed database if needs to be opted out" do
          @silverpop_sync.stubs(:silverpop_database_identifier).returns("4566")
          @silverpop_sync.stubs(:email).returns("foobar@yahoo.com")
          @silverpop.expects(:recipient_exists?).with("4566", "foobar@yahoo.com").returns(false)
          @silverpop.expects(:add_recipient).with("4566", "foobar@yahoo.com")
          @silverpop_sync.add_to_silverpop_database_if_missing([])
        end

      end

      context "remove from any extra silverpop contact lists" do

        should "remove from each contact list that the recpient does not belong to" do
          @silverpop_sync.stubs(:silverpop_database_identifier).returns("4566")
          @silverpop_sync.stubs(:email).returns("foobar@yahoo.com")
          @silverpop_sync.expects(:silverpop_contact_list_identifier).at_least_once.returns("the_right_list")
          @silverpop.expects(:contact_lists_for_recipient).with("4566", "foobar@yahoo.com").returns([ "wrong list 1", "wrong list 2", "the_right_list"])
          @silverpop.expects(:remove_recipient).with("wrong list 1", "foobar@yahoo.com")
          @silverpop.expects(:remove_recipient).with("wrong list 2", "foobar@yahoo.com")
          @silverpop_sync.remove_from_any_extra_silverpop_contact_lists([])
        end

      end


      context "add to publisher's silverpop contact list if missing" do

        setup do
          @silverpop_sync.stubs(:silverpop_database_identifier).returns("4566")
          @silverpop_sync.stubs(:email).returns("foobar@yahoo.com")
          publisher = stub
          publisher.stub_everything
          @silverpop_sync.stubs(:publisher).returns(publisher)
          @silverpop_sync.expects(:silverpop_contact_list_identifier).at_least_once.returns("the_right_list")
        end

        should "add it if missing" do
          @silverpop.expects(:contact_lists_for_recipient).with("4566", "foobar@yahoo.com").returns([ "wrong list 1", "wrong list 2"])
          @silverpop.expects(:add_contact_to_contact_list).with("the_right_list", "foobar@yahoo.com")
          @silverpop_sync.add_to_publishers_silverpop_contact_list_if_missing([])
        end

        should "don't call add if it's there already" do
          @silverpop.expects(:contact_lists_for_recipient).with("4566", "foobar@yahoo.com").returns(["the_right_list"])
          @silverpop.expects(:add_contact_to_contact_list).never
          @silverpop_sync.add_to_publishers_silverpop_contact_list_if_missing([])
        end

      end

    end

  end
end
