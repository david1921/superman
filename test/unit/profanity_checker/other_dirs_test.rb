require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ProfanityChecker::OtherDirsTest

module ProfanityChecker
  class OtherDirsTest < ActiveSupport::TestCase

    should "find no use of profanity in the codebase" do
      FileUtils.touch(Rails.root.join("config/locales/en.yml"))
      matches = nil
      ms = Benchmark.measure do
        matches = %x{
          find . \! -path "./tags" \! -path "./config/black_list.txt" \! -path "./.git*" \! -path "./vendor/*" \
                 \! -path "./log/*" \! -path "./tmp*" \! -path "./test*" \! -path "./lib/tasks/oneoff/data/wcax*" \
                 \! -path "./app/*" \! -path "./public/*" \! -path "./lib/oneoff/tasks/data/*perk*.txt" \
                 -type f -mtime -7 -print0 \
            | xargs -0 grep -IHion -f config/black_list.txt
        }.split("\n")
      end
      Rails.logger.info("profanity check on other dirs ran in %.3fs" % ms.real)

      matches.sort!
      assert_equal 1, matches.size, "unexpected file matches for profanity checker: #{matches.join(", ")}"
      assert_match %r{\./config/locales/en.yml.*testing123}, matches.first
    end

  end
end
