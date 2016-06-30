require "rubygems"
require "bundler"

Bundler.require :hydra

require 'hydra'
require 'hydra/tasks'
require File.dirname(__FILE__) + "/../analog/hydra_class_comment_detector"

namespace :hydra do

  desc "runs tests remotely"
  task :test => [ :setup, :hot_test ]

  desc "Set up test databases and gems on remote server"
  task :setup => [ :sync_message, :sync, :environment ] do
    Bundler.require :default
    start = Time.now
    begin
      validate_project_directory
      validate_exclude
      Rake::Task["hydra:bundle"].execute
      Rake::Task["db:abort_if_pending_migrations"].execute
      Rake::Task["db:test:prepare"].execute
      Rake::Task["hydra:sync"].execute
      Rake::Task["hydra:reset_db"].execute
    ensure
      minutes, seconds = timings(start)
      puts "Setup took #{minutes.to_i} minutes and #{seconds.to_i} seconds"
    end
  end
   
  desc "Run tests remotely, and run all Rails tests in same process. Assume migrations ran; test database up-to-date; gems installed. (hydra:test does all the setup and then runs this task)"
  task :hot_test => [ :sync_message, :sync ] do
    start = Time.now
    Rake::Task["hydra:check"].execute 
    Rake::Task["hydra:detect"].execute
    
    begin
      Rake::Task["hydra:remote_no_rails_tests"].execute
      Rake::Task["hydra:remote_all_tests"].execute
    rescue Exception => e
      raise
    ensure
      minutes, seconds = timings(start)
      puts "Tests ran in #{minutes.to_i} minutes and #{seconds.to_i} seconds"
    end
  end

  task :sync_message do
    # Give feedback before syncing. If rsync needs to send many files, there could a long stretch with no output.
    puts "sync"
  end

  desc "scans test files to detect missing hydra class comments"
  task :detect do
    "test/**/*_test.rb".each do |glob|
      HydraClassCommentDetector.detect glob
    end
  end

  desc "Check free RAM on Hydra servers"
  task :check do
    Hydra::RemoteCommand.new("if which vmstat; then vmstat -s -S M; else echo '8000 M free memory 8000 M total memory 1000 M active memory'; fi", "M free memory").results.each do |worker, response|
      puts /(\d+) M total memory/.match(response)[1]
      total_ram = /(\d+) M total memory/.match(response)[1].to_i
      active_ram = /(\d+) M active memory/.match(response)[1].to_i
      free_ram = total_ram - active_ram
      go = true
      if free_ram < 40 + 250 * worker["runners"].to_i
        go = false
        p "[  ] #{worker['connect']} has only #{free_ram} M free, and can't run #{worker["runners"]} Hydra runners"
      else
        p "[OK] #{worker['connect']} has #{free_ram} M free"
      end
      unless go
        exit 1
      end
    end
  end

  desc "Checks the ruby versions"
  task :check_ruby_version do
    p "ruby version"
    Hydra::RemoteCommand.new("ruby --version", "Done").results.each do |worker, response|
      ruby_version = /(^ruby.[0-9]+.*$)/.match(response)[0]
      p "#{worker['connect']} #{ruby_version}"
    end
  end

  desc "Run bundler on Hydra server"
  task :bundle => :environment do
    p "bundle"
    Hydra::RemoteCommand.new "bundle install --deployment --without development", "Your bundle is complete"
  end

  desc "Recreate test databases"
  task :reset_db => :environment do
    p "reset_db"
    config = YAML.load_file(File.join('config', 'hydra.yml'))
    max_runners = [ config.fetch('workers') { [] }.max_by { |worker| worker["runners"].to_i }["runners"].to_i, 4 ].max
    dbs = []
    dbs << Thread.new do
      index = 0
      max_runners.times do
        Hydra::RemoteCommand.new "RAILS_ENV=test TEST_DB_ID=$remote_user#{index} bundle exec rake db:reset", "assume_migrated_upto_version"
        index = index + 1
      end
    end
    dbs.each { |db| db.join }
  end

  desc "Remove remote project directories on Hydra server"
  task :remove => :environment do
    Hydra::RemoteCommand.new "rm -rf ~/super-banner && echo 'done'", "done"
  end

  desc "Run tests specified by TEST_DIR. Assumes database is up to date."
  task :my_hot_test_dir => [ :sync_message, :sync ] do
    start = Time.now
    Rake::Task["hydra:check"].execute
    begin
      Rake::Task["hydra:my_test_dir"].execute
    rescue Exception => e
      raise
    ensure
      minutes, seconds = timings(start)
      puts "Tests in #{ENV['TEST_DIR']} ran in #{minutes.to_i} minutes and #{seconds.to_i} seconds"
    end
  end

  desc "Run tests specified by the test file TEST. Assumes database is up to date."
  task :my_hot_test => [ :sync_message, :sync ] do
    start = Time.now
    begin
      Rake::Task["hydra:my_test"].execute
    rescue Exception => e
      raise
    ensure
      minutes, seconds = timings(start)
      puts "Test #{ENV['TEST']} ran in #{minutes.to_i} minutes and #{seconds.to_i} seconds"
    end
  end

end

Hydra::TestTask.new("hydra:remote_all_tests") do |t|
  "test/integration/**/*_test.rb".each do |glob|
    t.add_files glob
  end
  "test/functional/**/*_test.rb".each do |glob|
    t.add_files glob
  end
  "test/unit/**/*_test.rb".each do |glob|
    t.add_files glob
  end
  "test/view/**/*_test.rb".each do |glob|
    t.add_files glob
  end
  t.verbose = false
end

Hydra::TestTask.new("hydra:remote_no_rails_tests") do |t|
  "test/no_rails/**/*_test.rb".each do |glob|
    t.add_files glob
  end
  t.verbose = false
end

Hydra::TestTask.new("hydra:remote_view_tests") do |t|
  "test/view/**/*_test.rb".each do |glob|
    t.add_files glob
  end
  t.verbose = false
end

Hydra::TestTask.new("hydra:remote_unit_tests") do |t|
  "test/unit/**/*_test.rb".each do |glob|
    t.add_files glob
  end
  t.verbose = false
end

Hydra::TestTask.new("hydra:remote_functional_tests") do |t|
  "test/functional/**/*_test.rb".each do |glob|
    t.add_files glob
  end
  t.verbose = false
end

Hydra::TestTask.new("hydra:remote_integration_tests") do |t|
  "test/integration/**/*_test.rb".each do |glob|
    t.add_files glob
  end
  t.verbose = false
end

Hydra::SyncTask.new("hydra:sync") do |t|
  t.verbose = false
end

Hydra::TestTask.new("hydra:my_test_dir") do |t|
  if ENV['TEST_DIR']
    "#{ENV['TEST_DIR']}/**/*_test.rb".each do |glob|
      t.add_files glob
    end
    t.verbose = false
  end
end

Hydra::TestTask.new("hydra:my_test") do |t|
  if ENV['TEST']
    ENV['TEST'].each do |glob|
      t.add_files glob
    end
    t.verbose = false
  end
end

def validate_project_directory
  config_yml = YAML::load(IO.read(File.join("config", "hydra.yml")))
  project_dir = config_yml["sync"]["directory"]
  pwd = FileUtils.pwd
  unless project_dir == pwd
    raise "Your current project directory is #{pwd}, but your config/hydra.yml has #{project_dir}"
  end
end

def validate_exclude
  config_yml = YAML::load(IO.read(File.join("config", "hydra.yml")))
  exclude = config_yml["sync"]["exclude"].to_s
  [ %r{bundle}, %r{\.bundle}, %r{\.git}, %r{\.rvmrc}, %r{vendor/bundle}, %r{vendor/gems} ].each do |r|
    unless exclude[r]
      raise "sync:exclude in config/hydra.yml should exclude #{r.to_s} to ensure tests run correctly on the remote server"
    end
  end
end

def timings(start)
  delta = Time.now - start
  seconds = delta % 60
  delta = (delta - seconds) / 60
  minutes = delta % 60
  [minutes, seconds]
end
