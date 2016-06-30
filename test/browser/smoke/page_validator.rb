require "capybara/rails"
require File.dirname(__FILE__) + "/logger"


module Smoke

  class PageValidator
    include ::Capybara::DSL
    include Smoke::Logger

    attr_reader :messages

    def initialize(messages, show_page_on_error = true)
      @messages = messages
      @show_page_on_error = show_page_on_error
    end

    def validate_page(label, path)
      log "validate #{path}"
      if current_path != path
        visit path
        if current_path != path
          raise Smoke::UnrecoverableWarning.new(label, path, "Tried to visit #{path} but ended up on #{current_path} instead.")
        end
      end
      assert_no_errors(page.html, label, path)
    end

    def assert_no_errors(html, label, path)
      begin
        if html.include?("ActiveRecord::RecordNotFound")
          raise Smoke::UnrecoverableWarning.new(label, path, "ActiveRecord::RecordNotFound")
        end
        assert_no_content html, "Application Trace"
        assert_no_content html, "error occurred"
        assert_no_content html, "Exception"
        assert_no_content html, "LiquidError"
        assert_no_content html, "RecordNotFound"
        assert_no_content html, "RoutingError"
        assert_no_content html, "RuntimeError"
        assert_no_content html, "NoSuchMethodError"
        assert_no_content html, "Template is missing"
        assert_no_content html, "Unknown action"
        assert page.has_no_selector?(".translation_missing"), "Page has missing translations"
        html_without_poopy_tags = strip_unwanted_tags(html)
        assert_no_match /&amp;amp;/, html_without_poopy_tags, "Page has escaped html entity (amp)"
        assert_no_match /&amp;nbsp;/, html_without_poopy_tags, "Page has escaped html entity (nbsp)"
        assert_no_match /&lt;(.*)&gt;/, html_without_poopy_tags, "Page has escaped html"
      rescue Smoke::UnrecoverableWarning => e
        warning(label, path, e)
      rescue => e
        error(label, path, e)
        save_and_open_page if show_page_on_error?
      end
    end

    def strip_unwanted_tags(s)
      result = strip_noscripts(s)
      strip_iframes(result)
    end

    def strip_noscripts(s)
      strip_all_tags_and_contents(s, "noscript")
    end

    def strip_iframes(s)
      strip_all_tags_and_contents(s, "iframe")
    end

    def strip_all_tags_and_contents(s, tag_no_brackets)
      strip_all_ocurrences_of_tag(s, "<#{tag_no_brackets}", "</#{tag_no_brackets}>")
    end

    def strip_all_ocurrences_of_tag(s, opening, closing)
      final_result = s
      while (result = strip_next_occurrence(final_result, opening, closing))
        final_result = result
      end
      final_result
    end

    def strip_next_occurrence(s, opening, closing)
      index = s.index(opening)
      return nil unless index
      index2 = s.index(closing, index + opening.length)
      return nil unless index2
      result = s.slice(0..(index - 1))
      result << s.slice((index2+closing.length)..(s.length - 1))
    end

    def assert_no_content(html, content)
      if html.include?(content)
        fail "Page should not have '#{content}'"
      end
    end

    def assert_no_match(regex, html, msg)
      match_data = regex.match(html)
      if match_data
        # Some weird thing where the mailto stuff gets escaped
        unless email_address_between_angle_brackets?(match_data[0])
          fail msg + " (#{match_data[0]})"
        end
      end
    end

    def email_address_between_angle_brackets?(match_data)
      match_data =~ /&lt;.*@.*&gt;/
    end

    def show_page_on_error?
      @show_page_on_error
    end

    def assert(bool, msg)
      unless bool
        fail msg
      end
    end

    def fail(msg)
      raise msg
    end

  end

end