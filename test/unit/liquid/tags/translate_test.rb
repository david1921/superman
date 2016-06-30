require File.dirname(__FILE__) + "/../../../test_helper"

class TranslateTest < ActiveSupport::TestCase

  def assert_liquid_render(expected, template)
    assert_equal expected, Liquid::Template.parse(template).render({}, :registers => @registers)
  end
  
  fast_context "translate tag" do

    setup do
      @controller = PublishersController.new
      @registers = { :controller => @controller, :action_view => mock }
      @registers[:action_view].stubs(:template).returns(stub(:path_without_format_and_extension => "foo/bar"))
    end

    should "translate English" do
      I18n.locale = :en
      assert_liquid_render "Recipient", "{% t recipient %}"
    end

    should "translate Spanish" do
      I18n.locale = :es
      assert_liquid_render "Destinatario", "{% t recipient %}"
    end

    should "remove themes prefix if using lazy keys" do
      @registers[:action_view].stubs(:template).returns(stub(:path_without_format_and_extension => "themes/byp/foo/bar"))
      I18n.stubs(:translate).with("dummy", :scope => ["foo", "bar"], :raise => true, :default => nil).returns("Dummy")

      assert_liquid_render "Dummy", "{% t .dummy %}"
    end

    should "not remove themes prefix if not using lazy keys" do
      I18n.stubs(:translate).with("themes.byp.foo.bar.dummy", :raise => true, :default => nil).returns("Dummy")

      assert_liquid_render "Dummy", "{% t themes.byp.foo.bar.dummy %}"
    end

    fast_context "with no publisher" do

      should "handle lazy keys" do
        I18n.stubs(:translate).with("dummy", :scope => ["foo", "bar"], :raise => true, :default => nil).returns("Dummy")

        assert_liquid_render "Dummy", "{% t .dummy %}"
      end

    end

    fast_context "with publisher and no publishing group" do
      setup do
        publisher = Factory(:publisher, :label => "buscaayuda")
        @controller.stubs(:current_publisher).returns(publisher)
      end

      should "find composite key with scope" do
        I18n.locale = :en
        assert_liquid_render "Account", "{% t activerecord.models.consumer %}"
      end
      
      should "find composite key not in scope" do
        I18n.locale = :en
        assert_liquid_render "Facebook Connect", "{% t facebook_connect %}"
      end

      should "handle lazy keys" do
        I18n.stubs(:translate).with("dummy", :scope => ["buscaayuda", "foo", "bar"], :raise => true).returns("Publisher's Dummy")

        assert_liquid_render "Publisher's Dummy", "{% t .dummy %}"
      end
    end

    fast_context "with publisher and publishing group" do
      setup do
        publishing_group = Factory(:publishing_group, :label => "byp")
        publisher = Factory(:publisher, :label => "buscaayuda", :publishing_group => publishing_group)
        @controller.stubs(:current_publisher).returns(publisher)
      end

      should "handle lazy keys" do
        I18n.stubs(:translate).with("dummy", :scope => ["buscaayuda", "foo", "bar"], :raise => true).returns(nil)
        I18n.stubs(:translate).with("dummy", :scope => ["byp", "foo", "bar"], :raise => true).returns("Pub Group's Dummy")

        assert_liquid_render "Pub Group's Dummy", "{% t .dummy %}"
      end
    end
  end
end
