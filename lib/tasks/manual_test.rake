namespace :manual_test do
  desc "Validate html truncation for all daily deals in the system"
  task :html_truncation => :environment do 
    count = 0
    errors = 0
    DailyDeal.all.each do |deal|
      html = HtmlTruncator.truncate_html(deal.description, 1000)
      if html == "..."
        puts "-"*80
        puts "deal.id=#{deal.id}"
        puts "="*80
        puts deal.description
        errors += 1
      end
      count += 1
      print "." if count % 10 == 0
    end
    puts "\n#{errors} descriptions truncated to '...' out of #{count} deals"
    if errors > 0
      puts "FAILED"
      exit(1)
    end 
    puts "PASSED"
  end
end
