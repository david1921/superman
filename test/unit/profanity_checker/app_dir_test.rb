require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ProfanityChecker::AppDirTest

module ProfanityChecker

  class AppDirTest < ActiveSupport::TestCase

    def remove_match(matches, pattern)
      matches.each do |match|
        regex = /^#{pattern[:file_name]}(:\d+:)?#{pattern[:word]}$/
        if match =~ regex
          matches.delete match
          return true
        end
      end
      false
    end

    should "find no use of profanity in the codebase" do

      seeds = [
        { :file_name => 'app/models/bar_codes/import.rb', :word => 'testing123' },
        { :file_name => 'app/views/themes/entercom-portland/daily_deals/_signup_text.html.erb', :word => 'testing123' }
      ]

      # update the seeded file modification date to ensure they are searched
      seeds.each {|seed| FileUtils.touch(Rails.root.join(seed[:file_name])) }

      matches = []
      ms = Benchmark.measure do
        matches = %x{
          find app -mtime -7 -type f -print0 | xargs -0 grep -IHion -f config/black_list.txt
        }.split("\n")
      end
      Rails.logger.info("profanity check on app dir ran in %.3fs" % ms.real)

      seeds.each do |seed|
        unless remove_match matches, seed
          assert false, "Expected to find seed word '#{seed[:word]}' in file '#{seed[:file_name]}' but did not."
        end
      end

      whitelist = [
        { :file_name => 'app/views/layouts/offers/phoenixnewtimes/_navigation.html.erb', :word => 'bastard' },
        { :file_name => '', :word => 'Bastard' },
        #add more exceptions here as they come up
      ]

      whitelist.each {|pattern| remove_match matches, pattern }

      assert_equal 0, matches.size, "unexpected file matches for profanity checker\r#{matches.join("\r")}"

    end

  end

end
