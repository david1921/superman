require File.dirname(__FILE__) + "/../../test_helper"

class PublishersController::ShowTest < ActionController::TestCase
  tests PublishersController
  
  def test_show_without_custom_layout
    Factory(:publisher, :name => "New Times", :label => "new", :theme => "standard")
    get :show, :label => "new"
    assert_response :success
    assert_layout "offers/public_index"
  end
  
  def test_show_with_subcategory
    food = Category.create!(:name => "Food")
    food.children.create!(:name => "Restaurant")
    cafe = food.subcategories.create!(:name => "Cafe")
    
    publisher = publishers(:tucsonweekly)
    offer = publisher.advertisers.create!(:name => "adv").offers.create!(:message => "Offer 2", :category_names => "Food: Cafe")    
    
    get :show, :label => "tucsonweekly", :category_id => cafe.to_param
    assert_response :success
    assert_equal [ food ].sort_by(&:name), assigns(:publisher_categories).sort_by(&:name), "@publisher_categories"
    assert assigns(:publisher_categories)
    assert assigns(:publisher)
    assert assigns(:categories)
    assert assigns(:page_size)
  end
  
  def test_show_with_bad_label_should_return_404
    assert_raises ActiveRecord::RecordNotFound do
      get :show, :label => "oregonian"
    end
  end
  
  def test_show_with_bad_id_should_return_404
    assert_raises ActiveRecord::RecordNotFound do
      get :show, :id => "1236127836128"
    end
  end
  
  def test_show_with_id_should_return_404
    assert_raises ActiveRecord::RecordNotFound do
      get :show, :id => publishers(:sdreader).to_param
    end
  end
  
  def test_show_with_bad_label_should_return_404_with_null_label_in_db
    null_label_publisher = Factory(:publisher, :name => "Publisher", :label => nil)
    assert_raises ActiveRecord::RecordNotFound do
      get :show, :label => "oregonian"
    end
  end
  
  def test_show_with_bad_id_should_return_404_with_null_label_in_db
    null_label_publisher = Factory(:publisher, :name => "Publisher", :label => nil)
    assert_raises ActiveRecord::RecordNotFound do
      get :show, :id => "1236127836128"
    end
  end
  
  def test_show_with_id_should_return_404_with_null_label_in_db
    null_label_publisher = Factory(:publisher, :name => "Publisher", :label => nil)
    assert_raises ActiveRecord::RecordNotFound do
      get :show, :id => publishers(:sdreader).to_param
    end
  end
  
  def test_show_with_id_should_return_404_with_bad_market_label
    publisher = Factory(:publisher)
    market = Factory(:market, :publisher => publisher)
    assert_raises ActiveRecord::RecordNotFound do
      get :show, :id => publisher.to_param, :market => "abc"
    end
  end
  
  def test_show_with_label_should_return_404_with_bad_market_label
    publisher = Factory(:publisher)
    market = Factory(:market, :publisher => publisher)
    assert_raises ActiveRecord::RecordNotFound do
      get :show, :label => publisher.to_param, :market => "abc"
    end
  end
  
end
