require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::EditTest < ActionController::TestCase
  tests OffersController

  assert_no_angle_brackets :except => [ :test_edit_when_publishing_group_and_offer_both_have_categories ]

  def test_edit_with_simple_publisher
    advertiser = advertisers(:di_milles)
    publisher  = advertiser.publisher
    offer      = advertiser.offers.create!(:message => "Free yogurt with your taco")

    publisher.reload
    publisher.update_attribute( :theme, 'simple' )
    assert_equal 'simple', advertiser.publisher.theme
    with_user_required(:aaron) do
      get :edit, :id => offer.to_param
    end
    assert_select "input[name='offer[label]']", 0
    assert_select "input[name='offer[message]']"
    assert_select "textarea[name='offer[txt_message]']"
    assert_select "textarea[name='offer[terms]']"
    assert_select "input[name='offer[show_on]']"
    assert_select "input[name='offer[expires_on]']"
    assert_select "input[name='offer[account_executive]']"
    assert_select "input[name='offer[offer_image]']"
    assert_select "input[name='offer[value_proposition]']", false
    assert_select "input[name='offer[value_proposition_detail]']", false
    assert_select "input[name='offer[headline]']", false
    assert_select "input[name='offer[category_names]']"
    assert_select "input[name='offer[coupon_code]']"
    assert_select "select[name='offer[featured]']", 1 do
      Offer::ALLOWED_FEATURED_VALUES.each { |k| assert_select "option[value=#{k}]", k.capitalize, 1 }
    end
    assert_select "input[name='offer[bit_ly_url]'][disabled=disabled]", 1
  end

  def test_edit_with_enhanced_publisher
    advertiser = advertisers(:di_milles)
    offer = advertiser.offers.create!(:message => "Free yogurt with your taco")
    assert_equal 'enhanced', advertiser.publisher.theme
    with_user_required(:aaron) do
      get :edit, :id => offer.to_param
    end
    assert_select "input[name='offer[label]']", 0
    assert_select "input[name='offer[photo]']"
    assert_select "input[name='offer[account_executive]']"
    assert_select "input[name='offer[offer_image]']"
    assert_select "input[name='offer[value_proposition]']"
    assert_select "input[name='offer[value_proposition_detail]']"
    assert_select "input[name='offer[headline]']", false
    assert_select "input[name='offer[coupon_code]']"
    assert_select "select[name='offer[featured]']", 1 do
      Offer::ALLOWED_FEATURED_VALUES.each { |k| assert_select "option[value=#{k}]", k.capitalize, 1 }
    end
    assert_select "input[name='offer[bit_ly_url]'][disabled=disabled]", 1
  end

  def test_edit_with_standard_publisher
    advertiser = advertisers(:di_milles)
    offer = advertiser.offers.create!(:message => "Free yogurt with your taco")
    advertiser.publisher.update_attribute( :theme, 'standard' )
    assert_equal 'standard', advertiser.publisher.theme
    with_user_required(:aaron) do
      get :edit, :id => offer.to_param
    end
    assert_select "input[name='offer[label]']", 0
    assert_select "input[name='offer[photo]']"
    assert_select "input[name='offer[offer_image]']"
    assert_select "input[name='offer[value_proposition]']"
    assert_select "input[name='offer[value_proposition_detail]']", false
    assert_select "input[name='offer[headline]']", false
    assert_select "input[name='offer[coupon_code]']"
    assert_select "select[name='offer[featured]']", 1 do
      Offer::ALLOWED_FEATURED_VALUES.each { |k| assert_select "option[value=#{k}]", k.capitalize, 1 }
    end
    assert_select "input[name='offer[bit_ly_url]'][disabled=disabled]", 1
  end

  def test_edit_with_withtheme_publisher
    advertiser = advertisers(:di_milles)
    offer = advertiser.offers.create!(:message => "Free yogurt with your taco")
    advertiser.publisher.update_attribute( :theme, 'withtheme' )
    assert_equal 'withtheme', advertiser.publisher.theme
    with_user_required(:aaron) do
      get :edit, :id => offer.to_param
    end
    assert_select "input[name='offer[label]']", 0
    assert_select "input[name='offer[photo]']"
    assert_select "input[name='offer[offer_image]']"
    assert_select "input[name='offer[value_proposition]']"
    assert_select "input[name='offer[value_proposition_detail]']", false
    assert_select "input[name='offer[headline]']", false
    assert_select "input[name='offer[coupon_code]']"
    assert_select "select[name='offer[featured]']", 1 do
      Offer::ALLOWED_FEATURED_VALUES.each { |k| assert_select "option[value=#{k}]", k.capitalize, 1 }
    end
    assert_select "input[name='offer[bit_ly_url]'][disabled=disabled]", 1
  end

  test "edit when publishing group and offer both have categories" do
    advertiser = Factory(:advertiser)
    advertiser.publisher.update_attribute(:self_serve, true)
    user = Factory(:user, :company => advertiser.publisher)
    offer = Factory(:offer, :advertiser => advertiser)
    publishing_group = advertiser.publisher.publishing_group

    offer.categories.each do |category|
      publishing_group.categories << category
    end

    login_as user

    get :edit, :id => offer.to_param
    assert_select "#category_ids_categories", true
    assert_select "#category_ids_list" do
      assert_select "li", offer.categories.count do
        assert_select "span", 1
        assert_select "input[name='offer[category_ids][]']", 1
        assert_select "a", 1
      end
    end
  end

  def test_edit_with_businessdirectory_publisher
    advertiser = advertisers(:di_milles)
    offer = advertiser.offers.create!(:message => "Free yogurt with your taco")
    advertiser.publisher.update_attribute( :theme, 'businessdirectory' )
    assert_equal 'businessdirectory', advertiser.publisher.theme
    with_user_required(:aaron) do
      get :edit, :id => offer.to_param
    end
    assert_select "input[name='offer[label]']", 0
    assert_select "input[name='offer[photo]']"
    assert_select "input[name='offer[offer_image]']"
    assert_select "input[name='offer[value_proposition]']"
    assert_select "input[name='offer[value_proposition_detail]']", false
    assert_select "input[name='offer[headline]']", false
    assert_select "input[name='offer[coupon_code]']"
    assert_select "select[name='offer[featured]']", 1 do
      Offer::ALLOWED_FEATURED_VALUES.each { |k| assert_select "option[value=#{k}]", k.capitalize, 1 }
    end
    assert_select "input[name='offer[bit_ly_url]'][disabled=disabled]", 1
  end

  def test_edit_with_sdcitybeat_publisher
    advertiser = advertisers(:di_milles)
    offer = advertiser.offers.create!(:message => "Free yogurt with your taco")
    advertiser.publisher.update_attribute( :theme, 'sdcitybeat' )
    assert_equal 'sdcitybeat', advertiser.publisher.theme
    with_user_required(:aaron) do
      get :edit, :id => offer.to_param
    end
    assert_select "input[name='offer[label]']", 0
    assert_select "input[name='offer[photo]']"
    assert_select "input[name='offer[offer_image]']"
    assert_select "input[name='offer[value_proposition]']"
    assert_select "input[name='offer[value_proposition_detail]']", false
    assert_select "input[name='offer[headline]']", false
    assert_select "input[name='offer[coupon_code]']"
    assert_select "select[name='offer[featured]']", 1 do
      Offer::ALLOWED_FEATURED_VALUES.each { |k| assert_select "option[value=#{k}]", k.capitalize, 1 }
    end
    assert_select "input[name='offer[bit_ly_url]'][disabled=disabled]", 1
  end

  def test_edit_with_standard_publisher_with_advertiser_listing
    advertiser = advertisers(:di_milles)
    offer = advertiser.offers.create!(:message => "Free yogurt with your taco")
    advertiser.publisher.update_attributes! :theme => 'standard', :advertiser_has_listing => true

    with_user_required(:aaron) do
      get :edit, :id => offer.to_param
    end
    assert_select "input[name='offer[label]']", 1
    assert_select "input[name='offer[photo]']"
    assert_select "input[name='offer[offer_image]']"
    assert_select "input[name='offer[value_proposition]']"
    assert_select "input[name='offer[value_proposition_detail]']", false
    assert_select "input[name='offer[headline]']", false
    assert_select "input[name='offer[coupon_code]']"
    assert_select "select[name='offer[featured]']", 1 do
      Offer::ALLOWED_FEATURED_VALUES.each { |k| assert_select "option[value=#{k}]", k.capitalize, 1 }
    end
    assert_select "input[name='offer[bit_ly_url]'][disabled=disabled]", 1
  end

  def test_edit_hide_coupon_code
    publishing_group = publishing_groups(:student_discount_handbook)
    publishing_group.update_attribute :coupon_codes, false
    advertiser = advertisers(:changos)
    offer = advertiser.offers.create!(:message => "Free yogurt with your taco")
    advertiser.publisher.update_attribute( :theme, 'standard' )
    assert_equal 'standard', advertiser.publisher.theme
    with_user_required(:aaron) do
      get :edit, :id => offer.to_param
    end
    assert_select "input[name='offer[label]']", 0
    assert_select "input[name='offer[photo]']"
    assert_select "input[name='offer[offer_image]']"
    assert_select "input[name='offer[value_proposition]']"
    assert_select "input[name='offer[value_proposition_detail]']", false
    assert_select "input[name='offer[headline]']", false
    assert_select "input[name='offer[coupon_code]']", false
    assert_select "select[name='offer[featured]']", 1 do
      Offer::ALLOWED_FEATURED_VALUES.each { |k| assert_select "option[value=#{k}]", k.capitalize, 1 }
    end
    assert_select "input[name='offer[bit_ly_url]'][disabled=disabled]", 1
  end

  def test_edit_with_publisher_with_enable_offer_title
    advertiser = advertisers(:di_milles)
    offer = advertiser.offers.create!(:message => "Free yogurt with your taco")
    advertiser.publisher.update_attributes! :theme => 'standard', :enable_offer_headline => true

    with_user_required(:aaron) do
      get :edit, :id => offer.to_param
    end
    assert_select "input[name='offer[photo]']"
    assert_select "input[name='offer[offer_image]']"
    assert_select "input[name='offer[value_proposition]']"
    assert_select "input[name='offer[value_proposition_detail]']", false
    assert_select "input[name='offer[headline]']"
    assert_select "input[name='offer[coupon_code]']"
  end
end
