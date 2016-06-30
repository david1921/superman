require File.dirname(__FILE__) + "/../test_helper"

class PreferredLocaleTest < ActionController::IntegrationTest
  context "on a publisher without locale set" do
    setup do
      @publisher = Factory(:publisher)
      @publisher.stubs(:enabled_locales_for_consumer).returns([])
      @el_publisher = Factory(:publisher)
      @el_publisher.stubs(:enabled_locales_for_consumer).returns(['el'])

    end
    # Exposing a bug we had once.
    should "not transfer the locale of 'the last' publisher to the next request" do
      get "/el/publishers/#{@el_publisher}/deal-of-the-day"
      get "/publishers/#{@publisher.id}/deal-of-the-day"
      assert_equal :en, I18n.locale
    end
  end

  context "setting the consumer's preferred locale" do
    setup do
      @publisher = Factory(:publisher)
      @admin = Factory(:admin)
      ActionController.stubs(:current_user).returns(@admin)
      Publisher.any_instance.stubs(:enabled_locales_for_consumer).returns(["en", "es", "el"])
      I18n.default_locale = :en
      I18n.locale = :es
    end

    context "on consumer login" do
      setup do
        @consumer = Factory(:consumer, :publisher => @publisher, :email => "foobar@yahoo.com", :password => "password", :password_confirmation => "password")
      end

      should "set the current locale to the consumer's preferred locale when one is present" do
        @consumer.update_attribute(:preferred_locale, "el")
        assert_equal :es, I18n.locale
        post "/es/publishers/#{@publisher.id}/daily_deal_session/create", :publisher_id => @publisher.id, :session => { :email => "foobar@yahoo.com", :password => "password" }
        assert_equal :el, I18n.locale
      end

      should "keep the current locale when the consumer has no preferred locale" do
        @consumer.update_attribute(:preferred_locale, nil)
        assert_equal :es, I18n.locale
        post "/es/publishers/#{@publisher.id}/daily_deal_session/create", :session => { :email => "foobar@yahoo.com", :password => "password" }
        assert_equal :es, I18n.locale
      end
    end

    context "on consumer create" do
      should "set the current locale to the new consumer's preferred locale when one is present" do
        assert_equal :es, I18n.locale
        post "/es/publishers/#{@publisher.id}/consumers", :consumer => Factory.attributes_for(:consumer, :preferred_locale => "el")
        assert_equal :el, I18n.locale
      end

      should "keep the current locale when the consumer has no preferred locale" do
        assert_equal :es, I18n.locale
        post "/es/publishers/#{@publisher.id}/consumers", :consumer => Factory.attributes_for(:consumer)
        assert_equal :es, I18n.locale
      end
    end

    context "on consumer update" do
      setup do
        @consumer = Factory(:consumer, :publisher => @publisher, :email => "foobar@yahoo.com", :password => "password", :password_confirmation => "password")
        post "/es/publishers/#{@publisher.id}/daily_deal_session/create", :publisher_id => @publisher.id, :session => { :email => "foobar@yahoo.com", :password => "password" }
      end

      should "set the current locale to the consumer's preferred locale when one is present" do
        assert_equal :es, I18n.locale
        put "/es/publishers/#{@publisher.id}/consumers/#{@consumer.id}", :consumer => {:preferred_locale => "en"}
        assert_equal :en, I18n.locale
      end

      should "keep the current locale when the consumer has no preferred locale" do
        @consumer.update_attribute(:preferred_locale, nil)
        assert_equal :es, I18n.locale
        put "/es/publishers/#{@publisher.id}/consumers/#{@consumer.id}", :consumer => {}
        assert_equal :es, I18n.locale
      end
    end
  end
end