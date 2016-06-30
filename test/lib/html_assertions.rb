require 'nokogiri'

module Testing
  module HTMLAssertions
    def assert_similar_html(expected, actual, msg="")
      assert_equal parse_xml_and_squeeze_whitespace(expected), parse_xml_and_squeeze_whitespace(actual), msg
    end

    def parse_xml_and_squeeze_whitespace(xml)
      fixed_xml = restore_self_closing_br(xml)
      Nokogiri::XML(fixed_xml).to_html.gsub(/\s/, '').squeeze(' ')
    end

    private

    def restore_self_closing_br(html_without_self_closing_br)
      html_without_self_closing_br.gsub("<br>", "<br/>")
    end
  end
end