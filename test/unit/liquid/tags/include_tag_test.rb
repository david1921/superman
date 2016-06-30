require File.dirname(__FILE__) + "/../../../test_helper"

class IncludeTagTest < ActiveSupport::TestCase

  class TestFileSystem
    FILES = {
      "bar"                                       => "Bar's template",
      "foo"                                       => "Foo's template",
      "baz"                                       => "Baz's template",
      "themes/test-publishing-group/foo"          => "Publishing group's foo template",
      "themes/test-publishing-group/baz"          => "Publishing group's baz template",
      "themes/test-publisher/baz"                 => "Publisher's baz template",
      "themes/cleverbetta/custom_stylesheets"     => "<!-- override this for custom stylesheets -->",
      "themes/roaringlion/sidebar"                => "the default sidebar",
      "themes/cleverbetta/sidebar"                => "cleverbetta default sidebar",
      "xyz"                                       => "Value: {{ xyz }}",
      "themes/test-publisher/xyz"                 => "Publisher's Value: {{ xyz }}",
      "variables"                                 => "Value: {{ val }}",
      "themes/test-publishing-group/localized.en" => "Publishing group's English",
      "themes/test-publisher/localized.es"        => "Publisher's Spanish",
      "themes/cleverbetta/localized.fr"           => "cleverbetta French",
      "localized.en"                              => "Default English",
      "localized.es"                              => "Default Spanish",
      "localized.de"                              => "Default German",
      "other_localized"                           => "Default",
    }

    def read_template_file(template_path, context)
      raise "NO SUCH FILE" unless template_exists?(template_path)
      FILES[template_path]
    end

    def template_exists?(file)
      FILES.keys.include? file
    end
  end

  def assert_template(code, template, render_opts = nil)
    render_opts = {'publisher' => @publisher} unless render_opts
    assert_equal template, Liquid::Template.parse(code).render(render_opts, :registers => @registers)
  end

  def setup
    Liquid::Template.file_system = TestFileSystem.new

    @controller = ApplicationController.new
    publishing_group = Factory(:publishing_group, :label => 'test-publishing-group')
    @publisher = Factory(:publisher,
                         :publishing_group => publishing_group,
                         :label => "test-publisher")
    @registers = { :controller => @controller, :publisher => @publisher }
    Rails.env.stubs(:production?).returns(false)
  end

  test "template path with no theme" do
    assert_template "{% include with_theme 'bar' %}",
      "Bar's template"
  end

  test "template path with publisher theme" do
    assert_template "{% include with_theme 'baz' %}",
      "Publisher's baz template"
  end

  test "template path with publishing group theme" do
    assert_template "{% include with_theme 'foo' %}",
      "Publishing group's foo template"
  end

  test "no such template" do
    assert_raise RuntimeError do
       Liquid::Template.parse("{% include 'does_not_exist' %}").render!
    end

    assert_raise RuntimeError do
       Liquid::Template.parse("{% include with_theme 'does_not_exist' %}").render!
    end
  end
  
  test "no such template in production 'with_theme'" do
   Rails.env.stubs(:production?).returns(true)
   assert_raise RuntimeError do
     Liquid::Template.parse("{% include with_theme 'does_not_exist' %}").render
   end
  end

  test "no such template in dev 'with_theme'" do
   Rails.env.stubs(:production?).returns(false)
   assert_raise RuntimeError do
      Liquid::Template.parse("{% include with_theme 'does_not_exist' %}").render!
   end
  end

  test "with no publisher set" do
    assert_template "{% include with_theme 'foo' %}",
      "Foo's template", {}
    assert_template "{% include with_theme 'baz' %}",
      "Baz's template", {}
  end

  test "publisher doesn't have publishing group" do
    @publisher.publishing_group = nil
    assert_template "{% include with_theme 'foo' %}",
      "Foo's template"
  end

  test "standard include" do
    assert_template "{% include 'foo' %}",
      "Foo's template"
    assert_template "{% include 'themes/test-publishing-group/foo' %}",
      "Publishing group's foo template"
  end

  test "standard include using a variable as a path" do
    assert_template "{% assign test_template = 'foo' %}{% include test_template %}",
      "Foo's template"
  end

  test "template path with publishing group theme using a variable path" do
    assert_template "{% assign test_template = 'foo' %}{% include with_theme test_template %}",
      "Publishing group's foo template"
  end

  test "standard include with 'with'" do
    assert_template "{% include 'xyz' with 'test value' %}",
      "Value: test value"
  end

  test "with_theme with 'with'" do
    assert_template "{% include with_theme 'xyz' with 'test value' %}",
      "Publisher's Value: test value"
  end
  
  test "standard include with variable" do
    assert_template "{% include 'variables' val: 'test value' %}",
      "Value: test value"
  end

  test "with_theme with variable" do
    assert_template "{% include with_theme 'variables' val: 'test value' %}",
      "Value: test value"
  end

  test "include default template when no locale specific version is present without with_theme" do
    I18n.locale = :cn
    assert_template "{% include 'localized' %}", "Default English"
  end

  test "use default template when no localed version exists without with_theme" do
    I18n.locale = :cn
    assert_template "{% include 'other_localized' %}", "Default"
  end

  test "include default localized template when available when not using with_theme" do
    I18n.locale = :es
    assert_template "{% include 'localized' %}", "Default Spanish"
  end

  test "use default template when no localed version exists using with_theme" do
    I18n.locale = :cn
    assert_template "{% include with_theme 'other_localized' %}", "Default"
  end
  
  test "include default_locales publishing group template when no publisher exists for locale using with_theme" do
    I18n.locale = :de
    assert_template "{% include with_theme 'localized' %}", "Publishing group's English"
  end
  
  test "include publishers localized template when possible is present" do
    I18n.locale = :es
    assert_template "{% include with_theme 'localized' %}", "Publisher's Spanish"
  end

  test "include publishing group's localized template when possible is present" do
    I18n.locale = :en
    assert_template "{% include with_theme 'localized' %}", "Publishing group's English"
  end

  context "ready made themes on publishers" do
    
    setup do
      @publisher = Factory :publisher, :parent_theme => "cleverbetta"
    end
    
    should "render the ready made theme template when there is no publisher specific version" do
      assert_template "{% include with_theme 'custom_stylesheets' %}", "<!-- override this for custom stylesheets -->"
    end
    
  end
  
  context "ready made themes on publishing groups" do
    
    setup do
      @publishing_group = Factory :publishing_group, :label => "capetimes", :parent_theme => "roaringlion"
      @publisher = Factory :publisher, :publishing_group => @publishing_group
    end
    
    should "render the ready made theme template when there is no publishing group/publisher-specific one" do
      assert_template "{% include with_theme 'sidebar' %}", "the default sidebar"
    end
    
  end

  context "when a publisher's parent_theme differs from its publishing group's parent_theme" do
    
    setup do
      @publishing_group = Factory :publishing_group, :label => "capetimes", :parent_theme => "roaringlion"
      @publisher = Factory :publisher, :publishing_group => @publishing_group, :parent_theme => "cleverbetta"
    end
    
    context "and the publisher has not customized a given template" do

      should "render the template from the publisher's parent_theme" do
        assert_template "{% include with_theme 'sidebar' %}", "cleverbetta default sidebar"
      end
      
    end
    
  end
end
