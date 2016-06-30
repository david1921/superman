require File.dirname(__FILE__) + "/../../test_helper"

# hydra class ProfanityChecker::PublicDirTest

module ProfanityChecker
  class PublicDirTest < ActiveSupport::TestCase

    should "find no use of profanity in the codebase" do
      FileUtils.touch(Rails.root.join("public/javascripts/admin.js"))
      matches = nil
      ms = Benchmark.measure do
        matches = %x{
          find public -mtime -7 -type f -print0 | xargs -0 grep -IHion -f config/black_list.txt
        }.split("\n")
      end
      Rails.logger.info("profanity check on public dir ran in %.3fs" % ms.real)

      matches.sort!
      assert_equal 1, matches.size, "unexpected file matches for profanity checker: #{matches.join(", ")}"
      assert_match %r{public/javascripts/admin.js.*testing123}, matches.first
    end

  end
end
