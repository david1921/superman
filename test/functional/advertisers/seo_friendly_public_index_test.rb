require File.dirname(__FILE__) + "/../../test_helper"

class AdvertisersController::SeoFriendlyPublicIndexTest < ActionController::TestCase
  tests AdvertisersController

  def setup
    @publisher = publishers(:sdh_austin)
  end
  
  def test_seo_friendly_public_index_with_businessdirectory_theme_and_no_path
    Advertiser.destroy_all
    Offer.destroy_all
    publisher    = publishers(:houston_press)
    advertiser_1 = publisher.advertisers.create!( :name => "Advertiser 1", :listing => "Advertiser 1 listing" )
    advertiser_2 = publisher.advertisers.create!( :name => "Advertiser 2", :listing => "Advertiser 2 listing" )
    
    advertiser_1_offer_1 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 1", :category_names => "Restaurant : Thai" )
    advertiser_1_offer_2 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 2",  :category_names => "Cars : Customization" )
    
    advertiser_2_offer_1 = advertiser_2.offers.create!( :message => "Advertiser 2 Offer 1")
    
    get :seo_friendly_public_index, :publisher_label => publisher.label, :path => []
    
    assert_response :success
    assert_template :public_index
    assert_not_nil  assigns(:publisher)
    assert_not_nil  assigns(:advertisers)
    
    assert_equal 2, assigns(:advertisers).size, "only return advertisers with offers"
    
    assert_equal 1, advertiser_1_offer_1.impression_counts.size
    assert_equal 1, advertiser_1_offer_2.impression_counts.size
    assert_equal 1, advertiser_2_offer_1.impression_counts.size
    
    assert_select '#analog_analytics_content' do
      assert_select '#business_directory' do
        assert_select '.left_column'
        assert_select '.right_column' do
          assert_select '.businesses' do
            assert_select 'ol#directory' do
              assert_select 'li:nth-child(1)' do
                assert_select 'h3', :text => advertiser_1.name 
                assert_select 'ul.offers' do
                  assert_select 'li:nth-child(1)' do
                    assert_select '.top' do
                      assert_select 'a', :text => advertiser_1_offer_1.value_proposition
                    end
                    assert_select '.bottom', :text => advertiser_1_offer_1.terms
                  end
                  assert_select 'li:nth-child(2)' do
                    assert_select '.top' do
                      assert_select 'a', :text => advertiser_1_offer_2.value_proposition
                    end
                    assert_select '.bottom', :text => advertiser_1_offer_2.terms
                  end
                end
              end
              assert_select 'li:nth-child(2)' do
                assert_select 'h3', :text => advertiser_2.name
                assert_select 'ul.offers' do
                  assert_select 'li:nth-child(1)' do
                    assert_select '.top' do
                      assert_select 'a', :text => advertiser_2_offer_1.value_proposition                      
                    end
                    assert_select '.bottom', :text => advertiser_2_offer_1.terms
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def test_seo_friendly_public_index_with_businessdirectory_theme_and_map_and_no_path
    Advertiser.destroy_all
    Offer.destroy_all
    publisher    = publishers(:houston_press)
    advertiser_1 = publisher.advertisers.create!( :name => "Advertiser 1", :listing => "Advertiser 1 listing" )
    advertiser_1.stores.create!(:address_line_1 => "123 Sesame Street", :city => "Sheds", :state => "NY", :zip => "13035")
    advertiser_2 = publisher.advertisers.create!( :name => "Advertiser 2", :listing => "Advertiser 2 listing" )
    advertiser_2.stores.create!(:address_line_1 => "456 Sesame Street", :city => "Sheds", :state => "NY", :zip => "13035")
    
    advertiser_1_offer_1 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 1", :category_names => "Restaurant : Thai" )
    advertiser_1_offer_2 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 2",  :category_names => "Cars : Customization" )
    
    advertiser_2_offer_1 = advertiser_2.offers.create!( :message => "Advertiser 2 Offer 1")
    
    get :seo_friendly_public_index, :publisher_label => publisher.label, :path => [], :with_map => true
        
    assert_response :success
    assert_template :public_index
    assert_not_nil  assigns(:publisher)
    assert_not_nil  assigns(:advertisers)
    assert_not_nil  assigns(:map)
    
    assert_equal 2, assigns(:advertisers).size, "only return advertisers with offers"
    
    assert_equal 0, advertiser_1_offer_1.impression_counts.size
    assert_equal 0, advertiser_1_offer_2.impression_counts.size
    assert_equal 0, advertiser_2_offer_1.impression_counts.size
        
    assert_select '#analog_analytics_content' do
      assert_select '#business_directory' do
        assert_select '.left_column'
        assert_select '.right_column' do
          assert_select '.businesses' do
            assert_select 'ol#directory' do
              assert_select 'li:nth-child(1)', false, "there should be no child li elements to begin with"             
            end
          end
        end
      end
    end
    
  end

  def test_seo_friendly_public_index_with_businessdirectory_theme_and_map_and_no_path
   
    Advertiser.destroy_all
    Offer.destroy_all
    publisher    = publishers(:houston_press)
    advertiser_1 = publisher.advertisers.create!( :name => "Advertiser 1", :listing => "Advertiser 1 listing" )
    advertiser_1.stores.create!(:address_line_1 => "123 Sesame Street", :city => "Sheds", :state => "NY", :zip => "13035")
    advertiser_2 = publisher.advertisers.create!( :name => "Advertiser 2", :listing => "Advertiser 2 listing" )
    advertiser_2.stores.create!(:address_line_1 => "456 Sesame Street", :city => "Sheds", :state => "NY", :zip => "13035")
    
    advertiser_1_offer_1 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 1", :category_names => "Restaurant : Thai" )
    advertiser_1_offer_2 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 2",  :category_names => "Cars : Customization" )
    
    advertiser_2_offer_1 = advertiser_2.offers.create!( :message => "Advertiser 2 Offer 1")
    
    get :seo_friendly_public_index, :publisher_label => publisher.label, :path => [], :with_map => true
        
    assert_response :success
    assert_template :map_index
    assert_not_nil  assigns(:publisher)
    assert_not_nil  assigns(:advertisers)
    assert_not_nil  assigns(:map)
    
    assert_equal 2, assigns(:advertisers).size, "only return advertisers with offers"
    
    assert_equal 0, advertiser_1_offer_1.impression_counts.size
    assert_equal 0, advertiser_1_offer_2.impression_counts.size
    assert_equal 0, advertiser_2_offer_1.impression_counts.size   
  end
  
  def test_seo_friendly_public_index_with_businessdirectory_theme_and_path_of_cars
    Advertiser.destroy_all
    Offer.destroy_all
    publisher    = publishers(:houston_press)
    publisher.update_attribute(:production_host, "coupons.houstonpress.com") 
    assert_equal "coupons.houstonpress.com", publisher.production_host
    
    advertiser_1 = publisher.advertisers.create!( :name => "Advertiser 1", :listing => "Advertiser 1 listing" )
    advertiser_2 = publisher.advertisers.create!( :name => "Advertiser 2", :listing => "Advertiser 2 listing" )
    
    advertiser_1_offer_1 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 1", :category_names => "Restaurant : Thai" )
    advertiser_1_offer_2 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 2",  :category_names => "Cars : Customization" )
    
    advertiser_2_offer_1 = advertiser_2.offers.create!( :message => "Advertiser 2 Offer 1")
    
    get :seo_friendly_public_index, :publisher_label => publisher.label, :path => ["cars"]
    
    assert_response :success
    assert_template :public_index
    assert_not_nil  assigns(:publisher)
    assert_not_nil  assigns(:advertisers)
    
    assert_equal 1, assigns(:advertisers).size, "only return advertisers with offers"
    
    assert_equal 1, advertiser_1_offer_1.impression_counts.size, "since advertiser 1 has offers in cars"
    assert_equal 1, advertiser_1_offer_2.impression_counts.size, "since advertiser 1 has offers in cars"
    assert_equal 0, advertiser_2_offer_1.impression_counts.size, "advertisers 2 has no offers in cars"

    assert_select '#analog_analytics_content' do
      assert_select '#business_directory' do
        assert_select '.left_column'
        assert_select '.right_column' do 
          assert_select '.navigation' do
            assert_select '.bottom' do
              assert_select "a[href='http://coupons.houstonpress.com/houston/deals/cars/']"
            end
          end
          assert_select '.businesses' do
            assert_select 'ol#directory' do
              assert_select 'li:nth-child(1)' do
                assert_select 'h3', :text => advertiser_1.name 
                assert_select 'ul.offers' do
                  assert_select 'li:nth-child(1)' do
                    assert_select '.top' do
                      assert_select 'a', :text => advertiser_1_offer_1.value_proposition
                    end
                    assert_select '.bottom', :text => advertiser_1_offer_1.terms
                  end
                  assert_select 'li:nth-child(2)' do
                    assert_select '.top' do
                      assert_select 'a', :text => advertiser_1_offer_2.value_proposition
                    end
                    assert_select '.bottom', :text => advertiser_1_offer_2.terms
                  end
                end
              end
            end
          end
        end
      end
    end
    
  end

  def test_seo_friendly_public_index_with_businessdirectory_theme_and_path_of_cars_with_map
    Advertiser.destroy_all
    Offer.destroy_all     
    publisher    = publishers(:houston_press)
    publisher.update_attribute(:production_host, "coupons.houstonpress.com")
    
    advertiser_1 = publisher.advertisers.create!( :name => "Advertiser 1", :listing => "Advertiser 1 listing" )
    store_1      = advertiser_1.stores.build(:longitude => -95.5327, :latitude => 29.7052)
    store_1.save false #skip validation
    
    advertiser_2 = publisher.advertisers.create!( :name => "Advertiser 2", :listing => "Advertiser 2 listing" )
    store_2      = advertiser_2.stores.build(:longitude => -95.5327, :latitude => 29.7052)
    store_2.save false #skip validation
    
    advertiser_1_offer_1 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 1", :category_names => "Restaurant : Thai" )
    advertiser_1_offer_2 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 2",  :category_names => "Cars : Customization" )
    
    advertiser_2_offer_1 = advertiser_2.offers.create!( :message => "Advertiser 2 Offer 1")
    
    get :seo_friendly_public_index, :publisher_label => publisher.label, :path => ["cars"], :with_map => true
    
    assert_response :success
    assert_template :map_index
    assert_not_nil  assigns(:publisher)
    assert_not_nil  assigns(:advertisers)
    
    assert_equal 1, assigns(:advertisers).size, "should return businesses"
    
    assert_equal 0, advertiser_1_offer_1.impression_counts.size, "should not record impressions yet"
    assert_equal 0, advertiser_1_offer_2.impression_counts.size, "should not record impressions yet"
    assert_equal 0, advertiser_2_offer_1.impression_counts.size, "should not record impressions yet"
    
  end

  def test_seo_friendly_public_index_with_advertiser_id_and_xhr_request
    Advertiser.destroy_all
    Offer.destroy_all
    @publisher.update_attribute(:theme, 'businessdirectory')
    advertiser_1 = @publisher.advertisers.create!( :name => "Advertiser 1" )

    advertiser_1_offer_1 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 1", :category_names => "Restaurant : Thai" )      
    
    xhr :post, :seo_friendly_public_index, :publisher_label => @publisher.label, :advertiser_id => advertiser_1.id, :format => "js"
    
    assert_response :success
    assert_template :partial => "advertisers/businessdirectory/_business"
    
  end
  
end