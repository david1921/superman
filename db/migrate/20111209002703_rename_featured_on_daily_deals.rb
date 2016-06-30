class RenameFeaturedOnDailyDeals < ActiveRecord::Migration
  # Renaming the featured column so we can revert back to using it if needed. The big-table migration gem doesn't
  # handle renames properly. This migration copies heavily from it and could be used to start a real fix of the gem.
  def self.rename_column_using_tmp_table(old_column_name, new_column_name, options={})
    table_name = "daily_deals"
    new_table_name = "tmp_new_" + table_name
    old_table_name = "tmp_old_" + table_name

    begin
      say "Creating temporary table #{new_table_name} like #{table_name}..."
      execute("CREATE TABLE #{new_table_name} LIKE #{table_name}")
      say "Rename #{old_column_name} to #{new_column_name}"

      alter_sql = "ALTER TABLE #{new_table_name} CHANGE #{old_column_name} #{new_column_name} boolean"
      alter_sql << " default #{options[:default].to_s}" unless options[:default].nil?
      alter_sql << (options[:nullable].to_s == "true" ? "" : " NOT NULL") unless options[:nullable].nil?

      execute(alter_sql)

      old_column_names = []
      connection.execute("DESCRIBE #{table_name}").each_hash{ |row| old_column_names << row['Field'] } # see ruby mysql docs for more info
      new_column_names = []
      connection.execute("DESCRIBE #{new_table_name}").each_hash{ |row| new_column_names << row['Field'] }

      columns_to_copy = "`" + ( old_column_names & new_column_names ).join("`, `") + "`"
      columns_to_copy_from = columns_to_copy + ", `#{old_column_name}`"
      columns_to_copy_to = columns_to_copy + ", `#{new_column_name}`"

      timestamp_before_migration = connection.execute("SELECT CURRENT_TIMESTAMP").fetch_row[0] # note: string, not time object
      max_id_before_migration = connection.execute("SELECT MAX(id) FROM #{table_name}").fetch_row[0].to_i

      if max_id_before_migration == 0
        say "Source table is empty, no rows to copy into temporary table"
      else
        batch_size = 10000
        start = connection.execute("SELECT MIN(id) FROM #{table_name}").fetch_row[0].to_i
        counter = start
        say "Inserting into temporary table in batches of #{batch_size}..."
        say "Approximately #{max_id_before_migration-start+1} rows to process, first row has id #{start}", true
        while counter < ( max = connection.execute("SELECT MAX(id) FROM #{table_name}").fetch_row[0].to_i )
          percentage_complete = ( ( ( counter - start ).to_f / ( max - start ).to_f ) * 100 ).to_i
          say "Processing rows with ids between #{counter} and #{(counter+batch_size)-1} (#{percentage_complete}% complete)", true
          connection.execute("INSERT INTO #{new_table_name} (#{columns_to_copy_to}) SELECT #{columns_to_copy_from} FROM #{table_name} WHERE id >= #{counter} AND id < #{counter + batch_size}")
          counter = counter + batch_size
        end
        say "Finished inserting into temporary table"
      end

      say "Replacing source table with temporary table..."
      rename_table table_name, old_table_name
      rename_table new_table_name, table_name

      say "Cleaning up, checking for rows created/updated during migration, dropping old table..."
      begin
        connection.execute("LOCK TABLES #{table_name} WRITE, #{old_table_name} READ")
        recently_created_or_updated_conditions = "id > #{max_id_before_migration}"
        recently_created_or_updated_conditions << " OR updated_at > '#{timestamp_before_migration}'" if old_column_names.include?("updated_at")
        connection.execute("REPLACE INTO #{table_name} (#{columns_to_copy_to}) SELECT #{columns_to_copy_from} FROM #{old_table_name} WHERE #{recently_created_or_updated_conditions}")
      rescue Exception => e
        puts "Failed to lock tables and do final cleanup. This may not be anything to worry about, especially on an infrequently used table."
        puts "ERROR MESSAGE: " + e.message
      ensure
        connection.execute("UNLOCK TABLES")
      end
      drop_table old_table_name
      
    rescue Exception => e
      drop_table new_table_name
      raise
    end
  end

  def self.up
    rename_column_using_tmp_table("featured", "featured_deprecated")
  end

  def self.down
    rename_column_using_tmp_table("featured_deprecated", "featured", { :nullable => false, :default => true })
  end
end
