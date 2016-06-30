require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class AdvertisersController::Edit::StoresTest

module AdvertisersController::Edit
  class StoresTest < ActionController::TestCase
    tests AdvertisersController

    should "have listing field for full admin" do
      user, store = publishing_group_user_and_store(nil, User::FULL_ADMIN)
      edit_advertiser_for_store(user, store)
      assert_select "input[type=text][name='advertiser[stores_attributes][0][listing]'][value='#{store.listing}']", 1
    end

    should "have listing field for Entertainment Group user" do
      user, store = publishing_group_user_and_store('entertainment', nil)
      edit_advertiser_for_store(user, store)
      assert_select "input[type=text][name='advertiser[stores_attributes][0][listing]'][value='#{store.listing}']", 1
    end

    should "not have listing field for other users" do
      user, store = publishing_group_user_and_store('notentertainment', nil)
      edit_advertiser_for_store(user, store)
      assert_select "#advertiser_stores_attributes_0_listing", 0
    end


    private

    def edit_advertiser_for_store(user, store, should_see_listing=true)
      login_as user
      get :edit, :id => store.advertiser.to_param
      assert_response :success
    end

    def publishing_group_user_and_store(pub_group_label, admin_flag)
      store = store_with_self_serve_advertiser_publisher()

      pg = store.advertiser.publisher.publishing_group
      pg.self_serve = true # so the user can manage the advertiser, I think???
      pg.label = pub_group_label if pub_group_label
      pg.save!

      user = Factory(:user_without_company, :admin_privilege => admin_flag)
      user.user_companies << UserCompany.new(:company => pg) if pub_group_label

      [user, store]
    end

    def store_with_self_serve_advertiser_publisher
      advertiser = Factory(:advertiser)

      advertiser.publisher.tap do |pub|
        pub.self_serve = true
        pub.save!
      end

      advertiser.stores.first.tap do |store|
        store.update_attribute(:listing, 'something not nil')
      end
    end
  end
end
