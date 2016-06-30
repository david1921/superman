namespace :git do
  
  desc "Modify ~/.bash_profile to show current branch when in a git repo"
  task :show_current_branch_in_prompt do
    File.open(File.expand_path("~/.bash_profile"), "a") do |f|
      f.puts
      f.puts %q{PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '}
    end
    puts "Done! You will need to restart your shell for this change to take effect."
  end

end