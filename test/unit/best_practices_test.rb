require File.dirname(__FILE__) + "/../test_helper"

class BestPracticesTest < ActiveSupport::TestCase

  TEST_FILE_MAX_LINES = 800
  TEST_FILES_LONG_FILE_TOTAL_LINES_RATCHET = 11090
  TEST_FILES_OVER_MAX_LINES_RATCHET = 8
  TEST_FILE_RATCHET_MSGS = {
    :total_long_lines => "total lines in files longer than #{TEST_FILE_MAX_LINES} lines",
    :num_over_max_lines => "number of files over #{TEST_FILE_MAX_LINES} lines"
  }

  fast_context "test files" do

    setup do
      @total_long_lines = 0
      @files_longer_than_max = {}

      Dir[Rails.root.join("test/**/*_test.rb")].each do |test_filename|
        num_lines = `wc -l #{test_filename}`.match(/^\s*(\d+)/)[1]
        num_lines = num_lines.to_i
        if num_lines > TEST_FILE_MAX_LINES
          @files_longer_than_max[test_filename] = num_lines
          @total_long_lines += num_lines
        end
      end
    end

    should "have total long lines < #{TEST_FILES_LONG_FILE_TOTAL_LINES_RATCHET} lines (for files longer than #{TEST_FILE_MAX_LINES} lines)" do
      assert_message = <<"EOF"

Total lines in test files longer than #{TEST_FILE_MAX_LINES} cannot exceed #{TEST_FILES_LONG_FILE_TOTAL_LINES_RATCHET} (was #{@total_long_lines}).
You probably increased the length of one of these files:
\t#{long_files_output(@files_longer_than_max)}
EOF
      assert @total_long_lines <= TEST_FILES_LONG_FILE_TOTAL_LINES_RATCHET, assert_message
      puts ratchet_msg :total_long_lines, @total_long_lines if @total_long_lines < TEST_FILES_LONG_FILE_TOTAL_LINES_RATCHET
    end

    should "have less than #{TEST_FILES_OVER_MAX_LINES_RATCHET} files longer than #{TEST_FILE_MAX_LINES} lines" do
      assert_message = <<"EOF"

The number of files longer than #{TEST_FILE_MAX_LINES} cannot exceed #{TEST_FILES_OVER_MAX_LINES_RATCHET} (was #{@files_longer_than_max.size}).
You probably increased the length of one of these files:
\t#{long_files_output(@files_longer_than_max)}
EOF
      assert @files_longer_than_max.size <= TEST_FILES_OVER_MAX_LINES_RATCHET, assert_message
      puts ratchet_msg :num_over_max_lines, @files_longer_than_max.size if @files_longer_than_max.size < TEST_FILES_OVER_MAX_LINES_RATCHET
    end
  end

  private

  def ratchet_msg(name, value)
    "RATCHET! Looks like you reduced the #{TEST_FILE_RATCHET_MSGS[name]}. Gratz! Please crank the ratchet to #{value}."
  end

  def long_files_output(file_data)
    i = 0
    file_data.
      to_a.
      sort_by(&:second).
      reverse.
      map { |file, num_lines| "#{i+=1} " + file.gsub(Rails.root, '') + " (#{num_lines} lines)"}.
      join("\n\t")
  end
end
