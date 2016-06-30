require 'rake/testtask'

namespace :test do

  Rake::TestTask.new("no_rails") do |t|
    t.test_files = FileList['test/no_rails/**/*_test.rb'].shuffle
    t.verbose = true
  end

  Rake::TestTask.new("smoke") do |t|
    t.test_files = FileList['test/browser/smoke_test.rb']
    t.verbose = true
  end

  Rake::TestTask.new("views") do |t|
    t.test_files = FileList['test/view/**/*_test.rb']
    t.verbose = true
  end

end

Rake.application.instance_variable_get('@tasks').delete('test')
desc 'Run all unit, functional, integration and view tests'
task :test do
  errors = %w(test:views test:units test:functionals test:integration).collect do |task|
    begin
      Rake::Task[task].invoke
      nil
    rescue => e
      task
    end
  end.compact
  abort "Errors running #{errors.to_sentence(:locale => :en)}!" if errors.any?
end
