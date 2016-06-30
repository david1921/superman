require File.dirname(__FILE__) + "/../test_helper"

class TxtOffersControllerTest < ActionController::TestCase
  def test_new
    advertiser = advertisers(:changos)
    check_response = lambda { |role|
      assert_response :success, role
      assert_template :edit, role
      assert_select "form.new_txt_offer", 1 do
        assert_select "select[name='txt_offer[keyword_prefix]']", 1 do
          assert_select "option[value=SDH]", /\ASDH\z/
        end
        assert_select "input[type=text][name='txt_offer[keyword_suffix]']", 1
        assert_select "input[type=checkbox][name='txt_offer[assign_keyword]']", 1
        assert_select "textarea[name='txt_offer[message]']", 1
        assert_select "input[type=text][name='txt_offer[appears_on]']", 1
        assert_select "input[type=text][name='txt_offer[expires_on]']", 1
        assert_select "input[type=submit]", 1
      end
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      get :new, :advertiser_id => advertiser.to_param
    end
  end
  
  def test_new_with_advertiser_txt_keyword_prefix
    advertiser = advertisers(:changos)
    advertiser.update_attributes! :txt_keyword_prefix => "TACO"
    
    check_response = lambda { |role|
      assert_response :success, role
      assert_template :edit, role
      assert_select "form.new_txt_offer", 1 do
        assert_select "select[name='txt_offer[keyword_prefix]']", 1 do
          assert_select "option[value=SDHTACO]", /\ASDHTACO\z/
        end
        assert_select "input[type=text][name='txt_offer[keyword_suffix]']", 1
        assert_select "input[type=checkbox][name='txt_offer[assign_keyword]']", 1
        assert_select "textarea[name='txt_offer[message]']", 1
        assert_select "input[type=text][name='txt_offer[appears_on]']", 1
        assert_select "input[type=text][name='txt_offer[expires_on]']", 1
        assert_select "input[type=submit]", 1
      end
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      get :new, :advertiser_id => advertiser.to_param
    end
  end
  
  def test_create_with_auto_keyword_assignment
    advertiser = advertisers(:changos)
    check_response = lambda { |role|
      assert_redirected_to edit_advertiser_path(advertiser)
      txt_offer = advertiser.txt_offers(true).first
      assert_not_nil txt_offer, "TXT offer should have been created as #{role}"
      assert_equal "898411", txt_offer.short_code, role
      assert_match /\ASDH\d+\z/, txt_offer.keyword, role
      assert_equal "Buy one taco, get one free", txt_offer.message, role
      assert_equal Date.parse("Jan 01, 2008"), txt_offer.appears_on, role
      assert_equal Date.parse("Jan 31, 2008"), txt_offer.expires_on, role
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      advertiser.txt_offers.destroy_all
      post :create, :advertiser_id => advertiser.to_param, :txt_offer => {
        :keyword_prefix => "SDH",
        :assign_keyword => "1",
        :keyword_suffix => "",
        :message => "Buy one taco, get one free",
        :appears_on => "Jan 01, 2008",
        :expires_on => "Jan 31, 2008"
      }
    end
  end
  
  def test_create_with_manual_keyword_assignment
    advertiser = advertisers(:changos)
    check_response = lambda { |role|
      assert_redirected_to edit_advertiser_path(advertiser)
      txt_offer = advertiser.txt_offers(true).first
      assert_not_nil txt_offer, "TXT offer should have been created as #{role}"
      assert_equal "898411", txt_offer.short_code, role
      assert_equal "SDHTACO", txt_offer.keyword, role
      assert_equal "Buy one taco, get one free", txt_offer.message, role
      assert_equal Date.parse("Jan 01, 2008"), txt_offer.appears_on, role
      assert_equal Date.parse("Jan 31, 2008"), txt_offer.expires_on, role
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      advertiser.txt_offers.destroy_all
      post :create, :advertiser_id => advertiser.to_param, :txt_offer => {
        :keyword_prefix => "SDH",
        :assign_keyword => "0",
        :keyword_suffix => "TACO",
        :message => "Buy one taco, get one free",
        :appears_on => "Jan 01, 2008",
        :expires_on => "Jan 31, 2008"
      }
    end
  end
  
  def test_invalid_create
    advertiser = advertisers(:changos)
    check_response = lambda { |role|
      assert_response :success, role
      assert_template :edit, role
      txt_offer = assigns(:txt_offer)
      assert_not_nil txt_offer, "Assignment of @txt_offer as #{role}"
      assert txt_offer.errors.any?, "Should have errors as #{role}"
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      post :create, :advertiser_id => advertiser.to_param, :txt_offer => {
        :keyword_prefix => "SDH",
        :assign_keyword => "0",
        :keyword_suffix => "",
        :message => "Buy one taco, get one free"
      }
    end
  end

  def test_edit
    advertiser = advertisers(:changos)
    txt_offer = advertiser.txt_offers.create!(
      :short_code => "898411",
      :keyword => "SDH0001",
      :message => "Buy one taco, get one free",
      :appears_on => "Jan 01, 2008",
      :expires_on => "Jan 31, 2008"
    )
    check_response = lambda { |role|
      assert_response :success, role
      assert_equal txt_offer, assigns(:txt_offer), "Assignment of @txt_offer as #{role}"
      assert_select "form.edit_txt_offer", 1 do
        assert_select "input[type=text][name='txt_offer[label]']", 0
        assert_select "select[name='txt_offer[keyword_prefix]']", 0
        assert_select "input[type=text][name='txt_offer[keyword_suffix]']", 0
        assert_select "input[type=checkbox][name='txt_offer[assign_keyword]']", 0
        assert_select "textarea[name='txt_offer[message]']", 1
        assert_select "input[type=text][name='txt_offer[appears_on]']", 1
        assert_select "input[type=text][name='txt_offer[expires_on]']", 1
        assert_select "input[type=submit]", 1
      end
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      get :edit, :advertiser_id => advertiser.to_param, :id => txt_offer.to_param
    end
  end
  
  def test_edit_with_publisher_with_advertiser_listing
    advertiser = advertisers(:changos)
    advertiser.publisher.update_attributes! :advertiser_has_listing => true

    txt_offer = advertiser.txt_offers.create!(
      :short_code => "898411",
      :keyword => "SDH0001",
      :message => "Buy one taco, get one free",
      :appears_on => "Jan 01, 2008",
      :expires_on => "Jan 31, 2008"
    )
    check_response = lambda { |role|
      assert_response :success, role
      assert_equal txt_offer, assigns(:txt_offer), "Assignment of @txt_offer as #{role}"
      assert_select "form.edit_txt_offer", 1 do
        assert_select "input[type=text][name='txt_offer[label]']", role =~ /advertiser/i ? 0 : 1
        assert_select "select[name='txt_offer[keyword_prefix]']", 0
        assert_select "input[type=text][name='txt_offer[keyword_suffix]']", 0
        assert_select "input[type=checkbox][name='txt_offer[assign_keyword]']", 0
        assert_select "textarea[name='txt_offer[message]']", 1
        assert_select "input[type=text][name='txt_offer[appears_on]']", 1
        assert_select "input[type=text][name='txt_offer[expires_on]']", 1
        assert_select "input[type=submit]", 1
      end
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      get :edit, :advertiser_id => advertiser.to_param, :id => txt_offer.to_param
    end
  end
  
  def test_edit_with_advertiser_txt_keyword_prefix
    advertiser = advertisers(:changos)
    advertiser.update_attributes! :txt_keyword_prefix => "TACO"
    
    txt_offer = advertiser.txt_offers.create!(
      :short_code => "898411",
      :keyword => "SDHTACO1",
      :message => "Buy one taco, get one free",
      :appears_on => "Jan 01, 2008",
      :expires_on => "Jan 31, 2008"
    )
    check_response = lambda { |role|
      assert_response :success, role
      assert_equal txt_offer, assigns(:txt_offer), "Assignment of @txt_offer as #{role}"
      assert_select "form.edit_txt_offer", 1 do
        assert_select "input[type=text][name='txt_offer[label]']", 0
        assert_select "select[name='txt_offer[keyword_prefix]']", 0
        assert_select "input[type=text][name='txt_offer[keyword_suffix]']", 0
        assert_select "input[type=checkbox][name='txt_offer[assign_keyword]']", 0
        assert_select "textarea[name='txt_offer[message]']", 1
        assert_select "input[type=text][name='txt_offer[appears_on]']", 1
        assert_select "input[type=text][name='txt_offer[expires_on]']", 1
        assert_select "input[type=submit]", 1
      end
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      get :edit, :advertiser_id => advertiser.to_param, :id => txt_offer.to_param
    end
  end
  
  def test_update
    advertiser = advertisers(:changos)
    txt_offer = advertiser.txt_offers.create!(
      :short_code => "898411",
      :keyword => "SDH0001",
      :message => "Buy one taco, get one free",
      :appears_on => "Jan 01, 2008",
      :expires_on => "Jan 31, 2008"
    )
    check_response = lambda { |role|
      assert_redirected_to edit_advertiser_path(advertiser)
      txt_offer.reload
      assert_equal "898411", txt_offer.short_code, "Short code should not change as #{role}"
      assert_equal "SDH0001", txt_offer.keyword, "Keyword should not change as #{role}"
      assert_equal "Buy two tacos, get one free", txt_offer.message, "Updated message as #{role}"
      assert_equal Date.parse("Feb 01, 2008"), txt_offer.appears_on, "Updated appears_on as #{role}"
      assert_equal Date.parse("Feb 28, 2008"), txt_offer.expires_on, "Updated expires_on as #{role}"
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      txt_offer.update_attributes! :message => "Buy one taco, get one free", :appears_on => "Jan 01, 2008", :expires_on => "Jan 31, 2008"
      put :update, :advertiser_id => advertiser.to_param, :id => txt_offer.to_param, :txt_offer => {
        :message => "Buy two tacos, get one free",
        :appears_on => "Feb 01, 2008",
        :expires_on => "Feb 28, 2008"
      }
    end
  end
  
  def test_cannot_update_short_code_or_keyword
    advertiser = advertisers(:changos)
    txt_offer = advertiser.txt_offers.create!(
      :short_code => "898411",
      :keyword => "SDH0001",
      :message => "Buy one taco, get one free",
      :appears_on => "Jan 01, 2008",
      :expires_on => "Jan 31, 2008"
    )
    check_response = lambda { |role|
      assert_response :success
      assert_template :edit
      assert_equal txt_offer.reload, assigns(:txt_offer), "Assignment of @txt_offer as #{role}"
      assert assigns(:txt_offer).errors.any?, "Should have errors as #{role}"
      assert_equal "898411", txt_offer.short_code, "Short code should not change as #{role}"
      assert_equal "SDH0001", txt_offer.keyword, "Keyword should not change as #{role}"
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      put :update, :advertiser_id => advertiser.to_param, :id => txt_offer.to_param, :txt_offer => { :short_code => "898444" }
    end
    with_login_managing_advertiser_required(advertiser, check_response) do
      put :update, :advertiser_id => advertiser.to_param, :id => txt_offer.to_param, :txt_offer => { :keyword => "SDH0002" }
    end
  end
  
  def test_destroy
    advertiser = advertisers(:changos)
    check_response = lambda { |role|
      assert_redirected_to edit_advertiser_path(advertiser)
      assert_equal 1, advertiser.txt_offers(true).count, "Should still have a TXT offer as #{role}"
      assert_equal 0, advertiser.txt_offers(true).not_deleted.count, "TXT offer should have deleted flag set as #{role}"
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      advertiser.txt_offers.destroy_all
      txt_offer = advertiser.txt_offers.create!(
        :short_code => "898411",
        :keyword => "SDH0001",
        :message => "Buy one taco, get one free",
        :appears_on => "Jan 01, 2008",
        :expires_on => "Jan 31, 2008"
      )
      delete :destroy, :advertiser_id => advertiser.to_param, :id => txt_offer.to_param
    end
  end
end
