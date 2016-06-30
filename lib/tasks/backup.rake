namespace :backup do
  
  desc "Archive production database, attachment files and log files"
  task :dump do
    DUMP_BASE_PATH = ENV['DUMP_BASE_PATH']
    raise RuntimeError, "DUMP_BASE_PATH env variable is not set" if DUMP_BASE_PATH.nil?
    raise RuntimeError, "'#{DUMP_BASE_PATH}' is not a directory" unless File.directory?(DUMP_BASE_PATH)
    raise RuntimeError, "'#{DUMP_BASE_PATH}' is not empty" unless 2 == Dir.entries(DUMP_BASE_PATH).size
    
    RAILS_ENV = ENV['RAILS_ENV'] || 'production'
    
    dump_database RAILS_ENV, DUMP_BASE_PATH
    archive File.expand_path("public/system/", Rails.root), DUMP_BASE_PATH
    archive File.expand_path("log/", Rails.root), DUMP_BASE_PATH
  end
  
  def db_config(environment)
    require 'yaml'
    YAML.load_file(File.expand_path("config/database.yml", Rails.root))[environment.to_s]
  end
  
  def dump_database(environment, dst_base_path)
    db_name, db_user, db_pass = db_config(environment).values_at('database', 'username', 'password')
    dump_file_path = File.expand_path("#{db_name}.sql", dst_base_path)
    sh "mysqldump  --add-drop-database -u '#{db_user}' '--password=#{db_pass}' -B '#{db_name}' >#{dump_file_path}"
  end
  
  def archive(dir_path, dst_base_path)
    dst_file_path = File.expand_path(File.basename(dir_path) + ".tar", dst_base_path)
    sh "tar cf '#{dst_file_path}' -C '#{File.dirname(dir_path)}' '#{File.basename(dir_path)}'"
  end
end
