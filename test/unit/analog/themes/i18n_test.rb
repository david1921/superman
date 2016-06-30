require File.join(File.dirname(__FILE__), "..", "..", "..", "test_helper")

# hydra class Analog::Themes::I18nTest

module Analog
  module Themes

    class I18nTest < ActiveSupport::TestCase

      context "themed translations" do
        setup do
          ::I18n.stubs(:translate).returns(nil)
          ::I18n.stubs(:translate).with(:message, :scope => ["pub-group-label"], :raise => true).returns(nil)
          ::I18n.stubs(:translate).with(:message, :scope => ["pub-label"], :raise => true).returns(nil)
          ::I18n.stubs(:translate).with(:message, {}).returns("Default translation")
        end

        context "given nil" do
          should "return default translation" do
            assert_equal "Default translation", Analog::Themes::I18n.t(nil, :message)
          end
        end

        context "given a publisher" do
          setup do
            @publisher = Factory(:publisher, :label => "pub-label")
          end

          should "alias translate to t" do
            assert_equal "Default translation", Analog::Themes::I18n.t(@publisher, :message)
          end

          should "allow string scopes" do
            ::I18n.stubs(:translate).with(:other_message, {:scope => "foo.bar"}).returns("Baz")
            assert_equal "Baz", Analog::Themes::I18n.t(@publisher, :other_message, :scope => "foo.bar")
          end

          should "allow symbol scopes" do
            ::I18n.stubs(:translate).with(:other_message, {:scope => :foo}).returns("Baz")
            assert_equal "Baz", Analog::Themes::I18n.t(@publisher, :other_message, :scope => :foo)
          end

          context "given publisher does not have a themed translation" do
            should "return default translation" do
              assert_equal "Default translation", Analog::Themes::I18n.translate(@publisher, :message)
            end
          end

          context "given the publisher has a themed translation" do
            setup do
              ::I18n.stubs(:translate).with(:message, :scope => ["pub-label"], :raise => true).returns("Publisher's translation")
            end

            should "return themed translation" do
              assert_equal "Publisher's translation", Analog::Themes::I18n.translate(@publisher, :message)
            end
          end
        end

        context "given a publishing group" do
          setup do
            @publishing_group = Factory(:publishing_group, :label => "pub-group-label")
          end

          context "given publishing group does not have a themed translation" do
            should "return default translation" do
              assert_equal "Default translation", Analog::Themes::I18n.translate(@publishing_group, :message)
            end
          end

          context "given the publishing group has a themed translation" do
            setup do
              ::I18n.stubs(:translate).with(:message, :scope => ["pub-group-label"], :raise => true).returns("Publishing group's translation")
            end

            should "return themed translation" do
              assert_equal "Publishing group's translation", Analog::Themes::I18n.translate(@publishing_group, :message)
            end
          end
        end
      end

    end

  end
end
