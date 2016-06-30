module Consumers
  module AfterCreateStrategy
    class Coolsavings

      # This wants to be inline instead of resque
      # in case there is an issue creating the consumer on the coolsavings side
      def execute(consumer)
        attributes_for_coolsavings = map_consumer_attributes_to_coolsavings(consumer)
        member = create_member(consumer.email, Consumers::Md5Password.md5_password(consumer.password))
        # If the member exists, we do not need to create him
        # Further, if we try to call set_attributes, coolsavings will error out
        return if member.authentic?
        begin
          # coolsavings does not know about the member, meaning they were created
          # on our side, so we need to create it on their side.
          member.set_attributes!(attributes_for_coolsavings)
        rescue Analog::ThirdPartyApi::Coolsavings::ErrorResponse => e
          # The most common cause for this exception will be the restrictive
          # email checking that coolsavings does.  If the email validation fails
          # on the coolsavings side, this exception will be thrown.
          raise Consumers::AfterCreateError.new(e.message)
        end
      end

      def create_member(email, md5password)
        Analog::ThirdPartyApi::Coolsavings::Member.new(email, md5password)
      end

      def map_consumer_attributes_to_coolsavings(consumer)
        Analog::ThirdPartyApi::Coolsavings::AttributesMapper.new.map_to_coolsavings(consumer.attributes)
      end

    end
  end
end

