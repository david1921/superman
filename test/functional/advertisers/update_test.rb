require File.dirname(__FILE__) + "/../../test_helper"

class AdvertisersController::UpdateTest < ActionController::TestCase
  tests AdvertisersController

  def setup
    @advertiser = Factory(:advertiser, :size => "Large")
    @publisher = @advertiser.reload.publisher.tap{|pub| pub.update_attributes!(:advertiser_self_serve => true)}
    @admin = Factory(:admin)
    @advertiser_user = Factory(:user_without_company).tap{|u| u.user_companies.create!(:company => @advertiser)}
  end

  context "successful response" do
    context "as advertiser user" do
      setup do
        login_as @advertiser_user
      end

      should "go to edit page when existing offers" do
        @advertiser.offers << Factory(:offer, :advertiser => @advertiser)
        put :update, :id => @advertiser.to_param, :advertiser => {}
        assert_redirected_to edit_advertiser_path(@advertiser)
      end

      should "go to new offer page when no existing offers" do
        put :update, :id => @advertiser.to_param, :advertiser => {}
        assert_redirected_to new_advertiser_offer_path(@advertiser)
      end
    end

    context "publisher user or admin" do
      should "go to the advertiser edit w/ 'Updated' flash message" do
        login_as @admin
        put :update, :id => @advertiser.to_param, :advertiser => { :name => "Updated Advertiser" }
        assert_redirected_to edit_publisher_advertiser_path(@advertiser.publisher)
        assert flash[:notice].present?
      end
    end
  end

  should "update the record" do
    @advertiser.update_attributes!(
      :name => "Old Advertiser",
      :size => "Large",
      :logo => ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png'),
      :coupon_clipping_modes => [:email]
    )
    @advertiser.save!

    login_as @admin
    put :update, :id => @advertiser.to_param,
        :advertiser => {
          :name => "New Advertiser",
          :size => "SME",
          :logo => fixture_file_upload('/files/advertiser_logo.png', 'image/png'),
          :coupon_clipping_modes => [:txt]
        }

    assert_response :redirect
    assert flash[:notice].present?
    @advertiser.reload
    assert_equal "New Advertiser", @advertiser.name
    assert_equal "SME", @advertiser.size
    assert_equal "advertiser_logo.png", @advertiser.logo_file_name
    assert @advertiser.allows_clipping_via(:txt)
  end

  should "not delete store if all fields blank" do
    store = @advertiser.stores.first
    assert store.valid?, "Store should be valid, but: #{store.errors.full_messages}"
    name_before_update = @advertiser.name

    login_as @admin
    put :update,
        'id' => @advertiser.to_param,
        'advertiser' => {
          :name => "Updated Advertiser",
          :stores_attributes => {
            "0" => {"city"=>"", "zip"=>"", "id"=> store.to_param, "address_line_1"=>"", "phone_number"=>"", "address_line_2"=>"", "state"=>""}
          }
        }

    assert_response :success
    assert assigns(:advertiser).store.errors.present?, "Should have errors on store"
    assert_equal name_before_update, @advertiser.reload.name
    assert Store.exists?(store.id), "Should preserve store if all fields are set to blank"
  end

  should "clear clipping modes (for some unknown reason)" do
    @advertiser.update_attributes! :coupon_clipping_modes => [:email, :txt]
    assert @advertiser.allows_clipping_via(:txt)

    login_as @admin
    put :update, :id => @advertiser.to_param, :advertiser => {}

    assert flash[:notice].present?
    Advertiser::RECOGNIZED_COUPON_CLIPPING_MODES.each do |mode|
      assert !@advertiser.reload.allows_clipping_via(mode), "Advertiser should not allow #{mode} clipping"
    end
  end

end
