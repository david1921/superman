require File.dirname(__FILE__) + "/../../controllers_helper"

# hydra class Publishers::ThemesTest
module Publishers
  class ThemesTest < Test::Unit::TestCase

    def setup
      @themes = Object.new.extend(Publishers::Themes)
      @themes.stubs(:controller_name).returns("some_controller")
      @themes.stubs(:action_name).returns("some_action")
    end

    context "ClassMethods" do
      setup do
        @class_methods = Object.new.extend(Publishers::Themes::ClassMethods)
      end

      context "#with_theme_unless_admin" do
        context "current user is an admin" do
          should "return a proc that returns the specified layout" do
            mock_admin = mock('admin', :has_admin_privilege? => true)
            mock_controller = mock('controller', :current_user => mock_admin)
            layout = "passed layout"
            some_proc = @class_methods.with_theme_unless_admin_user(layout)

            assert_kind_of Proc, some_proc
            proc_result = some_proc.call(mock_controller)
            assert_equal "passed layout", proc_result
          end
        end

        context "current user is not an admin" do
          should "return what #with_theme returns" do
            args = ['layout path', {}]

            mock_admin = mock('admin', :has_admin_privilege? => false)
            mock_controller = mock('controller', :current_user => mock_admin)

            with_theme_return_value = mock('with_theme return value')
            mock_proc = mock('with_theme proc')
            mock_proc.expects(:call).with(mock_controller).returns(with_theme_return_value)
            @class_methods.stubs(:with_theme).with(*args).returns(mock_proc)

            some_proc = @class_methods.with_theme_unless_admin_user(*args)

            assert_kind_of Proc, some_proc
            proc_result = some_proc.call(mock_controller)
            assert_equal with_theme_return_value, proc_result
          end
        end
      end
    end

    context "#with_theme_unless_admin_user" do
      context "user without admin privileges" do
        should "return result of with_theme(*options)" do
          @themes.stubs(:user_without_admin_privilege?).returns(true)
          options = [{:layout => "application", :template => "edit"}]
          mock_returned_options = mock("returned options")
          @themes.stubs(:with_theme).with(*options).returns(mock_returned_options)
          assert_equal mock_returned_options, @themes.with_theme_unless_admin_user(*options)
        end
      end

      context "user with admin privileges" do
        should "return 'extracted' options" do
          @themes.stubs(:user_without_admin_privilege?).returns(false)
          options = [{:layout => "application", :template => "edit"}]
          assert_equal options.dup.try(:flatten).extract_options!, @themes.with_theme_unless_admin_user(*options)
        end
      end
    end

    context "#theme_source" do
      should "return current user's company when @publisher and @publishing_group are nil" do
        mock_company = mock("company")
        @themes.stubs(:current_user_publisher_or_publishing_group).returns(mock_company)
        @themes.instance_variable_set(:@publisher, nil)
        @themes.instance_variable_set(:@publishing_group, nil)
        assert_equal mock_company, @themes.theme_source
      end

      should "return @publisher when not nil" do
        mock_publisher = mock("publisher")
        @themes.instance_variable_set(:@publisher, mock_publisher)
        assert_equal mock_publisher, @themes.theme_source
      end

      should "return @publishing_group when @publisher nil" do
        mock_publishing_group = mock("publishing group")
        @themes.instance_variable_set(:@publisher, nil)
        @themes.instance_variable_set(:@publishing_group, mock_publishing_group)
        assert_equal mock_publishing_group, @themes.theme_source
      end
    end
  end
end
