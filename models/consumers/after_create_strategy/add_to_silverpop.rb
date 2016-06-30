module Consumers
  module AfterCreateStrategy
    class AddToSilverpop

      def execute(consumer)
        new_silverpop_recipient = create_new_silverpop_recipient(consumer)
        consumer.enqueue_resque_job_after_commit(NewSilverpopRecipients::ResqueJob, new_silverpop_recipient.id)
      end

      def create_new_silverpop_recipient(consumer)
        NewSilverpopRecipient.create!(:consumer => consumer)
      end

    end
  end
end
