  require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::ThemeHelperTest

module Publishers
  
  class ThemeHelperTest < ActionView::TestCase

    context "stylesheet_link_tag_with_theme" do

      setup do
        @publisher = Factory(:publisher)
      end

      context "without @publisher set" do
        should "return the default stylesheet link" do
          assert_equal stylesheet_link_tag('sass/hello'), stylesheet_link_tag_with_theme('hello')
        end
      end

      context "publisher and publishing group file do no exist" do
        setup do
          File.stubs(:exists?).with(File.join(Rails.public_path, "themes/#{@publisher.label}/stylesheets/hello.css")).returns(false)
          File.stubs(:exists?).with(File.join(Rails.public_path, "themes/#{@publisher.publishing_group.label}/stylesheets/hello.css")).returns(false)
        end
        should "return the default stylesheet without an extention" do
          assert_equal stylesheet_link_tag('sass/hello'), stylesheet_link_tag_with_theme('hello')
        end
        should "return the default stylesheet with an extension" do
          assert_equal stylesheet_link_tag('sass/hello'), stylesheet_link_tag_with_theme('hello.css')
        end
      end

      context "publisher and publishing group exist" do
        setup do
          File.stubs(:exists?).with(File.join(Rails.public_path, "themes/#{@publisher.label}/stylesheets/hello.css")).returns(true)
          File.stubs(:exists?).with(File.join(Rails.public_path, "themes/#{@publisher.publishing_group.label}/stylesheets/hello.css")).returns(true)
        end
        should "return a link to the publisher's stylesheet without an extension" do
          assert_equal stylesheet_link_tag("/themes/#{@publisher.label}/stylesheets/hello"), stylesheet_link_tag_with_theme("hello")
        end
        should "return a link to the publisher's stylesheet with an extension" do
          assert_equal stylesheet_link_tag("/themes/#{@publisher.label}/stylesheets/hello"), stylesheet_link_tag_with_theme("hello.css")
        end
      end

      context "publisher exists and publishing group does not exist" do
        setup do
          File.stubs(:exists?).with(File.join(Rails.public_path, "themes/#{@publisher.label}/stylesheets/hello.css")).returns(true)
          File.stubs(:exists?).with(File.join(Rails.public_path, "themes/#{@publisher.publishing_group.label}/stylesheets/hello.css")).returns(false)
        end
        should "return a link to the publisher's stylesheet without an extension" do
          assert_equal stylesheet_link_tag("/themes/#{@publisher.label}/stylesheets/hello"), stylesheet_link_tag_with_theme("hello")
        end
        should "return a link to the publisher's stylesheet with an extension" do
          assert_equal stylesheet_link_tag("/themes/#{@publisher.label}/stylesheets/hello"), stylesheet_link_tag_with_theme("hello.css")
        end
      end

      context "publisher does not exist and publishing group exists" do
        setup do
          File.stubs(:exists?).with(File.join(Rails.public_path, "themes/#{@publisher.label}/stylesheets/hello.css")).returns(false)
          File.stubs(:exists?).with(File.join(Rails.public_path, "themes/#{@publisher.publishing_group.label}/stylesheets/hello.css")).returns(true)
        end
        should "return a link to the publisher's stylesheet without an extension" do
          assert_equal stylesheet_link_tag("/themes/#{@publisher.publishing_group.label}/stylesheets/hello"), stylesheet_link_tag_with_theme("hello")
        end
        should "return a link to the publisher's stylesheet with an extension" do
          assert_equal stylesheet_link_tag("/themes/#{@publisher.publishing_group.label}/stylesheets/hello"), stylesheet_link_tag_with_theme("hello.css")
        end
      end

      context "with one stylesheet option" do
        setup do
          File.stubs(:exists?).with(File.join(Rails.public_path, "themes/#{@publisher.label}/stylesheets/hello.css")).returns(true)
          File.stubs(:exists?).with(File.join(Rails.public_path, "themes/#{@publisher.publishing_group.label}/stylesheets/hello.css")).returns(true)
        end

        should "return a link to the publisher's stylesheets with print media" do
          assert_equal stylesheet_link_tag("/themes/#{@publisher.label}/stylesheets/hello", :media => 'print'), stylesheet_link_tag_with_theme("hello", :media => :print)
        end
      end

      context "with multiple stylesheets" do
        setup do
          File.stubs(:exists?).with(File.join(Rails.public_path, "themes/#{@publisher.label}/stylesheets/hello.css")).returns(true)
          File.stubs(:exists?).with(File.join(Rails.public_path, "themes/#{@publisher.label}/stylesheets/goodbye.css")).returns(true)
        end

        should "return multiple links to the publisher's stylesheets" do
          assert_equal stylesheet_link_tag("/themes/#{@publisher.label}/stylesheets/hello", "/themes/#{@publisher.label}/stylesheets/goodbye"), stylesheet_link_tag_with_theme("hello", "goodbye")
        end

        should "return multiple links to the publisher's stylesheets with passed options" do
          assert_equal stylesheet_link_tag("/themes/#{@publisher.label}/stylesheets/hello", "/themes/#{@publisher.label}/stylesheets/goodbye", :media => "print"), stylesheet_link_tag_with_theme("hello", "goodbye", :media => "print")
        end
      end

    end

    context "logo_with_theme" do
      setup do
        @publishing_group = Factory(:publishing_group)
        @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      end

      context "publisher and publishing group logo do not exist" do
        setup do
          @publisher.stubs(:logo?).returns(false)
          @publishing_group.stubs(:logo?).returns(false)
        end

        should "return the url of the default logo" do
          assert_equal "/hello.jpg", logo_with_theme("/hello.jpg", :normal)
        end
      end

      context "publisher logo exists and publishing group logo does not exist" do
        setup do
          @publisher.stubs(:logo?).returns(true)
          normal_stub = url_stub(:normal, "goodbye.jpg")
          @publisher.stubs(:logo).returns(normal_stub)
          @publishing_group.stubs(:logo?).returns(false)
        end

        should "return the url of the publisher logo" do
          assert_equal @publisher.logo.url(:normal), logo_with_theme("/hello.jpg", :normal)
        end
      end

      context "publisher logo does no exist and publishing group logo does exist" do
        setup do
          @publisher.stubs(:logo?).returns(false)
          @publishing_group.stubs(:logo?).returns(true)
          normal_stub = url_stub(:normal, "hola.jpg")
          @publisher.stubs(:logo).returns(normal_stub)
        end

        should "return the url of the publishing group logo" do
          assert_equal @publishing_group.logo.url(:normal), logo_with_theme("/hello.jpg", :normal)
        end
      end

      context "both publisher logo and publishing group logo exists" do
        setup do
          @publisher.stubs(:logo?).returns(true)
          full_size_stub = url_stub(:normal, "goodbye.jpg")
          @publisher.stubs(:logo).returns(full_size_stub)
          normal_stub = url_stub(:normal, "goodbye.jpg")
          @publisher.stubs(:logo).returns(normal_stub)
          @publishing_group.stubs(:logo?).returns(true)
        end

        should "return the url of the publisher logo" do
          assert_equal @publisher.logo.url(:normal), logo_with_theme("/hello.jpg", :normal)
        end
      end

      context "full size option" do
        setup do
          @publisher.stubs(:logo?).returns(true)
          full_size_stub = url_stub(:full_size, "goodbye.jpg")
          @publisher.stubs(:logo).returns(full_size_stub)
          normal_stub = url_stub(:full_size, "goodbye.jpg")
          @publisher.stubs(:logo).returns(normal_stub)
          @publishing_group.stubs(:logo?).returns(true)
        end

        should "return the url of the publisher logo" do
          assert_equal @publisher.logo.url(:full_size), logo_with_theme("/hello.jpg", :full_size)
        end
      end
    end


    def url_stub(style, value)
      stub_result = stub
      stub_result.stubs(:url).with(style).returns(value)
      stub_result
    end

  end

end