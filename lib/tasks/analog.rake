namespace :analog do
  desc "Generate and send the daily daily-deal purchase summary report"
  exceptional_task :daily_deal_purchase_summary_report => :environment do |t|
    Job.run! t.name, :incremental => true do
      Analog::Tasks.send_daily_deal_purchase_summary_report!
    end
  end

  desc "Exceptional Rake Test"
  exceptional_task :test_task do
    raise "Test Exception"
  end
end
