require File.dirname(__FILE__) + "/../../test_helper"

class AdvertisersController::NewTest < ActionController::TestCase
  tests AdvertisersController

  def setup
    login_as Factory(:admin)
    @publisher = Factory(:publisher, :label => "bespoke")
  end

  should "render a new advertiser for the specified publisher" do
    get :new, 'publisher_id' => @publisher.to_param
    assert_response :success
    advertiser = assigns['advertiser']
    assert_equal @publisher, advertiser.publisher
    assert_template :edit
  end

  should "have standard advertiser inputs" do
    get :new, 'publisher_id' => @publisher.to_param
    assert_select "form.new_advertiser" do
      assert_select "select[name='advertiser[size]']" do
        assert_select "option[value=]", ""
        assert_select "option[value=SME]", "SME"
        assert_select "option[value=Large]", "Large"
      end
    end
  end

  context "publisher with disabled features" do
    setup do
      @publisher.update_attributes!(:advertiser_has_listing => false, :txt_keyword_prefix => nil)
    end

    should "not show the inputs for the features" do
      get :new, 'publisher_id' => @publisher.to_param
      assert_select "form.new_advertiser" do
        assert_select "input[type=text][name='advertiser[listing]']", 0
        assert_select "input[type=text][name='advertiser[txt_keyword_prefix]']", 0
      end
    end
  end

  context "publisher with enabled features" do
    setup do
      @publisher.update_attributes!(:advertiser_has_listing => true, :txt_keyword_prefix => "PRE")
    end

    should "show inputs for the features" do
      get :new, 'publisher_id' => @publisher.to_param
      assert_select "form.new_advertiser" do
        assert_select "input[type=text][name='advertiser[listing]']"
        assert_select "input[type=text][name='advertiser[txt_keyword_prefix]']"
      end
    end
  end

end
