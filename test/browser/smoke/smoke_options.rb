class Smoke::SmokeOptions < DelegateClass(Slop)

  def initialize(options = nil)
    super(create_slop)
    parse(options || [])
  end

  def create_slop
    Slop.new(:help => true).tap do |s|
      add_options(s)
    end
  end

  def add_options(s)
    s.on :driver=, "Use the specified Capybara driver. rack_test, selenium, webkit, webkit_debug", :optional_argument => true
    s.on :headless, "Don't open a browser (uses default 'rack_test' driver)", :optional_argument => true
    s.on :app_host, "What rails server to run requests against", :optional_argument => true
    s.on :active_resource_host, "what rails server to hit to get list of publishers, etc to run against", :optional_argument => true
    s.on :wall, "Include all pages.  Like doing --singup --login --purchase, etc.  ('Warn All')", :optional_argument => true
    s.on :signup, "Signup and check the signup pages", :optional_argument => true
    s.on :login, "Login and check login pages", :optional_argument => true
    s.on :purchase, "Make a purchase and check the purchase pages", :optional_argument => true
    s.on :skip_purchase, "Don't make a purchase, but check other pages", :optional_argument => true
    s.on :my_deals, "Visit my deals page after purchase, if any", :optional_argument => true
    s.on :deal_of_the_day, "Include the deal-of-the-day and deal-of-the-day-email page", :optional_argument => true
    s.on :extras, "Check the faq, how-to, contact-us, etc pages", :optional_argument => true
    s.on :skip_page_validations, "Do not validate pages", :optional_argument => true
    s.on :save_and_open_page, "On an error, save and open the page", :optional_argument => true
  end

end