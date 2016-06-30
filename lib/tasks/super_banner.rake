namespace :test do
  desc "Run the system tests in test/system"
  task :systems do
    Dir["test/system/**/*_test.rb"].each do |path|
      puts path
      unless path == "test/system/system_test.rb"
        system path
      end
    end
  end
end
