require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::TextilizedTest < ActiveSupport::TestCase

  context "textiled fields" do
    setup do
      @daily_deal = Factory(:daily_deal)
    end

    should "be formatted correctly" do
      [:description, :highlights, :terms, :reviews, :disclaimer, :redemption_page_description].each do |field|
        @daily_deal.update_attributes(field => "*Test* _textile_\n* string")

        assert_equal "<p><strong>Test</strong> <em>textile</em></p>\n<ul>\n\t<li>string</li>\n</ul>", @daily_deal.send(field)
        assert_equal "*Test* _textile_\n* string", @daily_deal.__send__(:"#{field}_source")
        assert_equal "Test textile\n\n\tstring\n", @daily_deal.__send__(:"#{field}_plain")
      end
    end
  end


end
