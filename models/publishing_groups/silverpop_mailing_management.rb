 module PublishingGroups
  module SilverpopMailingManagement

    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods

      def synchronize_users_that_have_failed_rows(limit = nil)
        limit = limit.to_i if limit

        find_args_hash = { :conditions => "publishers.publishing_group_id = #{self.id} AND success_at IS NULL", 
                           :include => {:consumer => { :publisher => :publishing_group }}}
        find_args_hash[:limit] = limit if limit
        find_args = [:all, find_args_hash]

        new_recipients = NewSilverpopRecipient.find(*find_args)
        find_args_hash[:limit] = limit - new_recipients.count if limit
        list_moves = SilverpopListMove.find(*find_args)

        limit_text = limit ? "with a limit of #{limit}" : ""
        say "Will fix #{new_recipients.count} recipients and #{list_moves.count} list moves..."
        synched_consumer_ids = Set.new
        silverpop.open do |_unused|
          (new_recipients + list_moves).each_with_index do |silverpop_item, index|
            break if limit && index >= limit
            say "    synching #{silverpop_item.consumer.email} from #{silverpop_item.class.name} ##{silverpop_item.id}"

            begin
              NewSilverpopRecipient.transaction do
                sync_consumer_with_silverpop(silverpop_item.consumer, silverpop) unless synched_consumer_ids.include?(silverpop_item.consumer_id)               
                silverpop_item.update_attributes!(:memo => "Synched with silverpop:synchronize_users_that_have_failed_rows", :success_at => Time.zone.now)
              end
              synched_consumer_ids << silverpop_item.consumer.id
            rescue Exception => e
              Exceptional.handle(e)
              silverpop_item.update_attributes!(:error_at => Time.zone.now)
            end
          end
        end
        say "Synched #{synched_consumer_ids.size} consumers"
      end

      private
      def sync_consumer_with_silverpop(consumer, silverpop)
        consumer.synchronize_with_silverpop!(silverpop)
      end

    end

  end
end