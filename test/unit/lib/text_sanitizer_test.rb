require File.dirname(__FILE__) + "/../../test_helper"
require File.dirname(__FILE__) + "/../../../lib/text_sanitizer"

class TextSanitizerTest < ActiveSupport::TestCase

  test "sanitize smart quotes" do
    html = "<p>Good ol&#8217; American home-style, homemade cooking is what you&#8217;re in for at Moe&#8217;s Cafe. Our menu is packed with delicious items, fresh from the kitchen every day, all day! To start, get on the right track with a cup of our delicious gourmet or one of the flavored coffees. Then go for breakfast, try a daily special or pick a pastry and some fresh fruit! Visit us later for lunch or dinner when you feel like you need to get away, see a friendly face or chat &#8211; just like Mom&#8217;s kitchen when you were growing up! And if you&#8217;re looking for something for the whole family, but tastes are diverse &#8211; that&#8217;s okay! Moe&#8217;s Cafe has healthy vegetarian, Native American and children menus to satisfy everyone and with generous portions to more than take the edge off of those hunger pangs. With so much to choose from you&#8217;ll want to go back again and again. Moe&#8217;s Cafe has what it is you&#8217;re looking for so on stop by, chat and get a piece of homemade pie!</p>"
    expected = "<p>Good ol' American home-style, homemade cooking is what you're in for at Moe's Cafe. Our menu is packed with delicious items, fresh from the kitchen every day, all day! To start, get on the right track with a cup of our delicious gourmet or one of the flavored coffees. Then go for breakfast, try a daily special or pick a pastry and some fresh fruit! Visit us later for lunch or dinner when you feel like you need to get away, see a friendly face or chat - just like Mom's kitchen when you were growing up! And if you're looking for something for the whole family, but tastes are diverse - that's okay! Moe's Cafe has healthy vegetarian, Native American and children menus to satisfy everyone and with generous portions to more than take the edge off of those hunger pangs. With so much to choose from you'll want to go back again and again. Moe's Cafe has what it is you're looking for so on stop by, chat and get a piece of homemade pie!</p>"
    assert_equal expected, TextSanitizer.sanitize_entities(html)
  end

  test "sanitize arbitrary entities" do
    html = "<p>foo&#1;&#12;&#123;&#1234;&#12345;&#123456;bar</p>"
    expected = "<p>foobar</p>"
    assert_equal expected, TextSanitizer.sanitize_entities(html)
  end

  test "sanitize non-ascii characters" do
    input = {
        :en_dash => ['–', '-'],
        :em_dash => ['—', '--'],
        :left_quote => ['‘', "'"],
        :right_quote => ['’', "'"],
        :left_dbl_quote => ['“', '"'],
        :right_dbl_quote => ['”', '"'],
        :bullet => ['•', '*'],
        :elipsis => ['…', '...'],
        :euros => ['€', 'E'],
        :trademark  => ['™', '(TM)'],
        :low_9_single_quote => ['‚', ''],
        :double_low_nine_quote => ['„', ''],
        :dagger => ['†', ''],
        :double_dagger => ['‡', ''],
        :per_thousand_sign => ['‰', ''],
    }

    input.each do |k,v|
      assert_equal v[1], TextSanitizer.sanitize_non_ascii(v[0]), "#{k} did not convert properly"
    end

    ["Ϩ", "✐"].each do |non_ascii|
      assert_equal '', TextSanitizer.sanitize_non_ascii(non_ascii), "#{non_ascii} did not convert properly"
    end

    assert_equal 'Hello  world', TextSanitizer.sanitize_non_ascii("✐Hello ΘΏ⦔ world✐")
  end

  test "sanitize non-breaking spaces into standard space" do
    assert_equal ' ', TextSanitizer.sanitize_non_ascii('&nbsp;')
  end

  test "#sanitize" do
    assert_equal "Hello 'E", TextSanitizer.sanitize("Hello &#8217;€Ϩ")
    assert_equal "Regular text<b>bold text</b><p>paragraph</p> block elements table data", TextSanitizer.sanitize("Regular text<b>bold text</b><p>paragraph</p><div>block elements</div><table><tbody><tr><td>table data</td></tr></tbody></table>")
  end

  test "#sanitize_html_tags" do
    assert_equal "Regular text<b>bold text</b><p>paragraph</p> block elements table data", TextSanitizer.sanitize_html_tags("Regular text<b>bold text</b><p>paragraph</p><div>block elements</div><table><tbody><tr><td>table data</td></tr></tbody></table>")
  end

  test "sanitization methods with nil or empty input" do
    assert_equal nil, TextSanitizer.sanitize(nil)
    assert_equal '', TextSanitizer.sanitize('')
    assert_equal nil, TextSanitizer.sanitize_entities(nil)
    assert_equal '', TextSanitizer.sanitize_entities('')
    assert_equal nil, TextSanitizer.sanitize_non_ascii(nil)
    assert_equal '', TextSanitizer.sanitize_non_ascii('')
    assert_equal nil, TextSanitizer.sanitize_html_tags(nil)
    assert_equal '', TextSanitizer.sanitize_html_tags('')
  end
end