namespace :audit do
  
  desc "Check for old deal js references"
  task :check_for_old_deal_js => :environment do
    
    themes = {}
    merge_file_information_for_themes(themes, themes_from_system_call(`grep -rn "Analog.DailyDeal.init" #{Rails.root}/app/views`))
    merge_file_information_for_themes(themes, themes_from_system_call(`grep -rn "javascripts/deal.js" #{Rails.root}/app/views`))
    merge_file_information_for_themes(themes, themes_from_system_call(`grep -rn "javascripts/deal_timer.js" #{Rails.root}/app/views`))
    merge_file_information_for_themes(themes, themes_from_system_call(`grep -rn "daily_deals/init_time_left_to_buy" #{Rails.root}/app/views`))
    merge_file_information_for_themes(themes, themes_from_system_call(`grep -rn "'deal'" #{Rails.root}/app/views | grep "javascript_include_tag"`))
    merge_file_information_for_themes(themes, themes_from_system_call(`grep -rn ":deal" #{Rails.root}/app/views | grep "javascript_include_tag"`))
    merge_file_information_for_themes(themes, themes_from_system_call(`find #{Rails.root}/app/views -name "_javascript.*.erb"`))

    unless themes.empty?
      puts "Our findings:"
      themes.each_pair do |key, files|
        puts "  #{key}:"
        files.each do |file|
          puts "    #{file}"
        end
      end
    else
      puts "Congratulations! There were no offending themes."
    end
  end
  
  private
  
  def themes_from_system_call(string)
    themes = {}
    string.each_line do |line|
      theme = theme_from_file_path(line)
      if theme
        themes[theme] ||= []
        themes[theme].push(line)
      end
    end
    themes
  end
  
  def theme_from_file_path(line)
    match = line.match(/[a-zA-Z0-9\\]*\/themes\/([a-zA-Z0-9]*)\/*/)
    match[1] if match
  end
  
  def merge_file_information_for_themes(themes, new_information)
    new_information.each_pair do |key, files|
      themes[key] ||= []
      themes[key].push(files)
    end
  end
end
