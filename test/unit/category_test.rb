require File.dirname(__FILE__) + "/../test_helper"

class CategoryTest < ActiveSupport::TestCase
  def test_create
    Category.create!(:name => "Pharmaceuticals")
  end
  
  def test_all_with_offers_count_for_publisher
    categories = returning([]) do |array|
      4.times { |i| array << Category.create!(:name => "Category #{i}") }
    end

    publishers = returning([]) do |array|
      3.times { |i| array << Factory(:publisher, :name => "Publisher #{i}") }
    end
    
    advertiser_0 = publishers[1].advertisers.create!
    advertiser_0.offers.create! :message => "Advertiser 0",  :categories => [categories[1]]
    advertiser_0.offers.create! :message => "Advertiser 0 deleted",  :categories => [ categories[0], categories[3] ], :deleted_at => Time.now
                                                         
    advertiser_1 = publishers[1].advertisers.create!     
    advertiser_1.offers.create! :message => "Advertiser 1",  :categories => [categories[1]]
                                                         
    advertiser_2 = publishers[2].advertisers.create!     
    advertiser_2.offers.create! :message => "Advertiser 2",  :categories => [categories[1], categories[2]]
                                                         
    advertiser_3 = publishers[2].advertisers.create!     
    advertiser_3.offers.create! :message => "Advertiser 3",  :categories => [categories[2], categories[3]]
                                                         
    advertiser_5 = publishers[2].advertisers.create!     
    advertiser_5.offers.create! :message => "Advertiser 5",  :categories => [categories[1]]
    advertiser_5.offers.create! :message => "Advertiser 5", :categories => [categories[2]]

    cats = Category.all_with_offers_count_for_publisher(:publisher => publishers[0])
    assert_equal 0, cats.size
    
    cats = Category.all_with_offers_count_for_publisher(:publisher => publishers[1])
    assert_equal 1, cats.size
    assert_not_nil (category = cats.detect { |cat| "Category 1" == cat.name })
    assert_equal 2, category.offers_count
    
    cats = Category.all_with_offers_count_for_publisher(:publisher => publishers[2])
    assert_equal 3, cats.size
    assert_not_nil (category = cats.detect { |cat| "Category 1" == cat.name })
    assert_equal 2, category.offers_count
    assert_not_nil (category = cats.detect { |cat| "Category 2" == cat.name })
    assert_equal 3, category.offers_count
    assert_not_nil (category = cats.detect { |cat| "Category 3" == cat.name })
    assert_equal 1, category.offers_count
  end
  
  def test_all_with_offers_count_for_publisher_with_expired_offer
    categories = returning([]) do |array|
      4.times { |i| array << Category.create!(:name => "Category #{i}") }
    end

    publishers = returning([]) do |array|
      3.times { |i| array << Factory(:publisher, :name => "Publisher #{i}") }
    end
    
    advertiser_0 = publishers[1].advertisers.create!
    advertiser_0.offers.create! :message => "Advertiser 0",  :categories => [categories[1]]
    advertiser_0.offers.create! :message => "Advertiser 0 deleted",  :categories => [ categories[0], categories[3] ], :deleted_at => Time.now
                                                         
    advertiser_1 = publishers[1].advertisers.create!     
    advertiser_1.offers.create! :message => "Advertiser 1",  :categories => [categories[1]]
                                                         
    advertiser_2 = publishers[2].advertisers.create!     
    advertiser_2.offers.create! :message => "Advertiser 2",  :categories => [categories[1], categories[2]]
                                                         
    advertiser_3 = publishers[2].advertisers.create!     
    advertiser_3.offers.create! :message => "Advertiser 3",  :categories => [categories[2], categories[3]]
                                                         
    advertiser_5 = publishers[2].advertisers.create!     
    advertiser_5.offers.create! :message => "Advertiser 5",  :categories => [categories[1]], :expires_on => 2.days.ago
    advertiser_5.offers.create! :message => "Advertiser 5", :categories => [categories[2]]

    cats = Category.all_with_offers_count_for_publisher(:publisher => publishers[0])
    assert_equal 0, cats.size
    
    cats = Category.all_with_offers_count_for_publisher(:publisher => publishers[1])
    assert_equal 1, cats.size
    assert_not_nil (category = cats.detect { |cat| "Category 1" == cat.name })
    assert_equal 2, category.offers_count
    
    cats = Category.all_with_offers_count_for_publisher(:publisher => publishers[2])
    assert_equal 3, cats.size
    assert_not_nil (category = cats.detect { |cat| "Category 1" == cat.name })
    assert_equal 1, category.offers_count
    assert_not_nil (category = cats.detect { |cat| "Category 2" == cat.name })
    assert_equal 3, category.offers_count
    assert_not_nil (category = cats.detect { |cat| "Category 3" == cat.name })
    assert_equal 1, category.offers_count
  end
  
  def test_all_with_offers_count_for_publisher_with_zip_and_radius
    categories = returning([]) do |array|
      4.times { |i| array << Category.create!(:name => "Category #{i}") }
    end
    categories[1].subcategories.create!(:name => "Subcategory 1")
    categories[2].subcategories.create!(:name => "Subcategory 2")

    publishers = returning([]) do |array|
      3.times { |i| array << Factory(:publisher, :name => "Publisher #{i}") }
    end
    
    advertiser_0 = publishers[1].advertisers.create!
    advertiser_0.stores.create(:address_line_1 => "0 Main St", :city => "San Diego", :state => "CA", :zip => "92101").save!
    advertiser_0.offers.create! :message => "Advertiser 0 Offer 0",  :categories => [categories[1]]
                                                         
    advertiser_1 = publishers[1].advertisers.create!     
    advertiser_1.stores.create(:address_line_1 => "1 Main St", :city => "San Diego", :state => "CA", :zip => "92106-1234").save!
    advertiser_1.offers.create! :message => "Advertiser 1 Offer 0",  :categories => [categories[1], categories[3]]
                                                         
    advertiser_2 = publishers[2].advertisers.create!     
    advertiser_2.stores.create(:address_line_1 => "2 Main St", :city => "San Diego", :state => "CA", :zip => "92101-1234").save!
    advertiser_2.offers.create! :message => "Advertiser 2 Offer 0",  :categories => [categories[1], categories[2]]
                                                         
    advertiser_3 = publishers[2].advertisers.create!     
    advertiser_3.stores.create(:address_line_1 => "3 Main St", :city => "Cazenovia", :state => "NY", :zip => "13035").save!
    advertiser_3.offers.create! :message => "Advertiser 3 Offer 0",  :categories => [categories[2], categories[3]]
                                                         
    advertiser_4 = publishers[2].advertisers.create!     
    advertiser_4.stores.create(:address_line_1 => "4 Main St", :city => "Lakeside", :state => "CA", :zip => "92040").save!
    advertiser_4.offers.create! :message => "Advertiser 4 Offer 0",  :categories => [categories[1], categories[3]]
    advertiser_4.offers.create! :message => "Advertiser 4 Offer 1", :categories => [categories[2]]

    assert_categories_with_counts = lambda do |publisher, zip, radius, cats_with_count|
      want_cats = cats_with_count.keys.sort_by(&:id)
      search_request = SearchRequest.create(:publisher => publisher, :postal_code => zip, :radius => radius)
      have_cats = Category.all_with_offers_count_for_publisher(search_request).sort_by(&:id)
      assert_equal want_cats, have_cats, "Categories for #{publisher.name}, #{radius} mi of #{zip}"
      have_cats.each do |category|
        assert_equal cats_with_count[category], category.offers_count, "Offer count for #{category.name}"
      end
    end
    assert_categories_with_counts.call publishers[0], "92101",  0, {}
    assert_categories_with_counts.call publishers[0], "92101",  5, {}
    assert_categories_with_counts.call publishers[0], "92101", 20, {}
    
    assert_categories_with_counts.call publishers[1], "92101",  0, { categories[1] => 1 }
    assert_categories_with_counts.call publishers[1], "92101",  5, { categories[1] => 2, categories[3] => 1 }
    assert_categories_with_counts.call publishers[1], "92101", 20, { categories[1] => 2, categories[3] => 1 }

    assert_categories_with_counts.call publishers[2], "92101",  0, { categories[1] => 1, categories[2] => 1 }
    assert_categories_with_counts.call publishers[2], "92101",  5, { categories[1] => 1, categories[2] => 1 }
    assert_categories_with_counts.call publishers[2], "92101", 20, { categories[1] => 2, categories[2] => 2, categories[3] => 1 }
    
    assert_nil ZipCode.find_by_zip("92102"), "Assume no zip-code fixture for 92102"
    assert_categories_with_counts.call publishers[2], "92102", 20, {}
  end
  
  def test_all_with_offers_count_for_publisher_with_zip_and_radius_with_expired_offer
    categories = returning([]) do |array|
      4.times { |i| array << Category.create!(:name => "Category #{i}") }
    end
    categories[1].subcategories.create!(:name => "Subcategory 1")
    categories[2].subcategories.create!(:name => "Subcategory 2")

    publishers = returning([]) do |array|
      3.times { |i| array << Factory(:publisher, :name => "Publisher #{i}") }
    end
    
    advertiser_0 = publishers[1].advertisers.create!
    advertiser_0.stores.create(:address_line_1 => "0 Main St", :city => "San Diego", :state => "CA", :zip => "92101").save!
    advertiser_0.offers.create! :message => "Advertiser 0 Offer 0",  :categories => [categories[1]]
                                                         
    advertiser_1 = publishers[1].advertisers.create!     
    advertiser_1.stores.create(:address_line_1 => "1 Main St", :city => "San Diego", :state => "CA", :zip => "92106-1234").save!
    advertiser_1.offers.create! :message => "Advertiser 1 Offer 0",  :categories => [categories[1], categories[3]]
                                                         
    advertiser_2 = publishers[2].advertisers.create!     
    advertiser_2.stores.create(:address_line_1 => "2 Main St", :city => "San Diego", :state => "CA", :zip => "92101-1234").save!
    advertiser_2.offers.create! :message => "Advertiser 2 Offer 0",  :categories => [categories[1], categories[2]]
                                                         
    advertiser_3 = publishers[2].advertisers.create!     
    advertiser_3.stores.create(:address_line_1 => "3 Main St", :city => "Cazenovia", :state => "NY", :zip => "13035").save!
    advertiser_3.offers.create! :message => "Advertiser 3 Offer 0",  :categories => [categories[2], categories[3]]
                                                         
    advertiser_4 = publishers[2].advertisers.create!     
    advertiser_4.stores.create(:address_line_1 => "4 Main St", :city => "Lakeside", :state => "CA", :zip => "92040").save!
    advertiser_4.offers.create! :message => "Advertiser 4 Offer 0",  :categories => [categories[1], categories[3]]
    advertiser_4.offers.create! :message => "Advertiser 4 Offer 1", :categories => [categories[2]], :expires_on => 3.days.ago

    assert_categories_with_counts = lambda do |publisher, zip, radius, cats_with_count|
      want_cats = cats_with_count.keys.sort_by(&:id)
      search_request = SearchRequest.create(:publisher => publisher, :postal_code => zip, :radius => radius)
      have_cats = Category.all_with_offers_count_for_publisher(search_request).sort_by(&:id)
      assert_equal want_cats, have_cats, "Categories for #{publisher.name}, #{radius} mi of #{zip}"
      have_cats.each do |category|
        assert_equal cats_with_count[category], category.offers_count, "Offer count for #{category.name}"
      end
    end
    assert_categories_with_counts.call publishers[0], "92101",  0, {}
    assert_categories_with_counts.call publishers[0], "92101",  5, {}
    assert_categories_with_counts.call publishers[0], "92101", 20, {}
    
    assert_categories_with_counts.call publishers[1], "92101",  0, { categories[1] => 1 }
    assert_categories_with_counts.call publishers[1], "92101",  5, { categories[1] => 2, categories[3] => 1 }
    assert_categories_with_counts.call publishers[1], "92101", 20, { categories[1] => 2, categories[3] => 1 }

    assert_categories_with_counts.call publishers[2], "92101",  0, { categories[1] => 1, categories[2] => 1 }
    assert_categories_with_counts.call publishers[2], "92101",  5, { categories[1] => 1, categories[2] => 1 }
    assert_categories_with_counts.call publishers[2], "92101", 20, { categories[1] => 2, categories[2] => 1, categories[3] => 1 }
    
    assert_nil ZipCode.find_by_zip("92102"), "Assume no zip-code fixture for 92102"
    assert_categories_with_counts.call publishers[2], "92102", 20, {}
  end 
  
  def test_all_with_offers_count_for_publisher_with_publishers_in_publishing_group_and_search_by_publishing_group_enabled
    categories = returning([]) do |array|
      4.times { |i| array << Category.create!(:name => "Category #{i}") }
    end
   
    publishing_group = PublishingGroup.create!( :name => "Publishing Group #1")
    publishers = returning([]) do |array|
      3.times { |i| array << Factory(:publisher, :name => "Publisher #{i}", :publishing_group => publishing_group) }
    end
    
    advertiser_0 = publishers[1].advertisers.create!
    advertiser_0.offers.create! :message => "Advertiser 0",  :categories => [categories[1]]
    advertiser_0.offers.create! :message => "Advertiser 0 deleted",  :categories => [ categories[0], categories[3] ], :deleted_at => Time.now
                                                         
    advertiser_1 = publishers[1].advertisers.create!     
    advertiser_1.offers.create! :message => "Advertiser 1",  :categories => [categories[1]]
                                                         
    advertiser_2 = publishers[2].advertisers.create!     
    advertiser_2.offers.create! :message => "Advertiser 2",  :categories => [categories[1], categories[2]]
                                                         
    advertiser_3 = publishers[2].advertisers.create!     
    advertiser_3.offers.create! :message => "Advertiser 3",  :categories => [categories[2], categories[3]]
                                                         
    advertiser_5 = publishers[2].advertisers.create!     
    advertiser_5.offers.create! :message => "Advertiser 5",  :categories => [categories[1]], :expires_on => 2.days.ago
    advertiser_5.offers.create! :message => "Advertiser 5", :categories => [categories[2]]

    publisher = publishers[0]
    publisher.update_attribute(:enable_search_by_publishing_group, true)
    
    assert publisher.enable_search_by_publishing_group
    
    cats = Category.all_with_offers_count_for_publisher(:publisher => publishers[0])
    assert_equal 3, cats.size    
  end
  
  def test_subcategories
    food = Category.create!(:name => "Food")
    assert food.children.empty?, "No children"
    assert food.subcategories.empty?, "subcategories alias"
    
    restaurant = food.children.create!(:name => "Restaurant")
    cafe = food.subcategories.create!(:name => "Cafe")
    
    assert !(cafe.children << restaurant), "No circular relationships"
    
    # Different parent, same name
    Category.create!(:name => "Food")
  end
  
  def test_all_with_offers_count_for_publisher_with_subcategories
    categories = returning([]) do |array|
      4.times { |i| array << Category.create!(:name => "Category #{i}") }
    end
    
    subcategory = categories[1].subcategories.create!(:name => "Subcategory")

    publishers = returning([]) do |array|
      3.times { |i| array << Factory(:publisher, :name => "Publisher #{i}") }
    end
    
    advertiser_0 = publishers[1].advertisers.create!
    advertiser_0.offers.create! :message => "Advertiser 0: Offer 0",  :categories => [categories[1]]

    advertiser_1 = publishers[1].advertisers.create!
    advertiser_1.offers.create! :message => "Advertiser 1: Offer 0",  :categories => [categories[1]]
    
    advertiser_2 = publishers[2].advertisers.create!
    advertiser_2.offers.create! :message => "Advertiser 2: Offer 0",  :categories => [categories[1], categories[2]]

    advertiser_3 = publishers[2].advertisers.create!
    advertiser_3.offers.create! :message => "Advertiser 3: Offer 0",  :categories => [categories[2], categories[3]]

    advertiser_4 = publishers[1].advertisers.create!
    advertiser_4.offers.create! :message => "Advertiser 4: Offer 0",  :categories => [categories[1], subcategory]

    advertiser_5 = publishers[2].advertisers.create!
    advertiser_5.offers.create! :message => "Advertiser 5: Offer 0",  :categories => [categories[1]]

    cats = Category.all_with_offers_count_for_publisher(:publisher => publishers[0])
    assert_equal 0, cats.size
    
    cats = Category.all_with_offers_count_for_publisher(:publisher => publishers[1])
    assert_equal 1, cats.size, "Categories count. #{cats.map(&:name).join(', ')}"
    assert_not_nil (category = cats.detect { |cat| "Category 1" == cat.name })
    assert_equal 3, category.offers_count
    
    cats = Category.all_with_offers_count_for_publisher(:publisher => publishers[2])
    assert_equal 3, cats.size
    assert_not_nil (category = cats.detect { |cat| "Category 1" == cat.name })
    assert_equal 2, category.offers_count
    assert_not_nil (category = cats.detect { |cat| "Category 2" == cat.name })
    assert_equal 2, category.offers_count
    assert_not_nil (category = cats.detect { |cat| "Category 3" == cat.name })
    assert_equal 1, category.offers_count
  end
  
  def test_subcategories_parent
    categories = returning([]) do |array|
      4.times { |i| array << Category.create!(:name => "Category #{i}") }
    end
    
    subcategory = categories[1].subcategories.create!(:name => "Subcategory")

    publishers = returning([]) do |array|
      3.times { |i| array << Factory(:publisher, :name => "Publisher #{i}") }
    end
    
    advertiser_0 = publishers[1].advertisers.create!

    advertiser_1 = publishers[2].advertisers.create!
    advertiser_1.offers.create! :message => "Advertiser 1: Offer 0",  :categories => [categories[1]]
    
    advertiser_2 = publishers[2].advertisers.create!
    advertiser_2.offers.create! :message => "Advertiser 2: Offer 0",  :categories => [categories[1], categories[2]]

    advertiser_3 = publishers[2].advertisers.create!
    advertiser_3.offers.create! :message => "Advertiser 3: Offer 0",  :categories => [categories[2], categories[3]]

    advertiser_4 = publishers[2].advertisers.create!
    advertiser_4.offers.create! :message => "Advertiser 4: Offer 0",  :categories => [subcategory]
  end
  
  def test_downcase_name
    assert_equal nil, Category.new.downcase_name, "downcase_name with no name"
    assert_equal "football", Category.new(:name => "Football").downcase_name, "downcase_name with no name"
  end
  
  def test_full_name
    assert_equal "", Category.new.full_name, "full_name with no name"
    sports = Category.new(:name => "Sports")
    assert_equal "Sports", sports.full_name, "full_name with no name"
    sports.save!
    football = sports.subcategories.create!(:name => "Football")
    assert_equal "Sports: Football", football.full_name, "full_name with subcategory"
  end
  
  def test_depth_limit
    assert Category.create(:name => "Food"), "Can create root category"
    assert Category.create(:name => "Auto").subcategories.create(:name => "Ford"), "Can create child category"
    pizza = Category.create(:name => "Restaurant").subcategories.create(:name => "Italian").subcategories.create(:name => "Pizza")
    assert pizza.errors.any?, "No children for children"
  end
  
  def test_cannot_change_parent
    auto = Category.create(:name => "Auto")
    ford = auto.subcategories.create(:name => "Ford")
    assert_equal auto, ford.parent, "Ford parent"
    assert_equal auto.id, ford.parent_id, "Ford parent_id"

    ford.parent = Category.create(:name => "Airplane")
    ford.save
    assert ford.errors.on(:parent_id), "cannot change parent"
  end 
  
  def test_find_by_path_with_blank_parent_and_child
    assert_nil Category.find_by_path([nil, nil])
  end
  
  def test_find_by_path_with_blank_parent_and_invalid_child
    assert_nil Category.find_by_path([nil, "blah"])
  end 
  
  def test_find_by_path_with_invalid_parent_and_valid_child
    auto = Category.create(:name => "Auto")
    foreign = auto.subcategories.create(:name => "Foreign")
    assert foreign, Category.find_by_path(["blah", foreign.label])
  end 
  
  def test_find_by_path_with_valid_parent_and_invalid_child
    auto = Category.create(:name => "Auto")
    foreign = auto.subcategories.create(:name => "Foreign")
    assert_nil Category.find_by_path(["auto", "blah"])
  end
  
  def test_find_by_path_with_parent_and_child_label
    auto = Category.create(:name => "Auto")
    foreign = auto.subcategories.create(:name => "Foreign")
    assert_equal foreign, Category.find_by_path(["auto", "foreign"])
  end
  
  def test_find_by_path_with_just_parent_label_as_leaf
    auto = Category.create(:name => "Auto")
    assert_equal auto, Category.find_by_path(["auto"])
  end

  test "allowed_by_publishing_group" do
    publishing_group = Factory(:publishing_group)

    category = Factory(:category)
    subcategory1 = Factory(:category, :parent => category, :name => "Foo")
    subcategory2 = Factory(:category, :parent => category, :name => "Bar")
    subcategory3 = Factory(:category, :parent => category, :name => "Baz")

    publishing_group.categories << category
    publishing_group.categories << subcategory1
    publishing_group.categories << subcategory2

    assert_same_elements [subcategory1, subcategory2],
      category.subcategories.allowed_by_publishing_group(publishing_group)
  end
  
end
