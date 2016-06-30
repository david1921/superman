module Smoke
  module Capybara

    def setup_capybara(options)
      register_capybara_drivers
      setup_capybara_driver(options)
      setup_capybara_server(options)
      setup_capybara_timeouts
    end

    def setup_capybara_timeouts
      ::Capybara.server_boot_timeout = 500
    end

    def setup_capybara_driver(options)
      if options[:driver].present?
        case options[:driver]
        when "default", "headless"
          ::Capybara.use_default_driver
        when "javascript_driver"
          ::Capybara.current_driver = ::Capybara.javascript_driver
        else
          ::Capybara.current_driver = options[:driver].to_sym
          if options[:driver] == "webkit"
            ::Capybara.javascript_driver = :webkit
          end
        end
      elsif options.headless?
        ::Capybara.use_default_driver
      else
        ::Capybara.current_driver = ::Capybara.javascript_driver
      end
    end

    def capybara_headless?
      ::Capybara.current_driver == :rack_test
    end

    def setup_capybara_server(options)
      if options[:app_host].present?
        ::Capybara.app_host = options[:app_host]
        ::Capybara.run_server = false
      else
        ::Capybara.server_port = 8082
        ::Capybara.run_server = true
      end
    end

    def register_capybara_drivers
      ::Capybara.register_driver :selenium do |app|
        ::Capybara::Selenium::Driver.new(app, :browser => :chrome)
      end
    end

    def safe_fill_in(locator, options)
      if has_field?(locator)
        fill_in(locator, options)
      end
    end

    def safe_select(locator, value)
      if has_select?(locator)
        select(value, :from => locator)
      end
    end

    def safe_select_male(locator)
      if has_select?(locator, :options => ['Male', 'Female'])
        select("Male", :from => locator)
      elsif has_select?(locator, :options => ['M', "F"])
        select("M", :from => locator)
      end
    end

    def safe_click_link(locator)
      if has_link?(locator)
        begin
          click_link locator
        rescue Selenium::WebDriver::Error::ElementNotVisibleError => e
        #  ignore -- we failed to click
        end
      end
    end

    def safe_click_button(locator)
      if has_button?(locator)
        click_button locator
        true
      else
        false
      end
    end

    def safe_select_option(select_id, index_from_one)
      if has_select?(select_id)
        option_xpath = "//*[@id='#{select_id}']/option[#{index_from_one}]"
        option = find(:xpath, option_xpath)
        if option
          select(option.text, :from => select_id)
        end
      end
    end

    def safe_check(css_id)
      if has_css?("##{css_id}")
        check css_id
      end
    end

    def any_matching_span?(span_text)
      matches = page.all(:xpath, "//span")
      return matches.any? { |m| m.text == span_text }
    end

    def prototype_js_check(css_id)
      page.evaluate_script("$('#{css_id}').checked = true;")
    end

    def capybara_driver_supports_javascript?
      case ::Capybara.current_driver
        when :selenium, :webkit
          true
        else
          false
      end
    end

  end
end
