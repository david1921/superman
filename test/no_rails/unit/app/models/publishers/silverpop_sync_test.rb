require File.dirname(__FILE__) + "/../../models_helper"

# hydra class Publishers::SilverpopSyncTest
module Publishers
  class SilverpopSyncTest < Test::Unit::TestCase


    context "silverpop_sync" do

      setup do
        @silverpop = stub("silverpop")
        @silverpop_sync = stub("silverpop_sync")
        @silverpop_sync.extend(Publishers::SilverpopSync)
      end

      context "high level logic" do

        should "not sync subscribers for audit run" do
          @silverpop_sync.expects(:synchronize_subscribers_with_silverpop).never
          @silverpop_sync.expects(:synchronize_consumers_with_silverpop).with(@silverpop, 300).once
          @silverpop_sync.expects(:save_silverpop_audit_run!).once
          @silverpop_sync.synchronize_with_silverpop!(@silverpop, true, 300)
        end

        should "sync subscribers when not audit run" do
          @silverpop_sync.expects(:synchronize_subscribers_with_silverpop).once
          @silverpop_sync.expects(:synchronize_consumers_with_silverpop).with(@silverpop, 300).once
          @silverpop_sync.expects(:save_silverpop_audit_run!).never
          @silverpop_sync.synchronize_with_silverpop!(@silverpop, false, 300)
        end

      end

      context "synchronize_subscribers_with_silverpop" do

        should "call synchronize_with_silverpop on each subscriber" do
          subscribers = [ stub("sub1"), stub("sub2"), stub("sub3") ]
          subscribers[0].expects(:synchronize_with_silverpop)
          subscribers[1].expects(:synchronize_with_silverpop)
          subscribers[2].expects(:synchronize_with_silverpop)
          publishing_group = stub("publishing_group")
          publishing_group.stubs(:silverpop).returns(stub("silverpop"))
          @silverpop_sync.stubs(:publishing_group).returns(publishing_group)
          @silverpop_sync.stubs(:silverpop_audit_run).returns(stub("silverpop_audit_run"))
          @silverpop_sync.expects(:subscribers).returns(subscribers)
          @silverpop_sync.expects(:silverpop_sync_sleep_time).times(3).returns(0)
          @silverpop_sync.expects(:increment_silverpop_contacts_processed_counter).times(3)
          @silverpop_sync.synchronize_subscribers_with_silverpop(@silverpop)
        end

      end

      context "synchronize_consumers_with_silverpop" do

        should "call synchronize_with_silverpop on each consumer with nil audit_size" do
          consumers = [ stub("sub1"), stub("sub2"), stub("sub3") ]
          consumers[0].expects(:synchronize_with_silverpop)
          consumers[1].expects(:synchronize_with_silverpop)
          consumers[2].expects(:synchronize_with_silverpop)
          publishing_group = stub("publishing_group")
          publishing_group.stubs(:silverpop).returns(stub("silverpop"))
          @silverpop_sync.stubs(:publishing_group).returns(publishing_group)
          @silverpop_sync.stubs(:silverpop_audit_run).returns(stub("silverpop_audit_run"))
          @silverpop_sync.expects(:consumers).returns(consumers)
          @silverpop_sync.expects(:silverpop_sync_sleep_time).times(3).returns(0)
          @silverpop_sync.expects(:increment_silverpop_contacts_processed_counter).times(3)
          @silverpop_sync.synchronize_consumers_with_silverpop(@silverpop, nil)
        end

        should "call synchronize_with_silverpop on only audit_size consumers" do
          consumers = [ stub("sub1"), stub("sub2"), stub("sub3") ]
          consumers[0].expects(:synchronize_with_silverpop)
          consumers[1].expects(:synchronize_with_silverpop)
          consumers[2].expects(:synchronize_with_silverpop).never
          publishing_group = stub("publishing_group")
          publishing_group.stubs(:silverpop).returns(stub("silverpop"))
          @silverpop_sync.stubs(:publishing_group).returns(publishing_group)
          @silverpop_sync.stubs(:silverpop_audit_run).returns(stub("silverpop_audit_run"))
          @silverpop_sync.expects(:consumers).returns(consumers)
          @silverpop_sync.expects(:silverpop_sync_sleep_time).times(2).returns(0)
          @silverpop_sync.expects(:increment_silverpop_contacts_processed_counter).times(2)
          @silverpop_sync.synchronize_consumers_with_silverpop(@silverpop, 2)
        end
      end

    end

  end
end

