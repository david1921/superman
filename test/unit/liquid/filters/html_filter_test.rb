require File.dirname(__FILE__) + "/../../../test_helper"

class HTMLFilterTest < ActiveSupport::TestCase

  context "truncate_html_to_first_paragraph_only" do

    should "work with an empty string" do
      assert_equal "", Liquid::Template.parse('{{ ""  | truncate_html_to_first_paragraph_only }}').render
    end

    should "not truncate when the input has exactly one paragraph" do
      input = "<p>one paragraph</p>"
      assert_equal input, Liquid::Template.parse("{{ '#{input}' | truncate_html_to_first_paragraph_only }}").render
    end

    should "truncate two paragraphs and adds ellipsis" do
      first_paragraph = "<p>first paragraph</p>"
      second_paragraph = "<p>second paragraph</p>"
      assert_equal "<p>first paragraph...</p>", Liquid::Template.parse("{{ '#{first_paragraph}#{second_paragraph}' | truncate_html_to_first_paragraph_only }}").render
    end

    should "not touch input if there are no <p>s" do
      assert_equal "untouched", Liquid::Template.parse('{{ "untouched"  | truncate_html_to_first_paragraph_only }}').render
    end

  end

end
