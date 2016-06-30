require File.dirname(__FILE__) + "/../../../test_helper"
require 'nokogiri'

# hydra class Testing::HTMLAssertionsTest

module Testing
  class HTMLAssertionsTest < Test::Unit::TestCase
    context "#assert_similar_html" do
      should "not raise an exception when html has only whitespace differences" do
        assert_nothing_raised do
          assert_similar_html(
              "  <outer_tag> <inner_tag>Some content with newlines and/or spaces <inner_tag> </outer_tag>",
              "<outer_tag><inner_tag>Some content with newlines and/or spaces <inner_tag></outer_tag>  "
          )
        end
      end

      should "raise an exception when difference is with duplicated characters" do
        assert_raise Test::Unit::AssertionFailedError do
          assert_similar_html(
              "<outer_tag><div><p>sssomething here</p></div></outer_tag>",
              "<outer_tag><div><p>something here</p></div></outer_tag>"
          )
        end
      end

      should "raise an exception when html has non-whitespace differences" do
        assert_raise Test::Unit::AssertionFailedError do
          assert_similar_html(
              "<outer_tag> <div><p>sssomething here</p></div> </outer_tag>",
              "<outer_tag><div><p>something here</p></div></outer_tag>"
          )
        end
      end
    end
  end
end
