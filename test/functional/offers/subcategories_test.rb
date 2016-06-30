require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::SubcategoriesTest < ActionController::TestCase
  tests OffersController

  test "subcategory_options based on user" do
    advertiser = Factory(:advertiser)
    advertiser.publisher.update_attribute(:self_serve, true)
    publishing_group = advertiser.publisher.publishing_group
    user = Factory(:user, :company => advertiser.publisher)

    category = Factory(:category)
    subcategory1 = Factory(:category, :parent => category, :name => "Foo")
    subcategory2 = Factory(:category, :parent => category, :name => "Bar")
    subcategory3 = Factory(:category, :parent => category, :name => "Baz")

    publishing_group.categories << category
    publishing_group.categories << subcategory1
    publishing_group.categories << subcategory2

    login_as user

    get :subcategory_options, :advertiser_id => advertiser.to_param,
      :category_id => category.to_param

    assert_select "option[value='#{subcategory1.id}']", "Foo"
    assert_select "option[value='#{subcategory2.id}']", "Bar"
    assert_select "option[value='#{subcategory3.id}']", false
  end

  def test_subcategories
    offer = offers(:my_space_burger_king_free_fries)
    offer.category_names = "Restaurants: Italian"
    offer.save!

    xhr :post, :subcategories,
        :disclosed => "false",
        :publisher_id => publishers(:my_space).to_param,
        :category_id => categories(:restaurants).to_param
    assert_response(:success)
    assert_equal categories(:restaurants), assigns(:category), "@category"
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert_equal false, assigns(:disclosed), "@disclosed"
    assert_equal_arrays([ "Italian" ], assigns(:subcategories).map(&:name), "@subcategories")
  end

  def test_subcategories_disclosed
    offer = offers(:my_space_burger_king_free_fries)
    offer.category_names = "Restaurants: Italian"
    offer.save!

    xhr :post, :subcategories,
        :disclosed => "true",
        :publisher_id => publishers(:my_space).to_param,
        :category_id => categories(:restaurants).to_param
    assert_response(:success)
    assert_equal categories(:restaurants), assigns(:category), "@category"
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert_equal true, assigns(:disclosed), "@disclosed"
    assert_nil assigns(:subcategories), "@subcategories"
  end

  def test_subcategories_with_scope
    offer = offers(:my_space_burger_king_free_fries)
    offer.advertiser.stores.create(:address_line_1 => "1 Main St", :city => "San Diego", :state => "CA", :zip => "92106").save!
    offer.category_names = "Restaurants: Italian"
    offer.save!

    advertiser_2 = publishers(:my_space).advertisers.create!(:name => "Advertiser 2")
    advertiser_2.stores.create(:address_line_1 => "2 Main St", :city => "San Diego", :state => "CA", :zip => "92040").save!
    advertiser_2.offers.create!(
      :message => "Offer 2",
      :category_names => "Restaurants: Albanian"
    )

    advertiser_3 = publishers(:my_space).advertisers.create!
    advertiser_3.stores.create(:address_line_1 => "3 Main St", :city => "San Diego", :state => "CA", :zip => "92118").save!
    advertiser_3.offers.create!(
      :message => "Offer 2",
      :category_names => "Restaurants: Mexican"
    )

    xhr :post, :subcategories,
        :disclosed => "false",
        :publisher_id => publishers(:my_space).to_param,
        :category_id => categories(:restaurants).to_param,
        :postal_code => "92101",
        :radius => "20"
    assert_response(:success)
    assert_equal categories(:restaurants), assigns(:category), "@category"
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert_equal_arrays([ "Albanian", "Italian" ], assigns(:subcategories).map(&:name).sort, "@subcategories")
  end
  
  context "with_theme publisher" do
    
    setup do
      @publisher = Factory(:publisher, :theme => "withtheme")
      @category  = nil
      
      (1..3).each do |index|
        advertiser = Factory(:advertiser, :publisher => @publisher)
        offer      = Factory(:offer, :advertiser => advertiser, :message => "Offer :#{index}", :category_names => "Automobile")
        @category ||= offer.categories.first
      end      
          
      
    end
    
    context "with default theme" do
      
      setup do
        xhr :post, :subcategories,
          :disclosed => "false",
          :publisher_id => @publisher.to_param,
          :category_id => @category.to_param          
      end
      
      should respond_with( :success )
      should render_template( "offers/subcategories.js.rjs" )
      
    end
    
    context "with radarfrog specific theme" do
      
      setup do
        @publisher.reload.update_attribute(:label, "radarfrog")
        xhr :post, :subcategories,
          :disclosed => "false",
          :publisher_id => @publisher.to_param,
          :category_id => @category.to_param        
      end
      
      should respond_with( :success )
      should render_template( "themes/radarfrog/offers/subcategories.js.rjs" )
      
      
    end
    
    
    
    
  end

end
