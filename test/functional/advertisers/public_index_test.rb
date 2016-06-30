require File.dirname(__FILE__) + "/../../test_helper"

class AdvertisersController::PublicIndexTest < ActionController::TestCase
  tests AdvertisersController

  def setup
    @publisher = publishers(:sdh_austin)
  end
  
  def test_sdcitybeat_public_index_with_advertisers_with_no_offers
    Advertiser.destroy_all
    Offer.destroy_all 
    @publisher.update_attribute(:theme, 'sdcitybeat')
    advertiser_1 = @publisher.advertisers.create!( :name => "Advertiser 1" )
    advertiser_2 = @publisher.advertisers.create!( :name => "Advertiser 2" )
    
    get :public_index, :publisher_id => @publisher.id
    
    assert_response :success
    assert_template :public_index
    assert_not_nil  assigns(:publisher)
    assert_not_nil  assigns(:advertisers)
    
    assert_equal 0, assigns(:advertisers).size, "only return advertisers with offers"  
    assert_select '#analog_analytics_content' do
      assert_select '#business_directory' do
        assert_select '.left_column'
        assert_select '.right_column' do
          assert_select '.businesses', :text => "Sorry, no businesses found."
        end
      end
    end
  end  
  
  def test_sdcitybeat_public_index_with_advertisers_with_offers_but_no_search_params   
    Advertiser.destroy_all
    Offer.destroy_all
    @publisher.update_attribute(:theme, 'sdcitybeat')
    advertiser_1 = @publisher.advertisers.create!( :name => "Advertiser 1" )
    advertiser_2 = @publisher.advertisers.create!( :name => "Advertiser 2" )
    
    advertiser_1_offer_1 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 1" )
    advertiser_1_offer_2 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 2" )
    
    advertiser_2_offer_1 = advertiser_2.offers.create!( :message => "Advertiser 2 Offer 1")
    
    get :public_index, :publisher_id => @publisher.id
    
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
  
  def test_sdcitybeat_public_index_with_advertisers_with_offers_with_advertiser_id
    Advertiser.destroy_all
    Offer.destroy_all
    @publisher.update_attribute(:theme, 'sdcitybeat')
    advertiser_1 = @publisher.advertisers.create!( :name => "Advertiser 1" )
    advertiser_2 = @publisher.advertisers.create!( :name => "Advertiser 2" )
    
    advertiser_1_offer_1 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 1" )
    advertiser_1_offer_2 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 2" )
    
    advertiser_2_offer_1 = advertiser_2.offers.create!( :message => "Advertiser 2 Offer 1")
    
    get :public_index, :publisher_id => @publisher.id, :advertiser_id => advertiser_1.id
    
    assert_response :success
    assert_template :public_index
    assert_not_nil  assigns(:publisher)
    assert_not_nil  assigns(:advertisers)
    
    assert_equal 1, assigns(:advertisers).size, "only return advertiser base on advertiser id"
    
    assert_equal 1, advertiser_1_offer_1.impression_counts.size
    assert_equal 1, advertiser_1_offer_2.impression_counts.size
    assert_equal 0, advertiser_2_offer_1.impression_counts.size
    
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
            end
          end
        end
      end
    end
    
  end  
  
  def test_public_index_with_layout_of_iframe
    Advertiser.destroy_all
    Offer.destroy_all
    @publisher.update_attribute(:theme, 'sdcitybeat')
    advertiser_1 = @publisher.advertisers.create!( :name => "Advertiser 1" )
    advertiser_2 = @publisher.advertisers.create!( :name => "Advertiser 2" )
    
    advertiser_1_offer_1 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 1" )
    advertiser_1_offer_2 = advertiser_1.offers.create!( :message => "Advertiser 1 Offer 2" )
    
    advertiser_2_offer_1 = advertiser_2.offers.create!( :message => "Advertiser 2 Offer 1")
    
    get :public_index, :publisher_id => @publisher.id, :advertiser_id => advertiser_1.id, :layout => 'iframe'
    
    assert_response :success
    assert_template :public_index
    assert_layout "advertisers/public_index"    
  end
    
  test "TWC using withtheme for public_index with param of with_map set to true" do
    @publishing_group = Factory(:publishing_group, :label => 'rr')
    @publisher        = Factory(:publisher, :label => "clickedin-austin", :publishing_group => @publishing_group, :theme => "withtheme")
    get :public_index, :publisher_id => @publisher.to_param, :with_map => true
    
    assert_response :success
    assert_theme_layout "rr/layouts/advertisers/public_index"    
    assert_template "themes/rr/advertisers/map_index"
  end
  
  test "public index json request with no page parameter" do
    publisher = Factory(:publisher)
    (1..20).each do |number|
      advertiser = Factory(:advertiser, :name => "Advertiser #{number}", :publisher => publisher)
      store      = Factory(:store, :advertiser => advertiser, :latitude => 37.0625, :longitude => -95.67706)
      offer      = Factory(:offer, :value_proposition => "Offer #{number}", :advertiser => advertiser)
    end
    publisher.reload
    
    Publisher.any_instance.stubs(:advertisers_with_web_offers).returns(publisher.advertisers)
    
    get :public_index, :publisher_id => @publisher.to_param, :with_map => true, :format => "json"
    assert_response :success
    json = JSON.parse(@response.body)
    
    assert_equal 20,  json["mappable_advertisers"].size
    assert_equal 10,  json["advertisers"].size
    assert_equal 1,   json["page"]
    assert_equal 10,  json["page_size"]
    assert_equal 20,  json["total_count"]
  end
  
  test "public index json request with a page parameter" do
    publisher = Factory(:publisher)
    (1..20).each do |number|
      advertiser = Factory(:advertiser, :name => "Advertiser #{number}", :publisher => publisher)
      store      = Factory(:store, :advertiser => advertiser, :latitude => 37.0625, :longitude => -95.67706)
      offer      = Factory(:offer, :value_proposition => "Offer #{number}", :advertiser => advertiser)
    end
    publisher.reload
    
    Publisher.any_instance.stubs(:advertisers_with_web_offers).returns(publisher.advertisers)
    
    get :public_index, :publisher_id => @publisher.to_param, :with_map => true, :format => "json", :page => "2"
    assert_response :success
    json = JSON.parse(@response.body)
    
    assert_nil json["mappable_advertisers"], "should not return mappable advertiers"
    assert_equal 10,  json["advertisers"].size
    assert_equal 2,   json["page"]
    assert_equal 10,  json["page_size"]
    assert_equal 20,  json["total_count"]
  end
  
end