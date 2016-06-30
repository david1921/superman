namespace :tsung do
  desc "Run the Tsung benchmark for BCBSA and generate report"
  task :bcbsa do
    tsung_stats = `which tsung_stats`

    if ENV['TS']
      tsung_stats = ENV['TS']
    elsif tsung_stats.empty?
      puts "Can not find `tsung_stats` executable."
      puts "Try setting the TS environment variable to the tsung_stats.pl script."
    else
      tsung_stats = 'tsung_stats'
    end

    pwd = Dir.pwd

    puts "Running tsung..."
    tsung_cmd = `tsung -f test/benchmark/bcbsa.xml start`

    tsung_dir = tsung_cmd.chomp.split("Log directory is: ").last[0..-2]
    Dir.chdir(tsung_dir)
    puts "Running tsung_stats using \"#{tsung_stats}\"..."
    tsung_stats_cmd = `tsung_stats`

    puts
    puts "Report located at #{tsung_dir}/report.html"
  end
end
