require File.dirname(__FILE__) + "/../test_helper"

class ActionView::Helpers::TranslationHelperTest < ActionView::TestCase

  context "ActionView::Helpers::TranslationHelper" do

    should "remove themes prefix if using lazy keys" do
      stubs(:template).returns(stub(:path_without_format_and_extension => "themes/byp/foo/bar"))
      I18n.stubs(:translate).with("dummy", :scope => ["foo", "bar"], :raise => true, :default => nil).returns("Dummy")

      assert_equal "Dummy", t('.dummy')
    end

    should "not remove themes prefix if not using lazy keys" do
      I18n.stubs(:translate).with("themes.byp.foo.bar.dummy", :raise => true, :default => nil).returns("Dummy")

      assert_equal "Dummy", t('themes.byp.foo.bar.dummy')
    end

    context "no publisher" do

      should "handle lazy keys" do
        stubs(:template).returns(stub(:path_without_format_and_extension => "foo/bar"))
        I18n.stubs(:translate).with("dummy", :scope => ["foo", "bar"], :raise => true, :default => nil).returns("Dummy")

        assert_equal "Dummy", t('.dummy')
      end

    end

    context "with publisher and no publishing group" do
      setup do
        # @publisher used by TranslationHelper
        @publisher = Factory(:publisher, :label => "buscaayuda")
      end

      should "handle lazy keys" do
        stubs(:template).returns(stub(:path_without_format_and_extension => "foo/bar"))
        I18n.stubs(:translate).with("dummy", :scope => ["buscaayuda", "foo", "bar"], :raise => true).returns("Publisher's Dummy")

        assert_equal "Publisher's Dummy", t('.dummy')
      end
    end

    context "with publisher and publishing group" do
      setup do
        publishing_group = Factory(:publishing_group, :label => "byp")
        # @publisher used by TranslationHelper
        @publisher = Factory(:publisher, :label => "buscaayuda", :publishing_group => publishing_group)
      end

      should "handle lazy keys" do
        stubs(:template).returns(stub(:path_without_format_and_extension => "foo/bar"))
        I18n.stubs(:translate).with("dummy", :raise => true, :scope => ["buscaayuda", "foo", "bar"]).returns(nil)
        I18n.stubs(:translate).with("dummy", :raise => true, :scope => ["byp", "foo", "bar"]).returns("Pub Group's Dummy")

        assert_equal "Pub Group's Dummy", t('.dummy')
      end

      should "handle scoped keys" do
        I18n.stubs(:translate).with("123", :raise => true, :scope => ["buscaayuda", :abc, :xyz]).returns(nil)
        I18n.stubs(:translate).with("123", :raise => true, :scope => ["byp", :abc, :xyz]).returns("Pub Group's Foo")

        assert_equal "Pub Group's Foo", t('123', :scope => [:abc, :xyz])
      end
    end
  end

end
