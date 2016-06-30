namespace :import do

  desc "Import a set of barcodes for DAILY_DEAL using FILE as the source"
  task :barcodes_for_deal_from_csv => :environment do
    raise "ENV[DAILY_DEAL] and ENV[FILE] are both required by this task" if ENV['DAILY_DEAL'].empty? || ENV['FILE'].empty?

    if File.exists?(ENV['FILE'])
      puts "Reading: " + ENV['FILE']
      deal = DailyDeal.find(ENV['DAILY_DEAL'])
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M")
      barcode_count = 0
      File.readlines(ENV['FILE']).map(&:strip).each do |code|
              puts "lets go!"
        begin
          barcode_count += 1
          BarCode.connection.insert("INSERT INTO `bar_codes` (`bar_codeable_type`, `bar_codeable_id`, `created_at`, `assigned`, `code`, `position`,`updated_at`) VALUES('DailyDeal', #{deal.id}, '#{timestamp}', 0, '#{code}', #{barcode_count},'#{timestamp}')")
          if barcode_count % 1000 == 0
            puts barcode_count
          end
        rescue => e
          puts e
        end
      end
    else
      raise ".csv does not exists"
    end # fi file exists
  end #task

end # ns