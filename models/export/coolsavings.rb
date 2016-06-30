module Export
  class Coolsavings
    include Analog::Say

    def export_all_consumers
      all_coolsavings_publishers.each do |publisher|
        publisher.consumers.each do |consumer|
          export_to_coolsavings(consumer)
          consumer.force_password_reset = true
          consumer.save!
          small_sleep_to_avoid_looking_like_denial_of_service_attack
        end
      end
    end

    def all_coolsavings_publishers
      coolsavings = PublishingGroup.find_by_label("qinteractive") # coolsavings secret name is 'qinteractive'
      coolsavings.publishers
    end

    def export_to_coolsavings(consumer)
      random_password = User.random_password(6).md5
      member = Analog::ThirdPartyApi::Coolsavings::Member.new(consumer.email, random_password)
      coolsavings_attrs = Analog::ThirdPartyApi::Coolsavings::AttributesMapper.new.map_to_coolsavings(consumer.attributes)
      begin
        if Rails.env.production?
          say "Exporting #{consumer.email}..."
          member.set_attributes!(coolsavings_attrs)
        else
          say "In production, would be exporting #{consumer.email}..."
        end
      rescue RuntimeError => e
        say "Account already exists? :#{e.message}"
      end
    end

    def small_sleep_to_avoid_looking_like_denial_of_service_attack
      sleep 1
    end

  end
end
