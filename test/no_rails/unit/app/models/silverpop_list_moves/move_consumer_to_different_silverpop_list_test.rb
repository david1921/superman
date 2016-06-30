require File.dirname(__FILE__) + "/../../models_helper"

# hydra class SilverpopListMoves::MoveConsumerToDifferentSilverpopListTest
module SilverpopListMoves
  class MoveConsumerToDifferentSilverpopListTest < Test::Unit::TestCase

    module SilverpopDouble
      def open
        yield "session"
      end
    end

    context "move consumer to different silverpop list" do

      setup do
        @silverpop = stub("silverpop")
        @silverpop.extend(SilverpopDouble)
        @silverpop_list_move = stub("new_silverpop_recipient")
        @silverpop_list_move.extend(SilverpopListMoves::MoveConsumerToDifferentSilverpopList)
        @silverpop_list_move.stubs(:silverpop).returns(@silverpop)
      end

      context "move_consumer_to_different_silverpop_list" do

        should "have a happy happy path" do
          @silverpop_list_move.expects(:verify_consumer_exists!)
          @silverpop_list_move.expects(:remove_from_old_list)
          @silverpop_list_move.expects(:add_to_new_list)
          @silverpop_list_move.expects(:save!)
          @silverpop_list_move.move_consumer_to_different_silverpop_list
        end

        should "capture errors and save if there's an exception" do
          @silverpop_list_move.expects(:verify_consumer_exists!)
          @silverpop_list_move.expects(:remove_from_old_list)
          @silverpop_list_move.stubs(:add_to_new_list).raises(RuntimeError)
          @silverpop_list_move.expects(:error_at=)
          @silverpop_list_move.expects(:error_message=)
          @silverpop_list_move.expects(:save!)
          @silverpop_list_move.move_consumer_to_different_silverpop_list
        end

      end

      context "verify consumer exists" do

        setup do
          @silverpop_list_move.stubs(:database_id).returns(1234)
          @silverpop_list_move.stubs(:email).returns("foobar@yahoo.com")
        end

        should "not raise if consumer already exist" do
          @silverpop.expects(:recipient_exists?).returns(true)
          @silverpop_list_move.verify_consumer_exists!
        end

        should "raise if consumer does not exist" do
          @silverpop.expects(:recipient_exists?).returns(false)
          assert_raises RuntimeError do
            @silverpop_list_move.verify_consumer_exists!
          end
        end

      end

      context "remove from list" do

        setup do
          @silverpop_list_move.stubs(:database_id).returns(1234)
          @silverpop_list_move.stubs(:email).returns("foobar@yahoo.com")
          @silverpop_list_move.stubs(:old_list_id).returns(8989)
        end

        should "remove from list and set the time" do
          @silverpop.expects(:remove_recipient).with(8989, "foobar@yahoo.com")
          @silverpop_list_move.expects(:removed_from_old_list_at=)
          @silverpop_list_move.remove_from_old_list
        end

      end

      context "add to list" do

        setup do
          @silverpop_list_move.stubs(:database_id).returns(1234)
          @silverpop_list_move.stubs(:email).returns("foobar@yahoo.com")
          @silverpop_list_move.stubs(:new_list_id).returns(7766)
        end

        should "remove from list and set the time" do
          @silverpop.expects(:add_contact_to_contact_list).with(7766, "foobar@yahoo.com")
          @silverpop_list_move.expects(:added_to_new_list_at=)
          @silverpop_list_move.add_to_new_list
        end

      end
    end

  end

end
