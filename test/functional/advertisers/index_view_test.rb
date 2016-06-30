require File.dirname(__FILE__) + "/../../test_helper"

class Advertisers::IndexViewTest < ActionView::TestCase
  helper :advertisers

  helper do
    def admin?
      false
    end

    def protect_against_forgery?
      false
    end

    def edit_advertiser_path(advertiser)
      ""
    end

    def current_user
      @user
    end
  end

  def setup
    ActionController::Base.prepend_view_path 'app/views/advertisers'
    @user = Factory(:user)
    @publisher = @user.company
    Factory(:advertiser, :publisher => @publisher)
    @advertisers = Advertiser.search(:publisher => @publisher).paginate
    assert_present @advertisers
  end

  context "search form" do
    should "have inputs, and submit and clear buttons" do
      I18n.with_locale(:'en-GB') do
        render :file => 'index'
      end
      assert_select 'form.search[method=GET]' do
        assert_select 'label[for=name]', 'Name'
        assert_select 'input[name=name][value=]'
        assert_select 'label[for=zip]', 'Postcode'
        assert_select 'input[name=zip][value=]'
        assert_select 'input[type=submit][value=Search]'
        assert_select 'input[type=button][value=Clear]'
      end
    end

    should "be sticky" do
      @controller.params = {:name => 'pizza', :zip => 'e14'}
      render :file => 'index'
      assert_select 'input[name=name][value=pizza]'
      assert_select 'input[name=zip][value=e14]'
    end
  end

  context "A-Z quick links" do
    should "have only the current link active" do
      @controller.params = {:name => '^T'}
      render :file => 'index'
      assert_select 'input[name=name][value=^T]'
      assert_select 'ul.az_advertiser_menu li.active a', 'T'
      assert_select 'ul.az_advertiser_menu li.active a', 1
    end
  end
end
