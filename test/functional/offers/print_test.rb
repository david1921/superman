require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::PrintTest < ActionController::TestCase
  tests OffersController

  def test_print_for_timewarnercable_publishers
    publishing_group = Factory(:publishing_group, :label => "rr")
    ["clickedin-austin", "clickedin-dallas", "clickedin-sanantonio"].each do |label|
      publisher   = Factory(:publisher, :label => label, :name => label, :theme => "withtheme", :publishing_group => publishing_group)
      advertiser  = Factory(:advertiser, :publisher => publisher )
      offer       = Factory(:offer, :value_proposition => "This is the value proposition", :advertiser_id => advertiser.id )

      get :print, :id => offer.to_param, :publisher_id => publisher.to_param
      assert_response :success
      assert assigns(:offer)
      assert_layout nil
      assert_template "themes/rr/offers/print"
      assert_select "head" do
        assert_select "meta[name='robots'][content='noarchive']"
        assert_select "meta[name='googlebot'][content='noarchive']"
      end
    end

  end

  def test_print_with_simple_coupon_layout
    publisher = Factory(:publisher, :name => "Simple Layout", :theme => "simple", :label => "simplelayoutpub" )
    offer = publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco", :expires_on => 1.month.from_now )
    get :print, :id => offer.to_param, :publisher_id => offer.publisher.to_param
    assert_response :success
    assert_not_nil assigns(:offer), "assigns @offer"
    assert_layout nil
    assert_template "offers/print"
    assert_select "head" do
      assert_select "meta[name='robots'][content='noarchive']"
      assert_select "meta[name='googlebot'][content='noarchive']"
    end
    assert_select "span#expires-on"
  end

  def test_print_with_narrow_coupon_layout
    publisher = Factory(:publisher, :name => "Narrow Layout", :theme => "narrow", :label => "narrowlayoutpub" )
    offer = publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco" )
    get :print, :id => offer.to_param, :publisher_id => offer.publisher.to_param
    assert_response :success
    assert_not_nil assigns(:offer), "assigns @offer"
    assert_layout nil
    assert_template "offers/print"
    assert_select "head" do
      assert_select "meta[name='robots'][content='noarchive']"
      assert_select "meta[name='googlebot'][content='noarchive']"
    end
  end

  def test_print_with_enhanced_coupon_layout
    publisher = Factory(:publisher, :name => "Enhanced Layout", :theme => "enhanced", :label => "enhancedlayoutpub" )
    offer = publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco" )
    get :print, :id => offer.to_param, :publisher_id => offer.publisher.to_param
    assert_response :success
    assert_not_nil assigns(:offer), "assigns @offer"
    assert_layout nil
    assert_template "offers/print"
    assert_select "head" do
      assert_select "meta[name='robots'][content='noarchive']"
      assert_select "meta[name='googlebot'][content='noarchive']"
    end
  end

  def test_print_with_arizonastateuniversitymetropolitanphoenix_label
    publisher = Factory(:publisher, :name => "New", :theme => "standard", :label => "arizonastateuniversitymetropolitanphoenix")
    offer = publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco" )
    get :print, :id => offer.to_param, :publisher_id => offer.publisher.to_param
    assert_response :success
    assert_not_nil assigns(:offer), "assigns @offer"
    assert_layout nil
    assert_template "offers/arizonastateuniversitymetropolitanphoenix/print"
    assert_select "head" do
      assert_select "meta[name='robots'][content='noarchive']"
      assert_select "meta[name='googlebot'][content='noarchive']"
    end
  end

  def test_print_with_universityofarizonatucson_label
    publisher = Factory(:publisher, :name => "New", :theme => "standard", :label => "universityofarizonatucson")
    offer = publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco" )
    get :print, :id => offer.to_param, :publisher_id => offer.publisher.to_param
    assert_response :success
    assert_not_nil assigns(:offer), "assigns @offer"
    assert_layout nil
    assert_template "offers/universityofarizonatucson/print"
    assert_select "head" do
      assert_select "meta[name='robots'][content='noarchive']"
      assert_select "meta[name='googlebot'][content='noarchive']"
    end
  end

  def test_print_with_mcclatchy_publisher_should_not_show_expires_on
    publishing_group = Factory :publishing_group, :label => "mcclatchy"
    publisher = Factory :publisher, :label => "sacbee", :publishing_group => publishing_group
    advertiser = Factory :advertiser, :publisher => publisher
    offer = Factory :offer, :advertiser => advertiser, :message => "Free yogurt with your taco"

    get :print, :id => offer.to_param, :publisher_id => offer.publisher.to_param
    assert_response :success
    assert_select "span#expires-on", :count => 0
  end

  def test_print_as_owning_publisher
    Lead.destroy_all
    expires_on = 2.days.from_now

    @request.remote_addr = "196.255.151.209"
    offer = offers(:my_space_burger_king_free_fries)
    offer.update_attribute(:expires_on, expires_on)
    offer.reload # so, we set a date and not time (otherwise the assert test gets thrown off)

    get(:print, :id => offer.to_param, :publisher_id => offer.publisher.to_param)
    assert_response(:success)
    assert_nil(session[:user_id], "Should not automatically login user")
    assert_not_nil(assigns(:offer), "assigns @offer")
    assert_layout(nil)

    assert_equal 1, Lead.count, "Should create one lead"
    lead = Lead.first
    assert_equal publishers(:my_space), lead.publisher, "Should set publisher on new lead"
    assert_equal offers(:my_space_burger_king_free_fries), lead.offer, "Should set offer on new lead"
    assert lead.print_me, "Should set the print-me flag on the new lead"
    assert_equal "196.255.151.209", lead.remote_ip, "Should set remote_ip from REMOTE_ADDR header"

    assert_select "div.body" do
      assert_select "div.headline", offer.publisher.coupon_headline
      assert_select "h3", offer.message.upcase
      assert_select "p.terms", "#{offer.terms} Expires #{offer.expires_on.to_s(:compact)}."
      assert_select "p.advertiser_name", offer.advertiser_name.upcase
    end
    assert_select "form#print"
    assert_select "input[type='button'][value='Print']"
  end

  def test_print_as_non_owning_publisher
    Lead.destroy_all
    expires_on = 2.days.from_now

    @request.remote_addr = "196.255.151.209"
    offer = offers(:my_space_burger_king_free_fries)
    offer.update_attribute(:expires_on, expires_on)
    offer.reload # so, we set a date and not time (otherwise the assert test gets thrown off)

    publisher = publishers(:sdh_austin)
    assert_not_equal publisher, offer.publisher, "Publisher should not own offer"

    get(:print, :id => offer.to_param, :publisher_id => publisher.to_param)
    assert_response(:success)
    assert_nil(session[:user_id], "Should not automatically login user")
    assert_not_nil(assigns(:offer), "assigns @offer")
    assert_layout(nil)

    assert_equal 1, Lead.count, "Should create one lead"
    lead = Lead.first
    assert_equal publisher, lead.publisher, "Should set publisher on new lead"
    assert_equal offers(:my_space_burger_king_free_fries), lead.offer, "Should set offer on new lead"
    assert lead.print_me, "Should set the print-me flag on the new lead"
    assert_equal "196.255.151.209", lead.remote_ip, "Should set remote_ip from REMOTE_ADDR header"

    assert_select "div.body" do
      assert_select "div.headline", publisher.coupon_headline
      assert_select "h3", offer.message.upcase
      assert_select "p.terms", "#{offer.terms} Expires #{offer.expires_on.to_s(:compact)}."
      assert_select "p.advertiser_name", offer.advertiser_name.upcase
    end
    assert_select "form#print"
    assert_select "input[type='button'][value='Print']"
  end
end
