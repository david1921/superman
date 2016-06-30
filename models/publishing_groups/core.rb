module PublishingGroups
  module Core

    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods

      def combine_duplicate_consumers!
        consumers_by_email = consumers_grouped_by_duplicated_email
        say "Combining consumers for #{consumers_by_email.size} duplicated emails..."
        consumers_by_email.each do |email, consumers|
          say "Working on #{email} [#{consumers.size}]..."
          target = consumers.first
          to_be_assimilated = consumers.slice(1..-1)
          unless to_be_assimilated.empty?
            in_transaction do
              say "--> Combining #{email}..."
              to_be_assimilated.each do |consumer|
                target.assimilate!(consumer)
                consumer.force_destroy
              end
            end
          end
        end
      end

      def consumers_grouped_by_duplicated_email
        user_ids = Consumer.connection.select_rows(<<"EOF").inject({}){|s,e| s[e[0]] = Consumer.find(e[1].split(',')); s}
SELECT email, GROUP_CONCAT(u.id)
FROM users u
JOIN publishers p ON p.id = u.publisher_id
JOIN publishing_groups pg ON pg.id = p.publishing_group_id
WHERE pg.id = #{id}
GROUP BY email
HAVING COUNT(*) > 1
EOF
      end

      def in_transaction(&block)
        Consumer.transaction do
          yield
        end
      end
    end

  end
end
