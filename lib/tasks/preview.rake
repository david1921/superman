namespace :preview do
  task :require do
    require 'preview/server'
  end

  desc "Update designer server with latest code from current branch. BRANCH and DESIGNER can be set explicitly."
  task :update_server => [:environment, :require] do
    designer_name = ENV['DESIGNER']
    branch_name = ENV['BRANCH']
    begin
      Preview::Server.update_code_and_restart! :designer_name => designer_name, :branch_name => branch_name
    rescue Exception => e
      puts "ERROR: #{e.message}"
    end
  end
  
  desc "Synch up preview database and server with latest code"
  task :update  => [:environment, :require] do
    Rake::Task["db:migrate"].execute
    system "sudo /etc/init.d/#{ENV['DESIGNER_NAME']} restart"
  end
  
end
