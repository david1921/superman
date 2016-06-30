module Consumers
  module AfterUpdateStrategy
    class UpdateSilverpop

      def execute(consumer)
        if consumer.email_changed?
          new_silverpop_recipient = create_new_silverpop_recipient!(consumer)
          enqueue(consumer, NewSilverpopRecipients::ResqueJob, new_silverpop_recipient)
        elsif consumer.publisher_id_changed?
          silverpop_list_move = create_silverpop_list_move!(consumer)
          enqueue(consumer, SilverpopListMoves::ResqueJob, silverpop_list_move)
        end
      end

      def enqueue(consumer, klass, arg)
        consumer.enqueue_resque_job_after_commit(klass, arg.id)
      end

      def create_silverpop_list_move!(consumer)
        SilverpopListMove.create!(:consumer => consumer,
                                  :old_publisher => old_publisher(consumer),
                                  :new_publisher => new_publisher(consumer),
                                  :old_list_identifier => old_publisher(consumer).silverpop_list_identifier,
                                  :new_list_identifier => new_publisher(consumer).silverpop_list_identifier)

      end

      def create_new_silverpop_recipient!(consumer)
        NewSilverpopRecipient.create!(:consumer => consumer, :old_email => consumer.email_was)
      end

      def old_publisher(consumer)
        @old_publisher ||= Publisher.find(consumer.publisher_id_was)
      end

      def new_publisher(consumer)
        consumer.publisher
      end

    end
  end
end
