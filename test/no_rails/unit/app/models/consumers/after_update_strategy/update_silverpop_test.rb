require File.dirname(__FILE__) + "/../../../models_helper"

# hydra class Consumers::AfterPublisherChangedStrategy::UpdateSilverpopTest
module Consumers
  module AfterPublisherChangedStrategy
    class UpdateSilverpopTest < Test::Unit::TestCase

      context "execute" do

        setup do
          @silverpop_updater = Consumers::AfterUpdateStrategy::UpdateSilverpop.new
          @consumer = stub
        end

        should "do nothing if publisher_id_was is nil" do
          @consumer.expects(:email_changed?).returns(false)
          @consumer.expects(:publisher_id_changed?).returns(false)
          @silverpop_updater.expects(:enqueue).never
          @silverpop_updater.execute(@consumer)
        end

        should "create a silverpop list move and queue the resque job" do
          silverpop_list_move = stub
          @consumer.expects(:publisher_id_changed?).returns(true)
          @consumer.expects(:email_changed?).returns(false)
          @silverpop_updater.expects(:create_silverpop_list_move!).with(@consumer).returns(silverpop_list_move)
          @silverpop_updater.expects(:enqueue).with(@consumer, SilverpopListMoves::ResqueJob, silverpop_list_move)
          @silverpop_updater.execute(@consumer)
        end

        should "create a new silverpop recipient and queue the resque job" do
          new_silverpop_recipients = stub
          @consumer.expects(:email_changed?).returns(true)
          @silverpop_updater.expects(:create_new_silverpop_recipient!).with(@consumer).returns(new_silverpop_recipients)
          @silverpop_updater.expects(:enqueue).with(@consumer, NewSilverpopRecipients::ResqueJob, new_silverpop_recipients)
          @silverpop_updater.execute(@consumer)
        end

      end
    end
  end
end
