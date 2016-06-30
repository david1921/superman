require File.dirname(__FILE__) + "/../../../../test_helper"
require 'export/entertainment/deal_summary_email_task'

# hydra class Export::Entertainment::DealEmailFileSummarizerTest
module Export
  module Entertainment
    class FasterCSV; end
    class DealEmailFileSummarizerTest < Test::Unit::TestCase
      context "success path" do
        should "open the input file with FasterCSV" do
          input_file = "ignored value"
          config = {:col_sep => "|",
                    :headers => true,
                    :quote_char => "\n",
                    :skip_blanks => true}
          FasterCSV.stubs(:open).with(input_file, "rb", config).once
          ItemGrouper.stubs(:group_items)

          DealEmailFileSummarizer.summarize(input_file)
        end

        should "group items by the USERDEFINED2 column" do
          input_file = "ignored value"
          expected_text = "correct answer"
          FasterCSV.stubs(:open).returns([{'USERDEFINED2' => expected_text}])

          results = DealEmailFileSummarizer.summarize(input_file)

          assert_equal({expected_text => 1}, results)
        end
      end
    end
  end
end
