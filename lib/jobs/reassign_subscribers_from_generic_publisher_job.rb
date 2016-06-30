module Jobs
  class ReassignSubscribersFromGenericPublisherJob
    include Analog::Say

    class << self
      def perform(dry_run = false, count = false)
        base_sql = <<-SQL
          inner join publishers p on p.id = s.publisher_id and p.label = 'entertainment'
          inner join publisher_zip_codes z on z.zip_code = s.zip_code
          inner join publishers new_p on new_p.id = z.publisher_id
          inner join publishing_groups g on g.id = new_p.publishing_group_id and g.label = 'entertainment'
        SQL
        if count
          count_sql = <<-SQL
            select count(1)
            from subscribers s
            #{base_sql};
          SQL
          count_result = ActiveRecord::Base.connection.execute count_sql
          count = count_result.fetch_row[0]
          say "It would reassign #{count} entertainment subscribers to the correct publishers." if dry_run
        end
        unless dry_run
          update_sql = <<-SQL
            update subscribers s
            #{base_sql}
            set s.publisher_id = new_p.id;
          SQL
          ActiveRecord::Base.connection.execute update_sql
          say "Reassigned entertainment subscribers to the correct publishers."
        end
      end
    end
  end
end
