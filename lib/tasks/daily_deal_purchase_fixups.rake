namespace :daily_deal_purchase_fixups do
  desc "Seed the daily_deal_purchase_fixups table"
  task :seed_table => :environment do
    db_host, db_name, db_user, db_pass = ActiveRecord::Base.configurations[Rails.env].values_at("host", "database", "username", "password")
    sql_file_path = File.expand_path("db/daily_deal_purchase_fixups.sql", Rails.root)
    
    puts "Executing commands from #{sql_file_path} in 5 seconds!"
    sleep 5
    puts "Executing commands now"
    system "mysql --host=#{db_host} --user=#{db_user} --password=#{db_pass} #{db_name} <#{sql_file_path}"
  end
end
